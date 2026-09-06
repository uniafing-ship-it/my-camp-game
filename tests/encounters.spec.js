import { expect, test } from '@playwright/test';

const SAVE_KEY='camp_save_v7';
const EVENT_KEY='camp_stage7_encounters_v1';
const baseSave=(overrides={})=>({
  v:7,storage:{wood:100,stone:100,food:100,gold:100,pelts:2},built:4,
  buildings:[0,1,2,3].map(i=>({i,lvl:1,hp:100,maxHp:100})),wave:1,kills:0,bossKills:0,
  peltsGot:0,carcassCount:0,questIdx:0,dayT:0,nightWaveSpawned:1,wasNight:false,
  workersN:0,footN:0,hunterN:0,dogN:0,hero:{lvl:1,xp:0},researched:[],relics:[],achs:[],workerOrder:'auto',fame:0,expansions:0,
  ...overrides
});

async function gotoSavedGame(page,save){
  await page.route('https://cdn.jsdelivr.net/**',route=>route.abort());
  await page.addInitScript(({saveKey,eventKey,value})=>{
    localStorage.removeItem(eventKey);
    localStorage.setItem(saveKey,value);
  },{saveKey:SAVE_KEY,eventKey:EVENT_KEY,value:JSON.stringify(save)});
  await page.goto('/',{waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>window.MyCampLegacy&&window.MyCampGame);
  await page.locator('#playBtn').click();
  await page.waitForFunction(()=>window.MyCampLegacy?.state==='play');
}

test('Stage 7 resolves first post-raid encounter through V20 resources and persists the choice',async({page})=>{
  const pageErrors=[];page.on('pageerror',error=>pageErrors.push(error.message));
  await gotoSavedGame(page,baseSave());

  await expect(page.locator('html')).toHaveAttribute('data-v20-world-events','stage7-encounters-v1');
  const backdrop=page.locator('#stage7EncounterBackdrop');
  await expect(backdrop).toHaveClass(/\bopen\b/,{timeout:5_000});
  await expect(page.locator('#stage7EncounterTitle')).toContainText('Трофеи лесного рейда');

  const before=await page.evaluate(()=>({
    legacy:window.MyCampLegacy.storage.wood,
    canonical:window.MyCampGame.authority.snapshot('resources').wood,
    listed:window.MyCampGame.commands.list().includes('world.event.resolve')
  }));
  expect(before.listed).toBe(true);
  expect(before.canonical).toBe(before.legacy);

  await page.locator('[data-choice="timber"]').click();
  await expect(backdrop).not.toHaveClass(/\bopen\b/);
  await page.waitForFunction(expected=>window.MyCampLegacy.storage.wood===expected&&window.MyCampGame.authority.snapshot('resources').wood===expected,before.legacy+25);

  const after=await page.evaluate(eventKey=>({
    legacy:window.MyCampLegacy.storage.wood,
    canonical:window.MyCampGame.authority.snapshot('resources').wood,
    resolved:window.MyCampGame.encounters.resolved(),
    persisted:JSON.parse(localStorage.getItem(eventKey)||'[]')
  }),EVENT_KEY);
  expect(after.legacy).toBe(before.legacy+25);
  expect(after.canonical).toBe(before.legacy+25);
  expect(after.resolved).toContain('forest-spoils');
  expect(after.persisted).toContain('forest-spoils');
  expect(pageErrors).toEqual([]);
});

test('Stage 7 does not replay obsolete early encounters for an advanced save',async({page})=>{
  await gotoSavedGame(page,baseSave({wave:3,nightWaveSpawned:3}));
  const backdrop=page.locator('#stage7EncounterBackdrop');
  await expect(backdrop).toHaveClass(/\bopen\b/,{timeout:5_000});
  await expect(page.locator('#stage7EncounterTitle')).toContainText('Свежий звериный след');
  const state=await page.evaluate(eventKey=>({
    resolved:window.MyCampGame.encounters.resolved(),
    persisted:JSON.parse(localStorage.getItem(eventKey)||'[]')
  }),EVENT_KEY);
  expect(state.resolved).toContain('forest-spoils');
  expect(state.resolved).toContain('stone-cache');
  expect(state.persisted).toContain('forest-spoils');
  expect(state.persisted).toContain('stone-cache');
});

import { expect, test } from '@playwright/test';

const SAVE_KEY='camp_save_v7';
const baseSave=(overrides={})=>({
  v:7,storage:{wood:500,stone:500,food:500,gold:500,pelts:20},built:4,
  buildings:[0,1,2,3].map(i=>({i,lvl:1,hp:100,maxHp:100})),wave:0,kills:0,bossKills:0,
  peltsGot:0,carcassCount:0,questIdx:0,dayT:0,nightWaveSpawned:-1,wasNight:false,
  workersN:0,footN:0,hunterN:0,dogN:0,hero:{lvl:1,xp:0},researched:[],relics:[],achs:[],workerOrder:'auto',fame:0,expansions:0,
  ...overrides
});
async function gotoGame(page,save=baseSave()){
  await page.route('https://cdn.jsdelivr.net/**',route=>route.abort());
  await page.addInitScript(({key,value})=>localStorage.setItem(key,value),{key:SAVE_KEY,value:JSON.stringify(save)});
  await page.goto('/',{waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>window.MyCampLegacy&&window.MyCampGame);
  await page.locator('#playBtn').click();
  await page.waitForFunction(()=>window.MyCampLegacy?.state==='play');
}

test('strategic agent uses V20 authority and safe manual step grows workforce',async({page})=>{
  await gotoGame(page);
  const before=await page.evaluate(()=>({
    source:window.MyCampGame.agent.state().source,
    enabled:window.MyCampGame.autopilot.isEnabled(),
    strategy:window.MyCampGame.decisionEngine.strategy(),
    workers:window.MyCampLegacy.workers.length
  }));
  expect(before.source).toBe('v20-authority');
  expect(before.enabled).toBe(false);
  expect(before.strategy.action.type).toBe('hire.worker');
  expect(before.workers).toBe(0);

  const result=await page.evaluate(()=>window.MyCampGame.autopilot.step());
  expect(result.ok).toBe(true);
  expect(result.action.type).toBe('hire.worker');
  await page.waitForFunction(()=>window.MyCampLegacy.workers.length===1&&window.MyCampGame.authority.snapshot('villagers').workerCount===1);
  expect(await page.evaluate(()=>window.MyCampGame.autopilot.isEnabled())).toBe(false);
});

test('resource recovery bypasses spending reserve without enabling autopilot',async({page})=>{
  await gotoGame(page,baseSave({workersN:1}));
  await page.evaluate(()=>window.MyCampGame.runtime.get('resources').replace({wood:0,stone:0,food:0,gold:0,pelts:0}));
  await page.waitForFunction(()=>window.MyCampGame.authority.snapshot('resources').food===0);
  const strategy=await page.evaluate(()=>window.MyCampGame.decisionEngine.strategy());
  expect(strategy.action.type).toBe('workers.order');
  expect(strategy.action.value).toBe('food');
  const safety=await page.evaluate(()=>{const s=window.MyCampGame.decisionEngine.strategy();return window.MyCampGame.autopilot.safeAction(s.action);});
  expect(safety.ok).toBe(true);
  const result=await page.evaluate(()=>window.MyCampGame.autopilot.step());
  expect(result.ok).toBe(true);
  await expect(page.locator('.ord-btn[data-ord="food"]')).toHaveClass(/\bactive\b/);
});

test('research crosses agent Command Bus and updates real game state',async({page})=>{
  await gotoGame(page);
  const can=await page.evaluate(()=>window.MyCampGame.agent.can('research','axes'));
  expect(can).toBe(true);
  const result=await page.evaluate(()=>window.MyCampGame.agent.research('axes'));
  expect(result.ok).toBe(true);
  await page.waitForFunction(()=>window.MyCampLegacy.researched.includes('axes'));
  const state=await page.evaluate(()=>({researched:[...window.MyCampLegacy.researched],resources:{...window.MyCampLegacy.storage},canonical:window.MyCampGame.authority.snapshot('resources')}));
  expect(state.researched).toContain('axes');
  expect(state.resources.wood).toBe(400);
  expect(state.resources.gold).toBe(470);
  expect(state.canonical.wood).toBe(400);
  expect(state.canonical.gold).toBe(470);
});

test('expedition command deploys units through compatibility boundary',async({page})=>{
  await gotoGame(page,baseSave({footN:2}));
  await page.waitForFunction(()=>window.MyCampLegacy.soldiers.filter(s=>s.kind==='foot').length===2);
  const result=await page.evaluate(()=>window.MyCampGame.agent.startExpedition(0));
  expect(result.ok).toBe(true);
  await page.waitForFunction(()=>window.MyCampLegacy.soldiers.filter(s=>s.busy).length>=2);
  const projection=await page.evaluate(()=>window.MyCampGame.authority.snapshot('combat').army);
  expect(projection.busy).toBeGreaterThanOrEqual(2);
  expect(projection.idle).toBe(0);
});

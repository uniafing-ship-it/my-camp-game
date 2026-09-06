import { expect, test } from '@playwright/test';

const SAVE_KEY='camp_save_v7';
const baseSave=(built=6)=>({
  v:7,storage:{wood:100,stone:100,food:100,gold:100,pelts:2},built,
  buildings:Array.from({length:built},(_,i)=>({i,lvl:1,hp:100,maxHp:100})),wave:0,kills:0,bossKills:0,
  peltsGot:0,carcassCount:0,questIdx:0,dayT:0,nightWaveSpawned:-1,wasNight:false,
  workersN:0,footN:0,hunterN:0,dogN:0,hero:{lvl:1,xp:0},researched:[],relics:[],achs:[],workerOrder:'auto',fame:0,expansions:0
});

async function gotoGame(page,save){
  await page.route('https://cdn.jsdelivr.net/**',route=>route.abort());
  await page.addInitScript(({key,value})=>localStorage.setItem(key,value),{key:SAVE_KEY,value:JSON.stringify(save)});
  await page.goto('/',{waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>window.MyCampLegacy&&window.MyCampGame);
  await page.locator('#playBtn').click();
  await page.waitForFunction(()=>window.MyCampLegacy?.state==='play');
  await page.waitForFunction(()=>window.MyCampGame?.authority?.snapshot('buildings')?.count===window.MyCampLegacy.buildings.length);
}

test('Stage 7 shows camp tier inside the existing building status instead of adding another HUD panel',async({page})=>{
  const pageErrors=[];page.on('pageerror',error=>pageErrors.push(error.message));
  await gotoGame(page,baseSave(6));

  await expect(page.locator('html')).toHaveAttribute('data-v20-camp-progression','stage7-tiers-v1');
  const level=page.locator('#levelVal');
  await expect(level).toContainText('ПОСЕЛЕНИЕ',{timeout:5_000});
  await expect(level).toContainText('6/17');
  await expect(level).toHaveAttribute('data-camp-tier','settlement');
  expect(await page.locator('#midBox').count()).toBe(1);
  expect(await page.locator('#campTierPanel').count()).toBe(0);

  const state=await page.evaluate(()=>({
    current:window.MyCampGame.campProgression.current(),
    count:window.MyCampGame.authority.snapshot('buildings').count,
    legacyCount:window.MyCampLegacy.buildings.length
  }));
  expect(state.current.name).toBe('ПОСЕЛЕНИЕ');
  expect(state.count).toBe(6);
  expect(state.legacyCount).toBe(6);

  const box=await level.boundingBox();
  expect(box).not.toBeNull();
  expect(box.x).toBeGreaterThanOrEqual(0);
  expect(box.x+box.width).toBeLessThanOrEqual(390);
  expect(pageErrors).toEqual([]);
});

test('Stage 7 tier calculation reaches fortress and citadel without changing legacy buildings',async({page})=>{
  await gotoGame(page,baseSave(10));
  await expect(page.locator('#levelVal')).toContainText('КРЕПОСТЬ',{timeout:5_000});
  const before=await page.evaluate(()=>window.MyCampLegacy.buildings.length);
  const derived=await page.evaluate(()=>({
    fortress:window.MyCampGame.campProgression.tiers.find(t=>t.id==='fortress'),
    citadel:window.MyCampGame.campProgression.tiers.find(t=>t.id==='citadel')
  }));
  expect(derived.fortress.minBuildings).toBe(10);
  expect(derived.citadel.minBuildings).toBe(14);
  expect(await page.evaluate(()=>window.MyCampLegacy.buildings.length)).toBe(before);
});

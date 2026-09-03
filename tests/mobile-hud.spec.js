import { expect, test } from '@playwright/test';

async function gotoGame(page) {
  await page.route('https://cdn.jsdelivr.net/**', route => route.abort());
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.MyCampLegacy && window.MyCampGame, null, { timeout: 10_000 });
  await page.locator('#playBtn').click();
  await page.waitForFunction(() => window.MyCampLegacy?.state === 'play');
}

test('phone HUD keeps secondary controls compact until the player opens them', async ({ page }) => {
  const pageErrors=[];
  page.on('pageerror', error => pageErrors.push(error.message));
  await gotoGame(page);

  await expect(page.locator('html')).toHaveAttribute('data-v20-mobile-hud','stage6-compact-v1');

  const launcher=page.locator('#v20-agent-launcher');
  const agentPanel=page.locator('#v20-agent-panel');
  const backdrop=page.locator('#v20-agent-backdrop');
  await expect(launcher).toBeVisible();
  await expect(agentPanel).toBeHidden();

  const overlap=await page.evaluate(()=>{
    const rect=id=>{const r=document.getElementById(id).getBoundingClientRect();return {l:r.left,r:r.right,t:r.top,b:r.bottom};};
    const a=rect('v20-agent-launcher'),s=rect('skillPanel'),q=rect('squadPanel');
    const hit=(x,y)=>Math.max(x.l,y.l)<Math.min(x.r,y.r)&&Math.max(x.t,y.t)<Math.min(x.b,y.b);
    return {skill:hit(a,s),squad:hit(a,q)};
  });
  expect(overlap.skill).toBe(false);
  expect(overlap.squad).toBe(false);

  await launcher.click();
  await expect(agentPanel).toBeVisible();
  await expect(backdrop).toBeVisible();
  await expect(launcher).toHaveAttribute('aria-expanded','true');
  await page.locator('#v20-agent-panel [data-close]').click();
  await expect(agentPanel).toBeHidden();
  await expect(backdrop).toBeHidden();

  const toolsButton=page.locator('#mobileToolsBtn');
  const tools=page.locator('#topRight .tr-btns');
  await expect(toolsButton).toBeVisible();
  await expect(tools).toBeHidden();
  await toolsButton.click();
  await expect(tools).toBeVisible();
  await expect(toolsButton).toHaveAttribute('aria-expanded','true');
  await page.locator('#game').click({position:{x:190,y:420}});
  await expect(tools).toBeHidden();

  const guide=page.locator('#playerGuideHint');
  await expect(guide).toHaveAttribute('data-compact','true');
  await expect(guide).toContainText('деревьям');

  expect(pageErrors).toEqual([]);
});

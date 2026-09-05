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

for (const viewport of [{width:844,height:390},{width:932,height:430},{width:740,height:360}]) {
  test(`compact HUD survives phone rotation at ${viewport.width}x${viewport.height}`, async ({ page }) => {
    const errors=[];
    page.on('pageerror',error=>errors.push(error.message));
    await gotoGame(page);
    await page.setViewportSize(viewport);
    const panel=page.locator('#v20-agent-panel');
    const launcher=page.locator('#v20-agent-launcher');
    const tools=page.locator('#topRight .tr-btns');
    await expect(panel).toBeHidden();
    await expect(launcher).toBeVisible();
    await expect(tools).toBeHidden();
    await expect(page.locator('#playerGuideHint')).toHaveAttribute('data-compact','true');
    await launcher.click();
    await expect(panel).toBeVisible();
    await page.keyboard.press('Escape');
    await expect(panel).toBeHidden();
    await page.locator('#mobileToolsBtn').click();
    await expect(tools).toBeVisible();
    const bounds=await tools.evaluate(el=>{
      const box=el.getBoundingClientRect();
      return [...el.querySelectorAll('.hbtn')].map(button=>{
        const r=button.getBoundingClientRect();
        return r.left>=box.left && r.right<=box.right && r.top>=box.top && r.bottom<=box.bottom && r.left>=0 && r.right<=innerWidth && r.bottom<=innerHeight;
      });
    });
    expect(bounds).toHaveLength(6);
    expect(bounds.every(Boolean)).toBe(true);
    await page.setViewportSize({width:390,height:844});
    await expect(panel).toBeHidden();
    await expect(launcher).toBeVisible();
    await page.setViewportSize({width:1280,height:800});
    await expect(launcher).toBeHidden();
    await expect(panel).toBeVisible();
    await expect(tools).toBeVisible();
    expect(errors).toEqual([]);
  });
}

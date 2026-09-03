import { expect, test } from '@playwright/test';

async function gotoGame(page) {
  await page.route('https://cdn.jsdelivr.net/**', route => route.abort());
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.MyCampLegacy && window.MyCampGame, null, { timeout: 10_000 });
}

test('Stage 6 adds actionable guidance to early quests without creating another HUD panel', async ({ page }) => {
  const pageErrors = [];
  page.on('pageerror', error => pageErrors.push(error.message));

  await gotoGame(page);
  expect(await page.locator('#questBox').count()).toBe(1);
  expect(await page.locator('#playerGuideHint').count()).toBe(1);
  await expect(page.locator('html')).toHaveAttribute('data-v20-player-guide', 'stage6-quest-coach-v1');

  await page.locator('#playBtn').click();
  await page.waitForFunction(() => window.MyCampLegacy?.state === 'play');

  const guide = page.locator('#playerGuideHint');
  await expect(guide).toBeVisible();
  await expect(guide).toContainText('деревьям');
  await expect(guide).toHaveAttribute('data-stage', '6');
  await expect(guide).toHaveAttribute('data-active', 'true');

  const apiCheck = await page.evaluate(() => ({
    hasGuide: Boolean(window.MyCampGame.playerGuide),
    buildHint: window.MyCampGame.playerGuide.hintFor('Построй ЛЕСОПИЛКУ'),
    lateHint: window.MyCampGame.playerGuide.hintFor('Победи 25 орков')
  }));
  expect(apiCheck.hasGuide).toBe(true);
  expect(apiCheck.buildHint).toContain('строительной площадке');
  expect(apiCheck.lateHint).toBe('');

  await page.evaluate(() => {
    document.getElementById('questText').textContent = 'Построй ЛЕСОПИЛКУ';
  });
  await expect(guide).toContainText('строительной площадке');

  await page.evaluate(() => {
    document.getElementById('questText').textContent = 'Победи 25 орков';
  });
  await expect(guide).toBeHidden();
  await expect(guide).toHaveAttribute('data-active', 'false');

  expect(pageErrors).toEqual([]);
});

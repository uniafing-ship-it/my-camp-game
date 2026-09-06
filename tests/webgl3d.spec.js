import { expect, test } from '@playwright/test';

test('Stage 9 boots the true WebGL2 world renderer', async ({ page }) => {
  const pageErrors = [];
  const consoleErrors = [];
  page.on('pageerror', error => pageErrors.push(error.message));
  page.on('console', message => {
    if (message.type() === 'error' && !message.text().includes('Failed to load resource')) {
      consoleErrors.push(message.text());
    }
  });

  await page.route('https://cdn.jsdelivr.net/**', route => route.abort());
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.MyCampLegacy && window.MyCampGame, null, { timeout: 10_000 });
  await page.locator('#playBtn').click();
  await page.waitForFunction(() => window.MyCampLegacy?.state === 'play');

  const renderer = await page.evaluate(() => {
    const controller = window.MyCampGame.renderer3d;
    const instance = controller.start();
    const canvas = document.getElementById('webgl3d-world');
    const context = canvas?.getContext('webgl2');
    return {
      started: controller.started,
      enabled: instance?.enabled === true,
      canvas: !!canvas,
      webgl2: !!context,
      width: canvas?.width || 0,
      height: canvas?.height || 0,
      dataset: document.documentElement.dataset.renderer3d || ''
    };
  });

  expect(renderer.started).toBe(true);
  expect(renderer.enabled).toBe(true);
  expect(renderer.canvas).toBe(true);
  expect(renderer.webgl2).toBe(true);
  expect(renderer.width).toBeGreaterThan(0);
  expect(renderer.height).toBeGreaterThan(0);
  expect(renderer.dataset).toBe('1');

  await page.waitForTimeout(250);
  expect(pageErrors).toEqual([]);
  expect(consoleErrors).toEqual([]);
});

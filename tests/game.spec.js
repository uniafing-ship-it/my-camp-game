import { expect, test } from '@playwright/test';

const SAVE_KEY = 'camp_save_v7';

function runtimeMonitor(page) {
  const pageErrors = [];
  const consoleErrors = [];
  const badLocalResponses = [];

  page.on('pageerror', error => pageErrors.push(error.message));
  page.on('console', message => {
    if (message.type() !== 'error') return;
    const text = message.text();
    if (!text.includes('Failed to load resource')) consoleErrors.push(text);
  });
  page.on('response', response => {
    const url = new URL(response.url());
    if (url.origin !== 'http://127.0.0.1:4173') return;
    if (url.pathname === '/favicon.ico') return;
    if (response.status() >= 400) badLocalResponses.push(`${response.status()} ${url.pathname}`);
  });

  return {
    assertClean() {
      expect(pageErrors, `uncaught page errors: ${pageErrors.join(' | ')}`).toEqual([]);
      expect(consoleErrors, `console errors: ${consoleErrors.join(' | ')}`).toEqual([]);
      expect(badLocalResponses, `bad local responses: ${badLocalResponses.join(' | ')}`).toEqual([]);
    }
  };
}

async function gotoGame(page) {
  await page.route('https://cdn.jsdelivr.net/**', route => route.abort());
  await page.goto('/', { waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.MyCampLegacy && window.MyCampGame, null, { timeout: 10_000 });
}

async function startGame(page) {
  await page.locator('#playBtn').click();
  await page.waitForFunction(() => window.MyCampLegacy?.state === 'play');
  await expect(page.locator('#hud')).toHaveClass(/\bon\b/);
}

async function setSpeed10(page) {
  await page.locator('#speedToggle').click();
  await page.locator('.spd-btn[data-spd="10"]').click();
  await page.waitForFunction(() => window.MyCampLegacy?.gameSpeed === 10);
}

function seededUnlockedHunterSave() {
  return {
    v: 7,
    storage: { wood: 0, stone: 0, food: 0, gold: 0, pelts: 0 },
    built: 4,
    buildings: [0, 1, 2, 3].map(i => ({ i, lvl: 1 })),
    wave: 0,
    kills: 0,
    bossKills: 0,
    peltsGot: 0,
    carcassCount: 0,
    questIdx: 0,
    dayT: 0,
    nightWaveSpawned: -1,
    wasNight: false,
    workersN: 0,
    footN: 0,
    hunterN: 0,
    dogN: 0,
    hero: { lvl: 1, xp: 0 },
    researched: [],
    relics: [],
    achs: [],
    workerOrder: 'auto',
    fame: 0,
    expansions: 0
  };
}

function rectsOverlap(a, b) {
  return !(a.right <= b.left || b.right <= a.left || a.bottom <= b.top || b.bottom <= a.top);
}

test('V20 boots cleanly and adaptive HUD works', async ({ page }) => {
  const monitor = runtimeMonitor(page);
  await gotoGame(page);

  const boot = await page.evaluate(() => ({
    frozen: Object.isFrozen(window.MyCampGame),
    foundation: document.documentElement.dataset.v20Foundation,
    stabilization: document.documentElement.dataset.v20Stabilization,
    commands: window.MyCampGame.commands.list(),
    commandCan: {
      build: window.MyCampGame.commands.can('build'),
      upgrade: window.MyCampGame.commands.can('upgrade'),
      hireWorker: window.MyCampGame.commands.can('hire.worker'),
      hireFoot: window.MyCampGame.commands.can('hire.foot'),
      hireHunter: window.MyCampGame.commands.can('hire.hunter'),
      hireDog: window.MyCampGame.commands.can('hire.dog'),
      workersOrder: window.MyCampGame.commands.can('workers.order', 'food')
    },
    uiActions: window.MyCampGame.uiActions,
    agent: Boolean(window.MyCampGame.agent),
    decisionEngine: Boolean(window.MyCampGame.decisionEngine),
    autopilot: Boolean(window.MyCampGame.autopilot),
    agentPanel: Boolean(window.MyCampGame.agentPanel)
  }));

  expect(boot.frozen).toBe(true);
  expect(boot.foundation).toBe('1');
  expect(boot.stabilization).toBe('20.20');
  expect(boot.commands).toEqual(expect.arrayContaining([
    'resources.canAfford', 'villagers.snapshot', 'buildings.snapshot',
    'build', 'upgrade', 'hire.worker', 'hire.foot', 'hire.hunter', 'hire.dog', 'workers.order'
  ]));
  expect(Object.values(boot.commandCan).every(Boolean)).toBe(true);
  expect(Object.values(boot.uiActions).every(Boolean)).toBe(true);
  expect(boot.agent && boot.decisionEngine && boot.autopilot && boot.agentPanel).toBe(true);

  await expect(page.locator('#hud')).toHaveAttribute('data-hud-mode', 'phone');
  await startGame(page);

  const phoneRects = await page.evaluate(() => {
    const rect = id => {
      const r = document.getElementById(id).getBoundingClientRect();
      return { left: r.left, right: r.right, top: r.top, bottom: r.bottom };
    };
    return { store: rect('storeBox'), mid: rect('midBox'), right: rect('topRight') };
  });
  expect(rectsOverlap(phoneRects.store, phoneRects.mid)).toBe(false);
  expect(rectsOverlap(phoneRects.mid, phoneRects.right)).toBe(false);
  expect(rectsOverlap(phoneRects.store, phoneRects.right)).toBe(false);

  await page.setViewportSize({ width: 1280, height: 720 });
  await expect(page.locator('#hud')).toHaveAttribute('data-hud-mode', 'desktop');
  monitor.assertClean();
});

test('hunter affordability, command routing and save path work', async ({ page }) => {
  const monitor = runtimeMonitor(page);
  const seeded = seededUnlockedHunterSave();
  await page.addInitScript(({ key, value }) => localStorage.setItem(key, value), {
    key: SAVE_KEY,
    value: JSON.stringify(seeded)
  });

  await gotoGame(page);
  await startGame(page);

  const hunterButton = page.locator('#hireHunterBtn');
  await expect(hunterButton).toBeDisabled();
  await expect(hunterButton).toHaveClass(/\bno\b/);

  await page.evaluate(() => {
    window.MyCampLegacy.storage.food = 500;
    window.MyCampLegacy.storage.wood = 500;
  });
  await expect(hunterButton).toBeEnabled({ timeout: 2_000 });

  await hunterButton.click();
  await page.waitForFunction(() => window.MyCampLegacy.soldiers.some(s => s.kind === 'hunter'));
  const hunterState = await page.evaluate(() => ({
    hunters: window.MyCampLegacy.soldiers.filter(s => s.kind === 'hunter').length,
    food: window.MyCampLegacy.storage.food,
    wood: window.MyCampLegacy.storage.wood
  }));
  expect(hunterState.hunters).toBe(1);
  expect(hunterState.food).toBe(480);
  expect(hunterState.wood).toBe(470);

  await page.evaluate(() => window.MyCampGame.commands.execute('workers.order', 'food'));
  await expect(page.locator('.ord-btn[data-ord="food"]')).toHaveClass(/\bactive\b/);

  await page.evaluate(() => window.MyCampGame.migration.commands.save());
  const persisted = await page.evaluate(key => JSON.parse(localStorage.getItem(key)), SAVE_KEY);
  expect(persisted.storage.food).toBe(480);
  expect(persisted.storage.wood).toBe(470);
  expect(persisted.hunterN).toBe(1);
  expect(persisted.workerOrder).toBe('food');
  monitor.assertClean();
});

test('night cadence and reload do not duplicate a wave', async ({ page }) => {
  const monitor = runtimeMonitor(page);
  await gotoGame(page);
  await startGame(page);
  await setSpeed10(page);

  await page.waitForFunction(
    () => window.MyCampLegacy.wave === 1 && window.MyCampLegacy.dayT >= 180,
    null,
    { timeout: 25_000 }
  );

  const firstNight = await page.evaluate(() => ({
    wave: window.MyCampLegacy.wave,
    dayT: window.MyCampLegacy.dayT,
    enemies: window.MyCampLegacy.enemies.length,
    label: document.getElementById('dayVal').textContent
  }));
  expect(firstNight.wave).toBe(1);
  expect(firstNight.dayT).toBeGreaterThanOrEqual(180);
  expect(firstNight.dayT).toBeLessThan(190);
  expect(firstNight.enemies).toBeGreaterThan(0);
  expect(firstNight.label).toContain('НОЧЬ');

  await page.evaluate(() => window.MyCampGame.migration.commands.save());
  const nightSave = await page.evaluate(key => JSON.parse(localStorage.getItem(key)), SAVE_KEY);
  expect(nightSave.wave).toBe(1);
  expect(nightSave.wasNight).toBe(true);
  expect(Number.isFinite(nightSave.nightWaveSpawned)).toBe(true);

  await page.reload({ waitUntil: 'domcontentloaded' });
  await page.waitForFunction(() => window.MyCampLegacy && window.MyCampGame, null, { timeout: 10_000 });
  await startGame(page);
  expect(await page.evaluate(() => window.MyCampLegacy.wave)).toBe(1);

  await setSpeed10(page);
  await page.waitForTimeout(1_200);
  expect(await page.evaluate(() => window.MyCampLegacy.wave)).toBe(1);

  await page.waitForFunction(
    () => {
      const label = document.getElementById('dayVal')?.textContent || '';
      return window.MyCampLegacy.wave === 2 &&
        window.MyCampLegacy.dayT >= 270 &&
        label.includes('НОЧЬ');
    },
    null,
    { timeout: 12_000 }
  );
  const secondNight = await page.evaluate(() => ({
    wave: window.MyCampLegacy.wave,
    dayT: window.MyCampLegacy.dayT,
    label: document.getElementById('dayVal').textContent
  }));
  expect(secondNight.wave).toBe(2);
  expect(secondNight.dayT).toBeGreaterThanOrEqual(270);
  expect(secondNight.dayT).toBeLessThan(280);
  expect(secondNight.label).toContain('НОЧЬ');
  expect(secondNight.dayT - firstNight.dayT).toBeGreaterThan(80);
  expect(secondNight.dayT - firstNight.dayT).toBeLessThan(100);
  monitor.assertClean();
});

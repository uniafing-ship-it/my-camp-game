// V20.10: versioned save boundary. Legacy save remains intact during migration.
const KEY = 'my-camp-game-v20-state';
const VERSION = 1;
const clone = value => typeof structuredClone === 'function' ? structuredClone(value) : JSON.parse(JSON.stringify(value));

export const SaveManager = {
  key: KEY,
  version: VERSION,
  load(storage = localStorage) {
    try {
      const raw = storage.getItem(KEY);
      if (!raw) return null;
      const parsed = JSON.parse(raw);
      return parsed && typeof parsed === 'object' ? parsed : null;
    } catch (_) { return null; }
  },
  save(state, storage = localStorage) {
    const payload = { version: VERSION, savedAt: Date.now(), state: clone(state || {}) };
    storage.setItem(KEY, JSON.stringify(payload));
    return payload;
  },
  clear(storage = localStorage) { storage.removeItem(KEY); }
};

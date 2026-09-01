export function normalizeSave(save = {}) {
  return { ...save, version: Math.max(20, Number(save.version || 0)) };
}

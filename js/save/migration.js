export const CURRENT_SAVE_VERSION = 20;

export function migrateSave(input = {}) {
  const save = structuredClone ? structuredClone(input) : JSON.parse(JSON.stringify(input));
  const version = Number(save.version || 1);
  if (!save.version) save.version = version;
  if (!save.meta) save.meta = {};
  save.meta.saveVersion = CURRENT_SAVE_VERSION;
  return save;
}

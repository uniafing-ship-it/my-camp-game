// V20 Foundation: versioned save helpers.
export const SAVE_VERSION = 4;

export function migrateSave(input) {
  const raw = input && typeof input === 'object' ? input : {};
  const out = {...raw};
  out.version = Number.isFinite(raw.version) ? raw.version : 1;
  out.version = SAVE_VERSION;
  out.resources ||= {};
  out.villagers ||= {};
  out.buildings ||= {};
  out.research ||= {};
  out.expeditions ||= {};
  out.quests ||= {};
  out.events ||= {};
  out.prestige ||= {};
  return out;
}

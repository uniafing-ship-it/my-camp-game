// V20 Foundation: technology graph. Existing research remains authoritative until migrated.
export const RESEARCH_TREE = {
  economy: ['axes','bags','trade','storage'],
  defense: ['walls','towers','weapons','fortifications'],
  survival: ['food','medicine','weather','expeditions']
};

export function isResearchUnlocked(id, unlocked = []) {
  return unlocked.includes(id);
}

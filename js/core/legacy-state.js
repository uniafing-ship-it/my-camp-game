// V20.2 compatibility adapter: reads the legacy game's state without taking ownership of UI.
export function readLegacyState(source = window) {
  const candidates = [
    source.gameState,
    source.state,
    source.game,
    source.GAME_STATE,
    source.MyCampGame?.legacyState
  ];
  return candidates.find(v => v && typeof v === 'object') || {};
}

export function findResourceContainer(snapshot = {}) {
  return snapshot.resources && typeof snapshot.resources === 'object'
    ? snapshot.resources
    : snapshot;
}

export function findVillagers(snapshot = {}) {
  const value = snapshot.villagers;
  if (Array.isArray(value)) return value;
  if (value && Array.isArray(value.list)) return value.list;
  return [];
}

// V20.14: normalized read-only agent state projection.
// Keeps the legacy runtime authoritative while exposing stable state for future automation/AI agents.
export function createAgentState(migration) {
  const snapshot = migration?.snapshot?.() || {};
  const resources = migration?.resources?.() || {};
  const villagers = migration?.villagers?.() || [];
  const buildings = migration?.buildings?.() || [];
  const roleCounts = migration?.roleCounts?.() || {};

  return Object.freeze({
    resources: Object.freeze({...resources}),
    villagers: Object.freeze(villagers.map(v => ({
      role: v?.role || v?.kind || v?.state || 'unknown',
      state: v?.state || 'unknown',
      busy: !!v?.busy
    }))),
    villagersCount: villagers.length,
    roleCounts: Object.freeze({...roleCounts}),
    buildings: Object.freeze(Array.isArray(buildings) ? buildings.map(b => ({
      id: b?.i ?? b?.id ?? null,
      level: b?.lvl ?? b?.level ?? 1,
      hp: b?.hp ?? null,
      maxHp: b?.maxHp ?? null
    })) : []),
    raw: snapshot
  });
}

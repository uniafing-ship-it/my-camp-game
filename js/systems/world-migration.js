// Stage 4: canonical world projection published by DomainAuthority.
// Keep this projection lightweight: the legacy engine owns detailed entity
// simulation until the world loop itself is extracted.
const length = value => Array.isArray(value) ? value.length : 0;

export function createWorldMigration(bridge, authority) {
  const project = (at = Date.now(), source = 'legacy-driver') => {
    const s = bridge?.snapshot?.() || {};
    const value = {
      nodes: length(s.nodes),
      animals: length(s.animals),
      bundles: length(s.bundles),
      weather: String(s.weather || 'clear'),
      dayT: Number(s.dayT || 0),
      at
    };
    return authority?.commit?.('world', value, { source, at }) || value;
  };

  return {
    name: 'world-migration',
    update(_dt, now) { project(now ?? Date.now()); },
    refresh(source = 'legacy-driver') { return project(Date.now(), source); },
    snapshot() { return authority?.snapshot?.('world') || project(); }
  };
}

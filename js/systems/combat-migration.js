// Stage 4: canonical combat projection published by DomainAuthority.
const PHASES = Object.freeze(['idle', 'warning', 'active', 'boss', 'resolved']);

export function createCombatMigration(bridge, authority) {
  const project = (at = Date.now(), source = 'legacy-driver') => {
    const s = bridge?.snapshot?.() || {};
    const raid = s.raid || s.raids || {};
    const enemies = Array.isArray(s.enemies) ? s.enemies : [];
    const soldiers = Array.isArray(s.soldiers) ? s.soldiers : [];
    const rawPhase = String(raid.phase || (enemies.length ? 'active' : 'idle')).toLowerCase();
    const phase = PHASES.includes(rawPhase) ? rawPhase : 'idle';
    const value = {
      raid: {
        phase,
        wave: Number(raid.wave || s.wave || 0),
        enemies: enemies.length
      },
      army: { soldiers: soldiers.length },
      at
    };
    return authority?.commit?.('combat', value, { source, at }) || value;
  };

  return {
    name: 'combat-migration',
    update(_dt, now) { project(now ?? Date.now()); },
    refresh(source = 'legacy-driver') { return project(Date.now(), source); },
    snapshot() { return authority?.snapshot?.('combat') || project(); }
  };
}

export { PHASES as COMBAT_PHASES };

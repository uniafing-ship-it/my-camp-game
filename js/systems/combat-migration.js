// V20.8: canonical combat/raid projection. Legacy remains authoritative for mutations.
const PHASES = Object.freeze(['idle', 'warning', 'active', 'boss', 'resolved']);

export function createCombatMigration(bridge) {
  return {
    name: 'combat-migration',
    update(_dt, now, runtime) {
      const s = bridge?.snapshot?.() || {};
      const raid = s.raid || s.raids || {};
      const enemies = Array.isArray(s.enemies) ? s.enemies : [];
      const soldiers = Array.isArray(s.soldiers) ? s.soldiers : [];
      const rawPhase = String(raid.phase || 'idle').toLowerCase();
      const phase = PHASES.includes(rawPhase) ? rawPhase : 'idle';
      runtime.state.set('combat.raid.phase', phase);
      runtime.state.set('combat.raid.wave', Number(raid.wave || s.wave || 0));
      runtime.state.set('combat.raid.enemies', enemies.length);
      runtime.state.set('combat.army.soldiers', soldiers.length);
      runtime.state.set('combat.at', now ?? Date.now());
    }
  };
}

export { PHASES as COMBAT_PHASES };

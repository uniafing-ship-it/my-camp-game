// V20.9: canonical projection for map, expeditions and world events.
const safeArray = value => Array.isArray(value) ? value : [];

export function createWorldMigration(bridge) {
  return {
    name: 'world-migration',
    update(_dt, now, runtime) {
      const s = bridge?.snapshot?.() || {};
      const map = s.map || {};
      const expeditions = s.expeditions || {};
      const events = s.events || {};
      runtime.state.set('world.nodes', safeArray(s.nodes || map.nodes));
      runtime.state.set('world.discovered', safeArray(map.discovered || s.discovered));
      runtime.state.set('world.expeditions', safeArray(expeditions.list || expeditions));
      runtime.state.set('world.events', safeArray(events.active || events.list || events));
      runtime.state.set('world.at', now ?? Date.now());
    }
  };
}

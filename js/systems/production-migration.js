// V20.6: canonical production projection based on migrated villagers.
import { ProductionSystem } from './production.js';

export function createProductionMigration(bridge) {
  return {
    name: 'production-migration',
    update(_dt, now, runtime) {
      const snapshot = bridge?.snapshot?.() || {};
      const villagers = bridge?.roleCounts?.() || {};
      const base = snapshot.production || {};
      runtime.state.set('production.base', {...base});
      runtime.state.set('production.roleCounts', {...villagers});
      runtime.state.set('production.projected', ProductionSystem.calculate(villagers, base));
      runtime.state.set('production.at', now ?? Date.now());
    }
  };
}

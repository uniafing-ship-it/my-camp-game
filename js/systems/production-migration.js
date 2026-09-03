// Stage 4: canonical production projection published by DomainAuthority.
import { ProductionSystem } from './production.js';

export function createProductionMigration(bridge, authority) {
  const project = (at = Date.now(), source = 'legacy-driver') => {
    const snapshot = bridge?.snapshot?.() || {};
    const villagers = bridge?.roleCounts?.() || {};
    const base = snapshot.production || {};
    const value = {
      base: {...base},
      roleCounts: {...villagers},
      projected: ProductionSystem.calculate(villagers, base),
      at
    };
    return authority?.commit?.('production', value, { source, at }) || value;
  };

  return {
    name: 'production-migration',
    update(_dt, now) { project(now ?? Date.now()); },
    refresh(source = 'legacy-driver') { return project(Date.now(), source); },
    snapshot() { return authority?.snapshot?.('production') || project(); }
  };
}

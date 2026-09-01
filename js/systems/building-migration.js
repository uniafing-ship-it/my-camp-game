// V20.7: canonical building projection. Legacy remains authoritative for mutations.
import { buildingHealthRatio, needsRepair, BUILDING_LEVELS } from './buildings.js';

export function createBuildingMigration(bridge) {
  return {
    name: 'building-migration',
    update(_dt, now, runtime) {
      const snapshot = bridge?.snapshot?.() || {};
      const source = snapshot.buildings;
      const list = Array.isArray(source) ? source : (source && typeof source === 'object' ? Object.entries(source).map(([id, b]) => ({id, ...b})) : []);
      const projected = list.map((building) => ({
        ...building,
        level: Math.max(1, Number(building.level || 1)),
        maxHp: Number(building.maxHp || BUILDING_LEVELS[building.level || 1]?.hp || 100),
        healthRatio: buildingHealthRatio(building),
        needsRepair: needsRepair(building)
      }));
      runtime.state.set('buildings.list', projected);
      runtime.state.set('buildings.count', projected.length);
      runtime.state.set('buildings.at', now ?? Date.now());
    }
  };
}

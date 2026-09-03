// Stage 4: canonical building projection published by DomainAuthority.
import { buildingHealthRatio, needsRepair, BUILDING_LEVELS } from './buildings.js';

export function createBuildingMigration(bridge, authority) {
  const project = (at = Date.now(), sourceName = 'legacy-driver') => {
    const source = bridge?.buildings?.() || bridge?.snapshot?.()?.buildings || [];
    const list = Array.isArray(source)
      ? source
      : (source && typeof source === 'object' ? Object.entries(source).map(([id, b]) => ({id, ...b})) : []);
    const projected = list.map((building, index) => {
      const level = Math.max(1, Number(building.level ?? building.lvl ?? 1));
      const maxHp = Number(building.maxHp || BUILDING_LEVELS[level]?.hp || 100);
      const normalized = {
        id: building.id ?? building.i ?? `legacy-building-${index}`,
        type: building.type ?? building.i ?? index,
        level,
        hp: Number(building.hp ?? maxHp),
        maxHp
      };
      return {
        ...normalized,
        healthRatio: buildingHealthRatio(normalized),
        needsRepair: needsRepair(normalized)
      };
    });
    const value = { list: projected, count: projected.length, at };
    return authority?.commit?.('buildings', value, { source: sourceName, at }) || value;
  };

  return {
    name: 'building-migration',
    update(_dt, now) { project(now ?? Date.now()); },
    refresh(source = 'legacy-driver') { return project(Date.now(), source); },
    snapshot() { return authority?.snapshot?.('buildings') || project(); }
  };
}

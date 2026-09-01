// V20: building math is isolated from DOM and canvas code.
export const BUILDING_LEVELS = Object.freeze({
  1: {hp: 100, productionMultiplier: 1},
  2: {hp: 175, productionMultiplier: 1.35},
  3: {hp: 275, productionMultiplier: 1.8}
});

export function buildingHealthRatio(building) {
  if (!building) return 1;
  const max = Number(building.maxHp) || 1;
  return Math.max(0, Math.min(1, (Number(building.hp) || 0) / max));
}

export function needsRepair(building, threshold = 0.75) {
  return !!building && buildingHealthRatio(building) < threshold;
}

export function repairBuilding(building, amount) {
  if (!building) return building;
  const max = Number(building.maxHp) || BUILDING_LEVELS[building.level || 1]?.hp || 100;
  return {...building, maxHp: max, hp: Math.min(max, Math.max(0, Number(building.hp || 0) + Number(amount || 0)))};
}

export function upgradeBuilding(building) {
  if (!building) return building;
  const next = Math.min(3, Number(building.level || 1) + 1);
  const spec = BUILDING_LEVELS[next];
  if (!spec) return building;
  return {...building, level: next, maxHp: spec.hp, hp: Math.min(spec.hp, Math.max(Number(building.hp || 0), spec.hp * 0.5)), productionMultiplier: spec.productionMultiplier};
}

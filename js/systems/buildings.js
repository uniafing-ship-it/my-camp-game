// V20 Foundation: data-driven building definitions.
export const BUILDING_LEVELS = {
  1: {hp: 100, productionMultiplier: 1},
  2: {hp: 175, productionMultiplier: 1.35},
  3: {hp: 275, productionMultiplier: 1.8}
};

export function buildingHealthRatio(building) {
  if (!building) return 1;
  const max = Number(building.maxHp) || 1;
  return Math.max(0, Math.min(1, (Number(building.hp) || 0) / max));
}

export function needsRepair(building, threshold = 0.75) {
  return !!building && buildingHealthRatio(building) < threshold;
}

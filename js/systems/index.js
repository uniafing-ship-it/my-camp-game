// V20.3: one place where migrated systems are registered.
import { ResourcesSystem } from './resources.js';
import { ProductionSystem } from './production.js';
import { VILLAGER_ROLES, countRoles } from './villagers.js';
import { buildingHealthRatio, needsRepair, repairBuilding, upgradeBuilding } from './buildings.js';
import { RAID_PHASES, getRaidPhase } from './raids.js';
import { LegacyStateSync } from './state-sync.js';

export const SYSTEMS = Object.freeze({
  stateSync: LegacyStateSync,
  resources: ResourcesSystem,
  production: ProductionSystem,
  villagers: { roles: VILLAGER_ROLES, countRoles },
  buildings: { buildingHealthRatio, needsRepair, repairBuilding, upgradeBuilding },
  raids: { RAID_PHASES, getRaidPhase }
});

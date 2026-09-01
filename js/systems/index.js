// V20.6: migrated systems are registered in one place.
import { createResourcesSystem } from './resources.js';
import { ProductionSystem } from './production.js';
import { VILLAGER_ROLES, countRoles } from './villagers.js';
import { createVillagerMigration } from './villager-migration.js';
import { createProductionMigration } from './production-migration.js';
import { buildingHealthRatio, needsRepair, repairBuilding, upgradeBuilding } from './buildings.js';
import { RAID_PHASES, getRaidPhase } from './raids.js';
import { LegacyStateSync } from './state-sync.js';

export function createSystems(migration) {
  return Object.freeze({
    stateSync: LegacyStateSync,
    resources: createResourcesSystem(migration),
    villagerMigration: createVillagerMigration(migration),
    productionMigration: createProductionMigration(migration),
    production: ProductionSystem,
    villagers: { roles: VILLAGER_ROLES, countRoles },
    buildings: { buildingHealthRatio, needsRepair, repairBuilding, upgradeBuilding },
    raids: { RAID_PHASES, getRaidPhase }
  });
}

export const SYSTEMS = Object.freeze({
  stateSync: LegacyStateSync,
  production: ProductionSystem,
  villagers: { roles: VILLAGER_ROLES, countRoles },
  buildings: { buildingHealthRatio, needsRepair, repairBuilding, upgradeBuilding },
  raids: { RAID_PHASES, getRaidPhase }
});

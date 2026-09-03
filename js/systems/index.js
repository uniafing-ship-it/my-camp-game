// Stage 4: migrated systems publish through one DomainAuthority boundary.
import { createResourcesSystem } from './resources.js';
import { ProductionSystem } from './production.js';
import { VILLAGER_ROLES, countRoles } from './villagers.js';
import { createVillagerMigration } from './villager-migration.js';
import { createProductionMigration } from './production-migration.js';
import { createBuildingMigration } from './building-migration.js';
import { createCombatMigration } from './combat-migration.js';
import { createWorldMigration } from './world-migration.js';
import { buildingHealthRatio, needsRepair, repairBuilding, upgradeBuilding } from './buildings.js';
import { RAID_PHASES, getRaidPhase } from './raids.js';
import { LegacyStateSync } from './state-sync.js';

export function createSystems(migration, authority) {
  return Object.freeze({
    stateSync: LegacyStateSync,
    resources: createResourcesSystem(migration, authority),
    villagerMigration: createVillagerMigration(migration, authority),
    productionMigration: createProductionMigration(migration, authority),
    buildingMigration: createBuildingMigration(migration, authority),
    combatMigration: createCombatMigration(migration, authority),
    worldMigration: createWorldMigration(migration, authority),
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

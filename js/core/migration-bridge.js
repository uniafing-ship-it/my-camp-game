// V20.2: controlled migration bridge.
// Legacy remains the gameplay authority until an individual subsystem is migrated.
import { readLegacyState, findResourceContainer, findVillagers } from './legacy-state.js';
import { ResourcesSystem } from '../systems/resources.js';
import { countRoles } from '../systems/villagers.js';

export function createMigrationBridge(source = window) {
  return {
    snapshot() {
      return readLegacyState(source);
    },
    resources() {
      return findResourceContainer(this.snapshot());
    },
    villagers() {
      return findVillagers(this.snapshot());
    },
    roleCounts() {
      return countRoles(this.villagers());
    },
    canAfford(costs) {
      return ResourcesSystem.canAfford({ resources: this.resources() }, costs);
    }
  };
}

// V20.3: controlled migration bridge.
// The legacy game remains authoritative for mutations during the migration.
import { readLegacyState, findResourceContainer, findVillagers } from './legacy-state.js';
import { ResourcesSystem } from '../systems/resources.js';
import { countRoles } from '../systems/villagers.js';

export function createMigrationBridge(source = window) {
  const legacy = () => source.MyCampLegacy || null;
  return {
    available() { return !!legacy(); },
    snapshot() {
      return legacy() || readLegacyState(source);
    },
    resources() {
      const l = legacy();
      return l?.storage || findResourceContainer(this.snapshot());
    },
    villagers() {
      const l = legacy();
      return l?.villagers || findVillagers(this.snapshot());
    },
    buildings() { return legacy()?.buildings || this.snapshot()?.buildings || {}; },
    roleCounts() { return countRoles(this.villagers()); },
    canAfford(costs) { return ResourcesSystem.canAfford({ resources: this.resources() }, costs); },
    commands: {
      save() { return legacy()?.save?.(); },
      build() { return legacy()?.build?.(); },
      upgrade() { return legacy()?.upgrade?.(); },
      repair() { return legacy()?.repair?.(); }
    }
  };
}

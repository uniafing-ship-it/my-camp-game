// V20.13: controlled migration bridge.
// The legacy game remains authoritative for mutations during the migration.
import { readLegacyState, findResourceContainer, findVillagers } from './legacy-state.js';
import { ResourcesSystem } from '../systems/resources.js';
import { countRoles } from '../systems/villagers.js';

export function createMigrationBridge(source = window) {
  const legacy = () => source.MyCampLegacy || null;
  const legacyClick = id => {
    const el = source.document?.getElementById(id);
    if (!el) return false;
    const event = new MouseEvent('click', { bubbles: true, cancelable: true, view: source });
    Object.defineProperty(event, '__v20LegacyPassthrough', { value: true });
    return el.dispatchEvent(event);
  };
  return {
    available() { return !!legacy() || !!source.document; },
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
      build() { return legacy()?.build?.() ?? legacyClick('buildBtn'); },
      upgrade() { return legacy()?.upgrade?.() ?? legacyClick('upgradeBtn'); },
      repair() { return legacy()?.repair?.(); },
      hireWorker() { return legacy()?.hireWorker?.() ?? legacyClick('hireWorkerBtn'); },
      hireFoot() { return legacy()?.hireFoot?.() ?? legacyClick('hireFootBtn'); },
      hireHunter() { return legacy()?.hireHunter?.() ?? legacyClick('hireHunterBtn'); },
      hireDog() { return legacy()?.hireDog?.() ?? legacyClick('hireDogBtn'); },
      setOrder(order) {
        if (legacy()?.setOrder) return legacy.setOrder(order);
        const el = source.document?.querySelector(`.ord-btn[data-ord="${CSS.escape(order)}"]`);
        if (!el) return false;
        const event = new MouseEvent('click', { bubbles: true, cancelable: true, view: source });
        Object.defineProperty(event, '__v20LegacyPassthrough', { value: true });
        return el.dispatchEvent(event);
      }
    }
  };
}

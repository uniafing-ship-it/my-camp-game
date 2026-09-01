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
  const invoke = (method, buttonId, ...args) => {
    const fn = legacy()?.[method];
    return typeof fn === 'function' ? fn(...args) : legacyClick(buttonId);
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
      save() { return invoke('save', null); },
      build() { return invoke('build', 'buildBtn'); },
      upgrade() { return invoke('upgrade', 'upgradeBtn'); },
      repair() { return invoke('repair', null); },
      hireWorker() { return invoke('hireWorker', 'hireWorkerBtn'); },
      hireFoot() { return invoke('hireFoot', 'hireFootBtn'); },
      hireHunter() { return invoke('hireHunter', 'hireHunterBtn'); },
      hireDog() { return invoke('hireDog', 'hireDogBtn'); },
      setOrder(order) {
        const fn = legacy()?.setOrder;
        if (typeof fn === 'function') return fn(order);
        const buttons = source.document?.querySelectorAll('.ord-btn') || [];
        const el = Array.from(buttons).find(button => button.dataset.ord === order);
        if (!el) return false;
        const event = new MouseEvent('click', { bubbles: true, cancelable: true, view: source });
        Object.defineProperty(event, '__v20LegacyPassthrough', { value: true });
        return el.dispatchEvent(event);
      }
    }
  };
}

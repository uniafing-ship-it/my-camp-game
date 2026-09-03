// Stage 4: controlled adapter between the V20 authority boundary and the
// still-running legacy simulation. DOM replay remains a compatibility path
// for legacy commands that have not yet been extracted from the inline engine.
import { readLegacyState, findResourceContainer, findVillagers } from './legacy-state.js';
import { ResourcesSystem } from '../systems/resources.js';
import { countRoles } from '../systems/villagers.js';

const safeAmount = value => Math.max(0, Number(value) || 0);

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
    replaceResources(next = {}) {
      const target = this.resources();
      if (!target || typeof target !== 'object') return null;
      const keys = new Set([...Object.keys(target), ...Object.keys(next || {})]);
      for (const key of keys) target[key] = safeAmount(next?.[key]);
      return {...target};
    },
    applyResourceDelta(delta = {}) {
      const target = this.resources();
      if (!target || typeof target !== 'object') return null;
      for (const [key, value] of Object.entries(delta || {})) {
        target[key] = safeAmount(safeAmount(target[key]) + Number(value || 0));
      }
      return {...target};
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

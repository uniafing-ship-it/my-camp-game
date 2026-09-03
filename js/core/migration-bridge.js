// Stage 5: controlled adapter between V20 authority/agent commands and the
// still-running legacy simulation. DOM replay is compatibility-only; the
// strategic agent never mutates legacy state directly.
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
  const panelActionable = (panelId, buttonId) => {
    const panel = source.document?.getElementById(panelId);
    const button = source.document?.getElementById(buttonId);
    return !!panel?.classList?.contains('on') && !!button && !button.disabled && !button.classList.contains('no');
  };
  const repairActionable = () => {
    const panel = source.document?.getElementById('upgradePanel');
    const label = source.document?.getElementById('upName');
    return !!panel?.classList?.contains('on') && String(label?.textContent || '').includes('🔧');
  };
  const activeOrder = () => source.document?.querySelector?.('.ord-btn.active')?.dataset?.ord || 'auto';
  const researchViaDom = id => {
    const safeId = String(id || '');
    if (!safeId || legacy()?.researched?.includes?.(safeId)) return false;
    const screen = source.document?.getElementById('researchScr');
    const wasHidden = screen?.classList?.contains('hidden') !== false;
    if (wasHidden) legacyClick('researchBtn');
    const button = Array.from(source.document?.querySelectorAll?.('.rs-buy') || []).find(el => el.dataset.id === safeId);
    const ok = !!button && !button.disabled && !button.classList.contains('no') ? button.dispatchEvent(new MouseEvent('click', {bubbles:true,cancelable:true,view:source})) : false;
    if (wasHidden && screen && !screen.classList.contains('hidden')) legacyClick('researchBtn');
    return ok;
  };
  const expeditionViaDom = id => legacyClick(`expStart${Math.max(0, Math.min(2, Number(id) || 0))}`);
  const repairViaKeyboard = () => {
    if (!source.document) return false;
    return source.document.dispatchEvent(new KeyboardEvent('keydown', {code:'KeyU',key:'u',bubbles:true,cancelable:true}));
  };

  return {
    available() { return !!legacy() || !!source.document; },
    snapshot() { return legacy() || readLegacyState(source); },
    resources() { const l = legacy(); return l?.storage || findResourceContainer(this.snapshot()); },
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
      for (const [key, value] of Object.entries(delta || {})) target[key] = safeAmount(safeAmount(target[key]) + Number(value || 0));
      return {...target};
    },
    villagers() { const l = legacy(); return l?.villagers || findVillagers(this.snapshot()); },
    buildings() { return legacy()?.buildings || this.snapshot()?.buildings || {}; },
    soldiers() { return legacy()?.soldiers || this.snapshot()?.soldiers || []; },
    researched() { return [...(legacy()?.researched || this.snapshot()?.researched || [])]; },
    workerOrder() { return activeOrder(); },
    actionable() {
      return {
        build: panelActionable('buildPanel','buildBtn'),
        upgrade: panelActionable('upgradePanel','upgradeBtn'),
        repair: repairActionable()
      };
    },
    expeditionBusy() {
      const workers = legacy()?.workers || this.snapshot()?.workers || [];
      const soldiers = this.soldiers();
      return [...workers, ...soldiers].filter(unit => unit?.busy === true).length;
    },
    roleCounts() { return countRoles(this.villagers()); },
    canAfford(costs) { return ResourcesSystem.canAfford({ resources: this.resources() }, costs); },
    commands: {
      save() { return invoke('save', null); },
      build() { return invoke('build', 'buildBtn'); },
      upgrade() { return invoke('upgrade', 'upgradeBtn'); },
      repair() { return typeof legacy()?.repair === 'function' ? legacy().repair() : repairViaKeyboard(); },
      research(id) { return researchViaDom(id); },
      startExpedition(id) { return expeditionViaDom(id); },
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

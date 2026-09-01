// V20.5: canonical villager projection. Mutations remain in legacy until cut-over.
import { normalizeVillager, countRoles, VILLAGER_ROLES } from './villagers.js';

export function createVillagerMigration(bridge) {
  return {
    name: 'villager-migration',
    update(_dt, now, runtime) {
      const source = bridge?.villagers?.() || [];
      const list = Array.isArray(source) ? source.map(normalizeVillager) : [];
      runtime.state.set('villagers.list', list);
      runtime.state.set('villagers.roleCounts', countRoles(list));
      runtime.state.set('villagers.roles', VILLAGER_ROLES);
      runtime.state.set('villagers.at', now ?? Date.now());
    },
    snapshot() {
      const source = bridge?.villagers?.() || [];
      return Array.isArray(source) ? source.map(normalizeVillager) : [];
    }
  };
}

// Stage 4: canonical villager projection published by DomainAuthority.
import { normalizeVillager, countRoles, VILLAGER_ROLES } from './villagers.js';

export function createVillagerMigration(bridge, authority) {
  const project = (at = Date.now(), source = 'legacy-driver') => {
    const raw = bridge?.villagers?.() || [];
    const list = Array.isArray(raw) ? raw.map((v, index) => normalizeVillager(v, index)) : [];
    const value = {
      list,
      roleCounts: countRoles(list),
      roles: VILLAGER_ROLES,
      at
    };
    return authority?.commit?.('villagers', value, { source, at }) || value;
  };

  return {
    name: 'villager-migration',
    update(_dt, now) { project(now ?? Date.now()); },
    refresh(source = 'legacy-driver') { return project(Date.now(), source); },
    snapshot() { return authority?.snapshot?.('villagers') || project(); }
  };
}

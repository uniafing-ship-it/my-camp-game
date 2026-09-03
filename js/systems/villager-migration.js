// Stage 4: canonical villagers/workers projection published by DomainAuthority.
import { normalizeVillager, countRoles, VILLAGER_ROLES } from './villagers.js';

const projectWorker = (worker = {}, index = 0) => ({
  id: worker.id ?? `legacy-worker-${index}`,
  state: String(worker.state || 'idle'),
  busy: worker.busy === true,
  cargo: {...(worker.cargo || {})}
});

export function createVillagerMigration(bridge, authority) {
  const project = (at = Date.now(), source = 'legacy-driver') => {
    const snapshot = bridge?.snapshot?.() || {};
    const raw = bridge?.villagers?.() || [];
    const rawWorkers = Array.isArray(snapshot.workers) ? snapshot.workers : [];
    const list = Array.isArray(raw) ? raw.map((v, index) => normalizeVillager(v, index)) : [];
    const workers = rawWorkers.map(projectWorker);
    const value = {
      list,
      workers,
      count: list.length,
      workerCount: workers.length,
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

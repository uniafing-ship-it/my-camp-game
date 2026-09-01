// V20: villagers are data, not UI side-effects.
export const VILLAGER_ROLES = Object.freeze({
  worker: {name:'Рабочий', icon:'👷', production:1},
  lumberjack: {name:'Лесоруб', icon:'🪓', production:1.08},
  miner: {name:'Шахтёр', icon:'⛏️', production:1.08},
  hunter: {name:'Охотник', icon:'🏹', production:1.05},
  mechanic: {name:'Механик', icon:'🔧', production:1},
  farmer: {name:'Фермер', icon:'🌾', production:1.10}
});

export function normalizeVillager(v = {}) {
  const role = VILLAGER_ROLES[v.role] ? v.role : 'worker';
  return {id: v.id ?? `villager_${Math.random().toString(36).slice(2,8)}`, role, assigned: v.assigned !== false, ...v};
}

export function countRoles(villagers = []) {
  return villagers.map(normalizeVillager).reduce((acc, v) => {
    acc[v.role] = (acc[v.role] || 0) + 1;
    return acc;
  }, {});
}

export function assignRole(villagers, id, role) {
  if (!VILLAGER_ROLES[role]) return villagers;
  return villagers.map(v => v.id === id ? {...normalizeVillager(v), role} : normalizeVillager(v));
}

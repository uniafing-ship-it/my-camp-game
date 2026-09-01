// V20 Foundation: role model used by the future villagers UI/system.
export const VILLAGER_ROLES = {
  worker: {name:'Рабочий', icon:'👷'},
  lumberjack: {name:'Лесоруб', icon:'🪓'},
  miner: {name:'Шахтёр', icon:'⛏️'},
  hunter: {name:'Охотник', icon:'🏹'},
  mechanic: {name:'Механик', icon:'🔧'},
  farmer: {name:'Фермер', icon:'🌾'}
};

export function countRoles(villagers = []) {
  return villagers.reduce((acc, v) => {
    const role = v.role || 'worker';
    acc[role] = (acc[role] || 0) + 1;
    return acc;
  }, {});
}

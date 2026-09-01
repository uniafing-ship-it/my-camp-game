import { VILLAGER_ROLES } from './villagers.js';

export const ProductionSystem = {
  get(snapshot) { return snapshot?.production || {}; },
  roleMultiplier(role) { return Number(VILLAGER_ROLES[role]?.production || 1); },
  calculate(roleCounts = {}, base = {}) {
    const out = {};
    for (const [resource, amount] of Object.entries(base)) out[resource] = Number(amount || 0);
    out.wood = (out.wood || 0) * (1 + (roleCounts.lumberjack || 0) * 0.08);
    out.stone = (out.stone || 0) * (1 + (roleCounts.miner || 0) * 0.08);
    out.food = (out.food || 0) * (1 + (roleCounts.farmer || 0) * 0.10);
    return out;
  }
};

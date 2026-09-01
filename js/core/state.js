// V20 Foundation: canonical game state adapter.
// The existing runtime remains compatible while new systems migrate here.
export const GAME_STATE_VERSION = 4;

export function createState(seed = {}) {
  return {
    version: GAME_STATE_VERSION,
    resources: seed.resources || {},
    villagers: seed.villagers || {},
    buildings: seed.buildings || {},
    army: seed.army || {},
    world: seed.world || {},
    raid: seed.raid || {},
    research: seed.research || {},
    expeditions: seed.expeditions || {},
    quests: seed.quests || {},
    events: seed.events || {},
    prestige: seed.prestige || {},
    meta: seed.meta || {}
  };
}

export function mergeState(base, patch) {
  return {
    ...base,
    ...patch,
    resources: {...base.resources, ...patch.resources},
    villagers: {...base.villagers, ...patch.villagers},
    buildings: {...base.buildings, ...patch.buildings},
    world: {...base.world, ...patch.world}
  };
}

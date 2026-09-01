// V20 Foundation: canonical state shape shared by migrated systems.
export const GAME_STATE_VERSION = 20;

const object = value => (value && typeof value === 'object' ? value : {});

export function createState(seed = {}) {
  return {
    version: GAME_STATE_VERSION,
    resources: object(seed.resources),
    villagers: object(seed.villagers),
    buildings: object(seed.buildings),
    army: object(seed.army),
    world: object(seed.world),
    raid: object(seed.raid),
    research: object(seed.research),
    expeditions: object(seed.expeditions),
    quests: object(seed.quests),
    events: object(seed.events),
    prestige: object(seed.prestige),
    meta: object(seed.meta)
  };
}

export function mergeState(base, patch) {
  const a = createState(base);
  const b = patch || {};
  return {
    ...a,
    ...b,
    resources: {...a.resources, ...object(b.resources)},
    villagers: {...a.villagers, ...object(b.villagers)},
    buildings: {...a.buildings, ...object(b.buildings)},
    army: {...a.army, ...object(b.army)},
    world: {...a.world, ...object(b.world)},
    raid: {...a.raid, ...object(b.raid)},
    research: {...a.research, ...object(b.research)},
    expeditions: {...a.expeditions, ...object(b.expeditions)},
    quests: {...a.quests, ...object(b.quests)},
    events: {...a.events, ...object(b.events)},
    prestige: {...a.prestige, ...object(b.prestige)},
    meta: {...a.meta, ...object(b.meta)}
  };
}

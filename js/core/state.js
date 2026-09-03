// V20 Foundation: canonical state shape shared by migrated systems.
export const GAME_STATE_VERSION = 20;

const object = value => (value && typeof value === 'object' ? value : {});

export function createState(seed = {}) {
  return {
    version: GAME_STATE_VERSION,
    resources: object(seed.resources),
    buildings: object(seed.buildings),
    production: object(seed.production),
    villagers: object(seed.villagers),
    combat: object(seed.combat),
    world: object(seed.world),
    save: object(seed.save),
    ui: object(seed.ui),
    army: object(seed.army),
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
    buildings: {...a.buildings, ...object(b.buildings)},
    production: {...a.production, ...object(b.production)},
    villagers: {...a.villagers, ...object(b.villagers)},
    combat: {...a.combat, ...object(b.combat)},
    world: {...a.world, ...object(b.world)},
    save: {...a.save, ...object(b.save)},
    ui: {...a.ui, ...object(b.ui)},
    army: {...a.army, ...object(b.army)},
    raid: {...a.raid, ...object(b.raid)},
    research: {...a.research, ...object(b.research)},
    expeditions: {...a.expeditions, ...object(b.expeditions)},
    quests: {...a.quests, ...object(b.quests)},
    events: {...a.events, ...object(b.events)},
    prestige: {...a.prestige, ...object(b.prestige)},
    meta: {...a.meta, ...object(b.meta)}
  };
}

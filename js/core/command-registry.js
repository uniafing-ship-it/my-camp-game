// V20.11: first command adapters. They validate actions without double-applying them.
export function registerCommandAdapters(commands, migration) {
  commands.register('resources.canAfford', {
    can: costs => migration?.canAfford?.(costs) === true,
    execute: costs => ({ allowed: migration?.canAfford?.(costs) === true, costs: {...(costs || {})} })
  });

  commands.register('villagers.snapshot', {
    can: () => true,
    execute: () => migration?.villagers?.() || []
  });

  commands.register('buildings.snapshot', {
    can: () => true,
    execute: () => {
      const s = migration?.snapshot?.() || {};
      return s.buildings || [];
    }
  });
}

// V20.13: command adapters. Mutations delegate to the existing gameplay authority.
export function registerCommandAdapters(commands, migration) {
  commands.register('resources.canAfford', {
    can: costs => migration?.canAfford?.(costs) === true,
    execute: costs => ({ allowed: migration?.canAfford?.(costs) === true, costs: {...(costs || {})} })
  });
  commands.register('villagers.snapshot', { can: () => true, execute: () => migration?.villagers?.() || [] });
  commands.register('buildings.snapshot', {
    can: () => true,
    execute: () => migration?.buildings?.() || migration?.snapshot?.()?.buildings || []
  });
  commands.register('build', {
    can: () => typeof migration?.commands?.build === 'function',
    execute: payload => migration.commands.build(payload)
  });
  commands.register('upgrade', {
    can: () => typeof migration?.commands?.upgrade === 'function',
    execute: payload => migration.commands.upgrade(payload)
  });
  for (const [name, method] of [['hire.worker','hireWorker'],['hire.foot','hireFoot'],['hire.hunter','hireHunter'],['hire.dog','hireDog']]) {
    commands.register(name, {
      can: () => typeof migration?.commands?.[method] === 'function',
      execute: payload => migration.commands[method](payload)
    });
  }
  commands.register('workers.order', {
    can: order => typeof order === 'string' && typeof migration?.commands?.setOrder === 'function',
    execute: order => migration.commands.setOrder(order)
  });
}

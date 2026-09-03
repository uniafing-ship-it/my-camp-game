// Stage 4: command adapters cross the V20 boundary first. The inline legacy
// engine may still execute the low-level simulation mutation, after which the
// affected canonical domains are refreshed immediately.
export function registerCommandAdapters(commands, migration, runtime, authority) {
  const system = name => runtime?.get?.(name);
  const refresh = (names, source = 'v20-command') => {
    for (const name of names) system(name)?.refresh?.(source);
  };
  const executeLegacy = (method, payload, affected = []) => {
    const fn = migration?.commands?.[method];
    if (typeof fn !== 'function') return false;
    const result = fn(payload);
    refresh(affected);
    return result;
  };

  commands.register('resources.canAfford', {
    can: costs => system('resources')?.canAfford?.(costs) === true,
    execute: costs => ({
      allowed: system('resources')?.canAfford?.(costs) === true,
      costs: {...(costs || {})}
    })
  });
  commands.register('resources.snapshot', {
    can: () => true,
    execute: () => system('resources')?.snapshot?.() || {}
  });
  commands.register('authority.status', {
    can: () => true,
    execute: () => authority?.status?.() || {}
  });
  commands.register('villagers.snapshot', {
    can: () => true,
    execute: () => authority?.snapshot?.('villagers') || {}
  });
  commands.register('buildings.snapshot', {
    can: () => true,
    execute: () => authority?.snapshot?.('buildings') || {}
  });

  commands.register('build', {
    can: () => typeof migration?.commands?.build === 'function',
    execute: payload => executeLegacy('build', payload, [
      'resources', 'buildingMigration', 'villagerMigration', 'productionMigration'
    ])
  });
  commands.register('upgrade', {
    can: () => typeof migration?.commands?.upgrade === 'function',
    execute: payload => executeLegacy('upgrade', payload, [
      'resources', 'buildingMigration', 'villagerMigration', 'productionMigration', 'combatMigration'
    ])
  });

  const hires = [
    ['hire.worker', 'hireWorker'],
    ['hire.foot', 'hireFoot'],
    ['hire.hunter', 'hireHunter'],
    ['hire.dog', 'hireDog']
  ];
  for (const [name, method] of hires) {
    commands.register(name, {
      can: () => typeof migration?.commands?.[method] === 'function',
      execute: payload => executeLegacy(method, payload, [
        'resources', 'villagerMigration', 'combatMigration'
      ])
    });
  }

  commands.register('workers.order', {
    can: order => typeof order === 'string' && typeof migration?.commands?.setOrder === 'function',
    execute: order => executeLegacy('setOrder', order, ['villagerMigration'])
  });
}

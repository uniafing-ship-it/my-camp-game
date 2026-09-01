// V20.14: safe game-agent facade.
// Read operations use normalized state; mutations go through the command bus.
export function createGameAgent(runtime) {
  const migration = runtime?.get?.('migration');
  const commands = runtime?.get?.('commands');

  const read = () => {
    const resources = migration?.resources?.() || {};
    const villagers = migration?.villagers?.() || [];
    const buildings = migration?.buildings?.() || [];
    return {
      resources: {...resources},
      villagers: villagers.map(v => ({role:v?.role || v?.kind || 'unknown', state:v?.state || 'unknown', busy:!!v?.busy})),
      villagersCount: villagers.length,
      roleCounts: {...(migration?.roleCounts?.() || {})},
      buildings: Array.isArray(buildings) ? buildings.map(b => ({id:b?.i ?? b?.id ?? null, level:b?.lvl ?? b?.level ?? 1, hp:b?.hp ?? null, maxHp:b?.maxHp ?? null})) : []
    };
  };

  const exec = (name, payload) => {
    if (!commands?.can?.(name, payload)) return {ok:false, command:name, reason:'not-available'};
    try { return {ok:true, command:name, result:commands.execute(name, payload)}; }
    catch (error) { return {ok:false, command:name, reason:String(error?.message || error)}; }
  };

  return Object.freeze({
    version:'20.14',
    state:read,
    can:(name,payload)=>!!commands?.can?.(name,payload),
    execute:exec,
    build:payload=>exec('build',payload),
    upgrade:payload=>exec('upgrade',payload),
    hireWorker:()=>exec('hire.worker'),
    hireFoot:()=>exec('hire.foot'),
    hireHunter:()=>exec('hire.hunter'),
    hireDog:()=>exec('hire.dog'),
    setOrder:order=>exec('workers.order',order)
  });
}

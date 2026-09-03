// Stage 5: canonical combat projection with strategic army composition.
const PHASES = Object.freeze(['idle','warning','active','boss','resolved']);

export function createCombatMigration(bridge, authority) {
  const project = (at = Date.now(), source = 'legacy-driver') => {
    const s = bridge?.snapshot?.() || {};
    const raid = s.raid || s.raids || {};
    const enemies = Array.isArray(s.enemies) ? s.enemies : [];
    const soldiers = Array.isArray(s.soldiers) ? s.soldiers : [];
    const rawPhase = String(raid.phase || (enemies.length ? 'active' : 'idle')).toLowerCase();
    const phase = PHASES.includes(rawPhase) ? rawPhase : 'idle';
    const count = kind => soldiers.filter(unit => unit?.kind === kind).length;
    const busy = soldiers.filter(unit => unit?.busy === true).length;
    const value = {
      raid:{phase,wave:Number(raid.wave||s.wave||0),enemies:enemies.length},
      army:{soldiers:soldiers.length,foot:count('foot'),hunter:count('hunter'),dog:count('dog'),busy,idle:Math.max(0,soldiers.length-busy)},
      at
    };
    return authority?.commit?.('combat',value,{source,at})||value;
  };
  return{name:'combat-migration',update(_dt,now){project(now??Date.now());},refresh(source='legacy-driver'){return project(Date.now(),source);},snapshot(){return authority?.snapshot?.('combat')||project();}};
}
export { PHASES as COMBAT_PHASES };

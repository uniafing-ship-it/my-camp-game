import { readFileSync, existsSync } from 'node:fs';
import { createStrategyPlanner } from '../js/agent/strategy-planner.js';
const read=p=>readFileSync(p,'utf8');
const main=read('js/main.js');
const agent=read('js/agent/game-agent.js');
const decision=read('js/agent/decision-engine.js');
const autopilot=read('js/agent/autopilot.js');
const planner=read('js/agent/strategy-planner.js');
const commands=read('js/core/command-registry.js');
const migration=read('js/core/migration-bridge.js');
const combat=read('js/systems/combat-migration.js');
const villagers=read('js/systems/villager-migration.js');
const checks=new Map([
  ['V20.22 strategic planner exists',existsSync('js/agent/strategy-planner.js')&&planner.includes("version:'20.22'")],
  ['agent reads DomainAuthority',agent.includes("source:'v20-authority'")&&agent.includes("authority?.snapshot?.(name)")],
  ['agent never writes legacy state directly',!agent.includes('MyCampLegacy')&&!planner.includes('MyCampLegacy')&&!decision.includes('MyCampLegacy')&&!autopilot.includes('MyCampLegacy')],
  ['decision engine executes generic commands',decision.includes('agent.execute(action.type,payload)')],
  ['autopilot uses action-aware safety',autopilot.includes("mode:'action-aware'")&&autopilot.includes("action.risk==='recovery'")],
  ['low-resource recovery is not reserve-blocked',autopilot.includes("action.type==='workers.order'")],
  ['strategic command adapters exist',['repair','research','expedition.start','save.now'].every(name=>commands.includes(`'${name}'`))],
  ['migration compatibility facts are read-only helpers',migration.includes('workerOrder()')&&migration.includes('actionable()')&&migration.includes('expeditionBusy()')],
  ['repair availability is contextual',migration.includes('repairActionable')&&migration.includes('repair: repairActionable()')],
  ['combat exposes unit composition',combat.includes("foot:count('foot')")&&combat.includes("hunter:count('hunter')")&&combat.includes("dog:count('dog')")],
  ['villagers expose idle/busy worker counts',villagers.includes('busyWorkers')&&villagers.includes('idleWorkers')],
  ['V20.23 runtime preserves the V20.22 strategic agent',main.includes("runtimeVersion:'20.23.0'")&&main.includes("dataset.v20Agent='20.22'")&&main.includes("dataset.v20DecisionEngine='strategic-planner'")]
]);

const repairState={
  resources:{food:1000,wood:1000,stone:1000,gold:1000,pelts:100},
  buildings:{count:17,list:[
    {id:0,type:0,hp:40,maxHp:100,needsRepair:true},
    {id:3,type:3,hp:100,maxHp:100,needsRepair:false},
    {id:13,type:13,hp:100,maxHp:100,needsRepair:false}
  ]},
  villagers:{workerCount:10,idleWorkers:10,busyWorkers:0},
  combat:{raid:{phase:'idle',wave:1},army:{soldiers:18,idle:18,foot:8,hunter:6,dog:4}},
  world:{dayT:100},
  progression:{researched:['axes','bags','armor','arrows','walls','hounds']},
  compatibility:{workerOrder:'food',actionable:{build:false,upgrade:false,repair:true},expeditionBusy:1}
};
const repairPlan=createStrategyPlanner().plan(repairState);
checks.set('planner actively selects contextual repair',repairPlan.goal==='repair-camp'&&repairPlan.action.type==='repair'&&repairPlan.action.risk==='maintenance');

let failed=false;for(const [name,ok] of checks){console.log(`${ok?'PASS':'FAIL'} ${name}`);if(!ok)failed=true;}if(failed)process.exit(1);console.log('AGENT STATIC QA PASS');

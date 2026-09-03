// Stage 5 / V20.22: deterministic multi-action decision engine.
import { createStrategyPlanner } from './strategy-planner.js';

export function createDecisionEngine(agent){
  const planner=createStrategyPlanner();
  const lastBySignature=new Map();
  const cooldown=8000;
  const duplicateCooldown=20000;
  const signature=a=>`${a?.type||'observe'}:${a?.value??''}`;

  const evaluate=()=>planner.plan(agent.state());
  const execute=actionOverride=>{
    const plan=evaluate();
    const action=actionOverride||plan.action;
    if(!action||action.type==='observe')return{ok:false,action,plan,reason:'no-action'};
    const now=Date.now();const sig=signature(action);const last=lastBySignature.get(sig)||0;
    const limit=action.type==='workers.order'?duplicateCooldown:cooldown;
    if(now-last<limit)return{ok:false,action,plan,reason:'cooldown'};
    const payload=Object.prototype.hasOwnProperty.call(action,'value')?action.value:undefined;
    const result=agent.execute(action.type,payload);
    if(result?.ok)lastBySignature.set(sig,now);
    return{...result,action,plan};
  };

  return Object.freeze({
    version:'20.22',evaluate,
    plan(){return evaluate().action;},
    strategy(){return evaluate();},
    execute,
    cooldowns(){return Object.fromEntries([...lastBySignature.entries()]);}
  });
}

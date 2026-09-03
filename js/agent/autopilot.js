// Stage 5 / V20.22: bounded strategic autopilot. Disabled by default.
const DEFAULT_INTERVAL=12000;
const MIN_RESERVE=Object.freeze({food:10,wood:10,stone:10,gold:0,pelts:0});
const num=(o,k)=>Math.max(0,Number(o?.[k]||0));

export function createAutopilot(agent,decisionEngine,options={}){
  let enabled=false,timer=null,busy=false,lastResult=null;
  const interval=Math.max(10000,Number(options.interval||DEFAULT_INTERVAL));
  const reserve={...MIN_RESERVE,...(options.reserve||{})};

  const safeAction=(action,state=agent.state())=>{
    if(!action||action.type==='observe')return{ok:false,reason:'no-action'};
    const phase=state.combat?.raid?.phase||'idle';
    const nightT=Number(state.world?.dayT||0);
    const afterFirst=nightT>=180, phaseT=afterFirst?(nightT-180)%90:-1;
    const isNight=afterFirst&&phaseT<30;
    if(['active','boss'].includes(phase)||isNight)return{ok:false,reason:'combat-active'};
    if(action.risk==='recovery'||action.type==='workers.order'||action.type==='expedition.start')return{ok:true,reason:'non-spending'};
    const resources=state.resources||{};
    if(action.costs){
      for(const [key,cost] of Object.entries(action.costs)){
        const floor=action.risk==='defense'?Math.min(Number(reserve[key]||0),5):Number(reserve[key]||0);
        if(num(resources,key)-Number(cost||0)<floor)return{ok:false,reason:`reserve-${key}`};
      }
    }else if(action.risk==='surplus'){
      if(Object.entries(reserve).some(([key,min])=>num(resources,key)<Number(min||0)*2))return{ok:false,reason:'surplus-not-proven'};
    }
    return{ok:true,reason:'safe'};
  };

  const step=()=>{
    if(busy)return{ok:false,reason:'busy'};
    const strategy=decisionEngine?.strategy?.();
    const action=strategy?.action;
    const safety=safeAction(action);
    if(!safety.ok)return lastResult={ok:false,action,strategy,reason:safety.reason};
    busy=true;
    try{return lastResult=decisionEngine.execute(action)||{ok:false,reason:'decision-engine-unavailable'};}
    finally{busy=false;}
  };
  const tick=()=>!enabled?{ok:false,reason:'disabled'}:step();

  return Object.freeze({
    version:'20.22',
    enable(){if(enabled)return;enabled=true;timer=setInterval(tick,interval);},
    disable(){enabled=false;if(timer)clearInterval(timer);timer=null;},
    isEnabled(){return enabled;},tick,step,safeAction,
    lastResult(){return lastResult;},
    safety:()=>({interval,reserve:{...reserve},mode:'action-aware'})
  });
}

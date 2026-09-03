// Stage 5 / V20.22: strategic agent reads canonical V20 domains and mutates
// the game only through CommandBus. Legacy reads are limited to compatibility
// facts that have not yet been migrated (research/order/actionable context).
export function createGameAgent(runtime){
  const authority=runtime?.get?.('authority');
  const migration=runtime?.get?.('migration');
  const commands=runtime?.get?.('commands');
  const domain=name=>authority?.snapshot?.(name)||{};
  const read=()=>{
    const resources=domain('resources');
    const villagers=domain('villagers');
    const buildings=domain('buildings');
    const combat=domain('combat');
    const world=domain('world');
    const progression={researched:migration?.researched?.()||[]};
    const compatibility={
      source:'legacy-readonly',
      workerOrder:migration?.workerOrder?.()||'auto',
      actionable:migration?.actionable?.()||{build:false,upgrade:false},
      expeditionBusy:Number(migration?.expeditionBusy?.()||0)
    };
    return{source:'v20-authority',resources,villagers,buildings,combat,world,progression,compatibility};
  };
  const exec=(name,payload)=>{
    if(!commands?.can?.(name,payload))return{ok:false,command:name,reason:'not-available'};
    try{
      const result=commands.execute(name,payload);
      if(result===false||result?.ok===false)return{ok:false,command:name,result,reason:result?.reason||'rejected'};
      return{ok:true,command:name,result};
    }catch(error){return{ok:false,command:name,reason:String(error?.message||error)};}
  };
  return Object.freeze({
    version:'20.22',state:read,
    can:(name,payload)=>!!commands?.can?.(name,payload),execute:exec,
    build:p=>exec('build',p),upgrade:p=>exec('upgrade',p),repair:()=>exec('repair'),
    research:id=>exec('research',id),startExpedition:id=>exec('expedition.start',id),
    hireWorker:()=>exec('hire.worker'),hireFoot:()=>exec('hire.foot'),hireHunter:()=>exec('hire.hunter'),hireDog:()=>exec('hire.dog'),
    setOrder:o=>exec('workers.order',o),save:()=>exec('save.now')
  });
}

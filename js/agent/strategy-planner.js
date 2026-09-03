// Stage 5 / V20.22: pure strategic planner. It never mutates game state.
const RESEARCH = Object.freeze([
  {id:'axes',cost:{gold:30,wood:100},weight:90},
  {id:'bags',cost:{gold:25,wood:80},weight:80},
  {id:'armor',cost:{gold:40,stone:120},weight:75},
  {id:'arrows',cost:{gold:60,stone:150},weight:65},
  {id:'walls',cost:{gold:50,stone:200},weight:60},
  {id:'hounds',cost:{gold:45,pelts:5},weight:55}
]);
const ORDERS = Object.freeze(['food','wood','stone','gold']);
const amount=(r,k)=>Math.max(0,Number(r?.[k]||0));
const afford=(r,c={})=>Object.entries(c).every(([k,v])=>amount(r,k)>=Number(v||0));
const afterReserve=(r,c,reserve)=>Object.entries(c||{}).every(([k,v])=>amount(r,k)-Number(v||0)>=Number(reserve?.[k]||0));
const hasBuilding=(state,id)=>state.buildings?.list?.some(b=>Number(b.type)===Number(id));
const healthRatio=b=>{const max=Math.max(1,Number(b?.maxHp||100));return Math.max(0,Math.min(1,Number(b?.hp??max)/max));};
const nightContext=(dayT=0)=>{const t=Math.max(0,Number(dayT||0));if(t<180)return{isNight:false,number:0,timeToNight:180-t};const phase=(t-180)%90;return{isNight:phase<30,number:Math.floor((t-180)/90)+1,timeToNight:phase<30?0:90-phase};};
const workerCost=n=>({food:15+n*10,wood:10+n*8});
const footCost=n=>({food:25+n*12,stone:15+n*10,gold:n*5});
const hunterCost=n=>({food:20+n*10,wood:30+n*10});
const dogCost=(n,hounds)=>({food:12+n*6,pelts:(hounds?1:2)+n});

export function createStrategyPlanner(){
  const analyze=(state={})=>{
    const resources=state.resources||{};
    const buildings=state.buildings||{list:[],count:0};
    const workers=state.villagers?.workerCount??state.workers?.count??0;
    const army=state.combat?.army||{};
    const wave=Number(state.combat?.raid?.wave||0);
    const night=nightContext(state.world?.dayT||0);
    const researched=state.progression?.researched||[];
    const stage=Math.max(0,Number(buildings.count||0));
    const repairTarget=(buildings.list||[])
      .filter(b=>b?.needsRepair===true||healthRatio(b)<.75)
      .sort((a,b)=>healthRatio(a)-healthRatio(b))[0]||null;
    const targets={
      food:80+wave*8+workers*4,
      wood:90+stage*10,
      stone:70+stage*9,
      gold:25+wave*5
    };
    const reserve={food:Math.min(50,Math.round(targets.food*.35)),wood:Math.min(60,Math.round(targets.wood*.3)),stone:Math.min(50,Math.round(targets.stone*.3)),gold:Math.min(25,Math.round(targets.gold*.25)),pelts:0};
    const deficits=ORDERS.map(key=>({key,ratio:amount(resources,key)/Math.max(1,targets[key]),missing:Math.max(0,targets[key]-amount(resources,key))})).sort((a,b)=>a.ratio-b.ratio);
    const workerTarget=Math.min(10,Math.max(2,2+Math.floor(stage/3)));
    const footTarget=Math.min(8,Math.max(1,1+Math.ceil(wave/2)));
    const hunterTarget=hasBuilding(state,3)?Math.min(6,Math.max(1,Math.ceil(Math.max(1,wave)/3))):0;
    const dogTarget=hasBuilding(state,13)?Math.min(4,Math.max(1,Math.ceil(Math.max(1,wave)/4))):0;
    return{resources,buildings,workers,army,wave,night,researched,repairTarget,targets,reserve,deficits,workerTarget,footTarget,hunterTarget,dogTarget};
  };

  const plan=(state={})=>{
    const a=analyze(state);const c=[];
    const add=(priority,action)=>c.push({priority,...action});
    const phase=state.combat?.raid?.phase||'idle';
    const currentOrder=state.compatibility?.workerOrder||'auto';
    const actionable=state.compatibility?.actionable||{};
    const idleSoldiers=Number(a.army.idle??a.army.soldiers??0);
    const idleWorkers=Number(state.villagers?.idleWorkers??Math.max(0,a.workers-Number(state.villagers?.busyWorkers||0)));

    if(['active','boss'].includes(phase)||a.night.isNight){
      return{goal:'survive-night',action:{type:'observe',reason:'combat-active',score:1},analysis:a,candidates:[]};
    }

    const emergency=a.deficits[0];
    if(a.workers>0&&emergency?.ratio<.28&&currentOrder!==emergency.key){
      add(100,{type:'workers.order',value:emergency.key,reason:`emergency-${emergency.key}`,score:1,risk:'recovery'});
    }

    if(actionable.repair&&a.repairTarget){
      add(98,{type:'repair',reason:`repair-building-${a.repairTarget.id}`,score:1-healthRatio(a.repairTarget),risk:'maintenance'});
    }

    const preNight=a.night.timeToNight<=30;
    const foots=Number(a.army.foot||0), hunters=Number(a.army.hunter||0), dogs=Number(a.army.dog||0);
    if(preNight){
      const fc=footCost(foots);if(foots<a.footTarget&&afford(a.resources,fc))add(96,{type:'hire.foot',reason:'prepare-night-foot',costs:fc,risk:'defense'});
      const hc=hunterCost(hunters);if(hunters<a.hunterTarget&&afford(a.resources,hc))add(94,{type:'hire.hunter',reason:'prepare-night-hunter',costs:hc,risk:'defense'});
      const dc=dogCost(dogs,a.researched.includes('hounds'));if(dogs<a.dogTarget&&afford(a.resources,dc))add(92,{type:'hire.dog',reason:'prepare-night-dog',costs:dc,risk:'defense'});
      if(a.workers>0&&currentOrder!=='food')add(85,{type:'workers.order',value:'food',reason:'stock-food-before-night',risk:'recovery'});
    }

    const wc=workerCost(a.workers);
    if(a.workers<a.workerTarget&&afford(a.resources,wc)&&afterReserve(a.resources,wc,{...a.reserve,food:Math.min(a.reserve.food,20),wood:Math.min(a.reserve.wood,20)})){
      add(82,{type:'hire.worker',reason:'grow-workforce',costs:wc,risk:'economy'});
    }

    if(actionable.build&&Object.entries(a.targets).every(([k,v])=>amount(a.resources,k)>=v*.85))add(78,{type:'build',reason:'expand-settlement',risk:'surplus'});

    if(!preNight){
      const fc=footCost(foots);if(foots<a.footTarget&&afford(a.resources,fc)&&afterReserve(a.resources,fc,a.reserve))add(72,{type:'hire.foot',reason:'grow-defense',costs:fc,risk:'economy'});
      const hc=hunterCost(hunters);if(hunters<a.hunterTarget&&afford(a.resources,hc)&&afterReserve(a.resources,hc,a.reserve))add(70,{type:'hire.hunter',reason:'grow-ranged-defense',costs:hc,risk:'economy'});
      const dc=dogCost(dogs,a.researched.includes('hounds'));if(dogs<a.dogTarget&&afford(a.resources,dc)&&afterReserve(a.resources,dc,a.reserve))add(68,{type:'hire.dog',reason:'grow-hounds',costs:dc,risk:'economy'});
    }

    for(const tech of RESEARCH){if(a.researched.includes(tech.id))continue;if(afford(a.resources,tech.cost)&&afterReserve(a.resources,tech.cost,a.reserve)){add(50+tech.weight/10,{type:'research',value:tech.id,reason:`research-${tech.id}`,costs:tech.cost,risk:'economy'});break;}}

    const expeditionBusy=Number(state.compatibility?.expeditionBusy||0);
    if(!preNight&&phase==='idle'&&expeditionBusy===0){
      if(a.wave>=4&&idleSoldiers>=3&&idleWorkers>=2)add(48,{type:'expedition.start',value:2,reason:'explore-ruins',risk:'deployment'});
      else if(a.deficits[0]?.ratio<.75&&idleWorkers>=2)add(46,{type:'expedition.start',value:1,reason:'gather-supplies',risk:'deployment'});
      else if(a.wave>=1&&idleSoldiers>=2)add(44,{type:'expedition.start',value:0,reason:'scout-world',risk:'deployment'});
    }

    if(actionable.upgrade&&Object.entries(a.targets).every(([k,v])=>amount(a.resources,k)>=v))add(42,{type:'upgrade',reason:'upgrade-nearby-building',risk:'surplus'});

    if(a.workers>0&&a.deficits[0]?.ratio<.95&&currentOrder!==a.deficits[0].key)add(30,{type:'workers.order',value:a.deficits[0].key,reason:`balance-${a.deficits[0].key}`,risk:'recovery'});

    c.sort((x,y)=>y.priority-x.priority);
    const selected=c[0]||{type:'observe',reason:'strategy-balanced',score:0};
    let goal='balanced-growth';
    if(a.repairTarget&&actionable.repair)goal='repair-camp';
    else if(preNight)goal='prepare-night';
    else if(a.workers<a.workerTarget)goal='grow-economy';
    else if(a.buildings.count<17)goal='expand-camp';
    else if(a.researched.length<RESEARCH.length)goal='advance-research';
    else goal='sustain-camp';
    return{goal,action:selected,analysis:a,candidates:c};
  };

  return Object.freeze({version:'20.22',analyze,plan});
}

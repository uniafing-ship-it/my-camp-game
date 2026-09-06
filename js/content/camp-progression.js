export const CAMP_TIERS=Object.freeze([
  Object.freeze({index:0,id:'camp-site',minBuildings:0,icon:'⛺',name:'СТОЯНКА'}),
  Object.freeze({index:1,id:'camp',minBuildings:3,icon:'🔥',name:'ЛАГЕРЬ'}),
  Object.freeze({index:2,id:'settlement',minBuildings:6,icon:'🏘️',name:'ПОСЕЛЕНИЕ'}),
  Object.freeze({index:3,id:'fortress',minBuildings:10,icon:'🏰',name:'КРЕПОСТЬ'}),
  Object.freeze({index:4,id:'citadel',minBuildings:14,icon:'👑',name:'ЦИТАДЕЛЬ'})
]);

export function campTierFor(buildings=0){
  const count=Math.max(0,Math.floor(Number(buildings)||0));
  return CAMP_TIERS.reduce((tier,candidate)=>count>=candidate.minBuildings?candidate:tier,CAMP_TIERS[0]);
}

export function formatCampProgress(buildings=0,total=17){
  const count=Math.max(0,Math.floor(Number(buildings)||0));
  const max=Math.max(count,Math.floor(Number(total)||17));
  const tier=campTierFor(count);
  return `${tier.icon} ${tier.name} · ${count}/${max}`;
}

function ensureStyle(doc){
  if(doc.getElementById('stage7CampProgressionStyle'))return;
  const style=doc.createElement('style');
  style.id='stage7CampProgressionStyle';
  style.textContent=`
#stage7CampTierToast{position:fixed;left:50%;top:22%;z-index:72;transform:translate(-50%,-8px);opacity:0;pointer-events:none;max-width:min(430px,calc(100vw - 32px));padding:10px 16px;border:1px solid rgba(216,183,101,.72);border-radius:12px;background:linear-gradient(180deg,rgba(48,64,54,.97),rgba(22,34,28,.98));color:#ffe6a3;font:700 15px/1.25 'Cormorant',serif;letter-spacing:.5px;text-align:center;box-shadow:0 10px 30px rgba(0,0,0,.45);transition:opacity .2s,transform .2s}#stage7CampTierToast.on{opacity:1;transform:translate(-50%,0)}
@media(max-width:760px){#stage7CampTierToast{top:32%;font-size:13px;padding:8px 12px}#levelVal{white-space:nowrap;letter-spacing:.35px}}
@media(prefers-reduced-motion:reduce){#stage7CampTierToast{transition:none!important}}
`;
  (doc.head||doc.documentElement).appendChild(style);
}

export function createCampProgression({authority,document:doc=globalThis.document,pollMs=450}={}){
  let started=false,timer=null,toastTimer=null,lastTierIndex=null,lastRendered='';
  let totalBuildings=17;
  const getLevel=()=>doc?.getElementById?.('levelVal')||null;
  const getCount=()=>Math.max(0,Number(authority?.snapshot?.('buildings')?.count)||0);

  const ensureToast=()=>{
    if(!doc)return null;
    let toast=doc.getElementById('stage7CampTierToast');
    if(!toast){toast=doc.createElement('div');toast.id='stage7CampTierToast';toast.setAttribute('aria-live','polite');doc.body.appendChild(toast);}
    return toast;
  };
  const detectTotal=level=>{
    const match=String(level?.textContent||'').match(/\/(\d+)/);
    if(match&&Number(match[1])>0)totalBuildings=Number(match[1]);
  };
  const flash=tier=>{
    const toast=ensureToast();if(!toast)return;
    clearTimeout(toastTimer);toast.textContent=`${tier.icon} Лагерь развился: ${tier.name}`;toast.classList.add('on');
    toastTimer=setTimeout(()=>toast?.classList.remove('on'),2600);
  };
  const refresh=()=>{
    const level=getLevel();if(!level)return null;
    detectTotal(level);
    const count=getCount(),tier=campTierFor(count),text=formatCampProgress(count,totalBuildings);
    if(lastTierIndex===null)lastTierIndex=tier.index;
    else if(tier.index>lastTierIndex){lastTierIndex=tier.index;flash(tier);doc?.defaultView?.dispatchEvent?.(new CustomEvent('mycamp:stage7-camp-tier',{detail:{...tier,buildings:count}}));}
    else lastTierIndex=tier.index;
    if(level.textContent!==text){level.textContent=text;lastRendered=text;}
    else lastRendered=text;
    level.dataset.campTier=tier.id;
    level.dataset.campTierIndex=String(tier.index);
    doc.documentElement.dataset.campTier=tier.id;
    return Object.freeze({...tier,buildings:count,total:totalBuildings,text:lastRendered});
  };
  const start=()=>{if(started)return false;started=true;ensureStyle(doc);ensureToast();refresh();timer=setInterval(refresh,Math.max(250,Number(pollMs)||450));return true;};
  const stop=()=>{started=false;clearInterval(timer);timer=null;clearTimeout(toastTimer);};
  const destroy=()=>{stop();doc?.getElementById?.('stage7CampTierToast')?.remove();};
  return Object.freeze({start,stop,destroy,refresh,current:()=>campTierFor(getCount()),tiers:CAMP_TIERS});
}

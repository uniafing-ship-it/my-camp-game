import { EVENT_TYPES } from '../systems/events.js';

const STORAGE_KEY='camp_stage7_encounters_v1';
const RESOURCE_ICON=Object.freeze({wood:'🌲',stone:'🪨',food:'🍓',gold:'🪙',pelts:'🐻'});

const choice=(id,label,rewards={},costs={})=>Object.freeze({id,label,rewards:Object.freeze({...rewards}),costs:Object.freeze({...costs})});

export const STAGE7_ENCOUNTERS=Object.freeze([
  Object.freeze({
    id:'forest-spoils',type:EVENT_TYPES.CACHE,wave:1,icon:'🌲',title:'Трофеи лесного рейда',
    text:'После первой ночи у стены остались пригодные припасы. Забрать можно только одну часть добычи.',
    choices:Object.freeze([
      choice('timber','Забрать связки древесины',{wood:25}),
      choice('coins','Собрать потерянные монеты',{gold:10}),
      choice('leave','Оставить всё как есть')
    ])
  }),
  Object.freeze({
    id:'stone-cache',type:EVENT_TYPES.CACHE,wave:2,icon:'🪨',title:'Расколотый обоз великанов',
    text:'Среди обломков найден запас камня и строительного леса. Лагерь успеет вывезти только один груз.',
    choices:Object.freeze([
      choice('stone','Вывезти камень',{stone:22}),
      choice('mixed','Забрать смешанный груз',{wood:16,stone:10}),
      choice('leave','Не задерживаться')
    ])
  }),
  Object.freeze({
    id:'hunter-trail',type:EVENT_TYPES.HARVEST,wave:3,icon:'🐾',title:'Свежий звериный след',
    text:'Охотники нашли богатую добычу после звериного рейда. Можно сделать запас еды или сохранить лучшие шкуры.',
    choices:Object.freeze([
      choice('food','Заготовить мясо',{food:30}),
      choice('pelts','Снять лучшие шкуры',{food:12,pelts:1}),
      choice('leave','Оставить след зверям')
    ])
  }),
  Object.freeze({
    id:'pirate-chest',type:EVENT_TYPES.MERCHANT,wave:4,icon:'🪙',title:'Пиратский сундук',
    text:'Уцелевший сундук заперт плохо. Внутри — монеты и строительные припасы, но унести всё не получится.',
    choices:Object.freeze([
      choice('gold','Забрать золото',{gold:18}),
      choice('supplies','Забрать припасы',{wood:18,stone:18}),
      choice('leave','Не трогать сундук')
    ])
  })
]);

function ensureStyle(doc){
  if(doc.getElementById('stage7EncounterStyle'))return;
  const style=doc.createElement('style');style.id='stage7EncounterStyle';style.textContent=`
#stage7EncounterBackdrop{position:fixed;inset:0;z-index:82;display:none;align-items:center;justify-content:center;padding:18px;background:rgba(6,10,8,.58);backdrop-filter:blur(3px);-webkit-backdrop-filter:blur(3px);pointer-events:auto}
#stage7EncounterBackdrop.open{display:flex}
#stage7Encounter{width:min(440px,calc(100vw - 28px));max-height:min(560px,calc(100vh - 36px));overflow:auto;padding:18px;border:1px solid rgba(216,183,101,.8);border-radius:16px;background:linear-gradient(180deg,rgba(48,64,54,.98),rgba(22,34,28,.99));box-shadow:0 20px 60px rgba(0,0,0,.55);color:#eee8d8;font:400 15px/1.35 'Alegreya',serif}
.stage7-encounter-kicker{font:700 11px/1 'Cormorant',serif;letter-spacing:2px;color:#d8b765;text-transform:uppercase}.stage7-encounter-title{margin:8px 0 6px;font:700 25px/1.05 'Cormorant',serif;color:#ffe6a3}.stage7-encounter-text{color:#d9d8ca}.stage7-encounter-actions{display:grid;gap:8px;margin-top:14px}.stage7-encounter-choice{min-height:46px;padding:9px 12px;border:1px solid rgba(208,177,96,.72);border-radius:10px;background:linear-gradient(180deg,#4a5b50,#25372f);color:#f2e7c5;font:700 14px 'Alegreya',serif;text-align:left;cursor:pointer}.stage7-encounter-choice:disabled{opacity:.4;cursor:not-allowed}.stage7-encounter-choice:active{transform:scale(.985)}
#stage7EncounterToast{position:fixed;left:50%;top:calc(18px + env(safe-area-inset-top));z-index:90;transform:translateX(-50%) translateY(-18px);opacity:0;pointer-events:none;max-width:min(460px,calc(100vw - 24px));padding:9px 14px;border:1px solid rgba(216,183,101,.7);border-radius:10px;background:rgba(24,37,30,.96);color:#ffe6a3;font:700 13px 'Alegreya',serif;box-shadow:0 8px 24px rgba(0,0,0,.4);transition:.2s}#stage7EncounterToast.on{opacity:1;transform:translateX(-50%) translateY(0)}
@media(max-width:760px){#stage7EncounterBackdrop{align-items:flex-end;padding:0}#stage7Encounter{width:100%;max-width:none;max-height:min(68vh,560px);border-radius:18px 18px 0 0;padding:16px 16px calc(16px + env(safe-area-inset-bottom));border-left:0;border-right:0;border-bottom:0}.stage7-encounter-title{font-size:22px}.stage7-encounter-text{font-size:14px}.stage7-encounter-choice{min-height:48px}}
@media(prefers-reduced-motion:reduce){#stage7EncounterToast,.stage7-encounter-choice{transition:none!important}}
`;(doc.head||doc.documentElement).appendChild(style);
}

function loadResolved(store){
  try{
    if(!store?.getItem?.('camp_save_v7')){store?.removeItem?.(STORAGE_KEY);return new Set();}
    const raw=store?.getItem?.(STORAGE_KEY);const parsed=raw?JSON.parse(raw):[];return new Set(Array.isArray(parsed)?parsed:[]);
  }catch(_){return new Set();}
}
function saveResolved(store,set){try{store?.setItem?.(STORAGE_KEY,JSON.stringify([...set]));}catch(_){}}
function rewardText(choiceDef){const parts=Object.entries(choiceDef?.rewards||{}).filter(([,v])=>Number(v)>0).map(([k,v])=>`+${v} ${RESOURCE_ICON[k]||k}`);return parts.join(' · ')||'Событие завершено';}

export function createCampEncounters({authority,commands,document:doc=globalThis.document,storage=globalThis.localStorage,pollMs=650}={}){
  const resolved=loadResolved(storage);let current=null,timer=null,toastTimer=null,started=false,bootstrapped=false;
  const ui={backdrop:null,panel:null,kicker:null,title:null,text:null,actions:null,toast:null};

  const buildUi=()=>{
    if(!doc)return false;if(ui.backdrop)return true;ensureStyle(doc);
    const backdrop=doc.createElement('div');backdrop.id='stage7EncounterBackdrop';backdrop.setAttribute('aria-hidden','true');
    backdrop.innerHTML='<section id="stage7Encounter" role="dialog" aria-modal="true" aria-labelledby="stage7EncounterTitle"><div class="stage7-encounter-kicker" data-kicker>СОБЫТИЕ ЛАГЕРЯ</div><div class="stage7-encounter-title" id="stage7EncounterTitle" data-title>—</div><div class="stage7-encounter-text" data-text>—</div><div class="stage7-encounter-actions" data-actions></div></section>';
    const toast=doc.createElement('div');toast.id='stage7EncounterToast';toast.setAttribute('aria-live','polite');doc.body.append(backdrop,toast);
    Object.assign(ui,{backdrop,panel:backdrop.querySelector('#stage7Encounter'),kicker:backdrop.querySelector('[data-kicker]'),title:backdrop.querySelector('[data-title]'),text:backdrop.querySelector('[data-text]'),actions:backdrop.querySelector('[data-actions]'),toast});
    backdrop.addEventListener('click',event=>{if(event.target===backdrop)hide();});
    doc.addEventListener('keydown',event=>{if(event.key==='Escape'&&current)hide();});
    return true;
  };
  const flash=text=>{if(!buildUi())return;clearTimeout(toastTimer);ui.toast.textContent=text;ui.toast.classList.add('on');toastTimer=setTimeout(()=>ui.toast?.classList.remove('on'),2300);};
  const hide=()=>{if(!ui.backdrop)return;ui.backdrop.classList.remove('open');ui.backdrop.setAttribute('aria-hidden','true');current=null;};
  const resolveChoice=(encounter,choiceDef)=>{
    const payload={eventId:encounter.id,choiceId:choiceDef.id,costs:choiceDef.costs,rewards:choiceDef.rewards};
    let result;try{result=commands?.execute?.('world.event.resolve',payload);}catch(err){result={ok:false,reason:err?.message||'command-failed'};}
    if(result?.ok!==true)return false;
    resolved.add(encounter.id);saveResolved(storage,resolved);hide();flash(`${encounter.icon} ${rewardText(choiceDef)}`);doc?.defaultView?.dispatchEvent?.(new CustomEvent('mycamp:stage7-encounter-resolved',{detail:{event:encounter.id,choice:choiceDef.id,result}}));return true;
  };
  const show=encounter=>{
    if(!encounter||resolved.has(encounter.id)||!buildUi())return false;current=encounter;ui.kicker.textContent=`${encounter.icon} СОБЫТИЕ ПОСЛЕ ВОЛНЫ ${encounter.wave}`;ui.title.textContent=encounter.title;ui.text.textContent=encounter.text;ui.actions.replaceChildren();
    for(const ch of encounter.choices){const button=doc.createElement('button');button.type='button';button.className='stage7-encounter-choice';button.dataset.choice=ch.id;button.textContent=ch.label;const affordable=commands?.can?.('world.event.resolve',{eventId:encounter.id,choiceId:ch.id,costs:ch.costs,rewards:ch.rewards})!==false;button.disabled=!affordable;button.addEventListener('click',()=>resolveChoice(encounter,ch));ui.actions.appendChild(button);}
    ui.backdrop.classList.add('open');ui.backdrop.setAttribute('aria-hidden','false');return true;
  };
  const check=()=>{
    const combat=authority?.snapshot?.('combat');const wave=Number(combat?.raid?.wave||0);const enemies=Number(combat?.raid?.enemies||0);if(wave<=0||enemies>0||current)return false;
    if(!bootstrapped){bootstrapped=true;const hasSaved=resolved.size>0;if(!hasSaved&&wave>1){for(const item of STAGE7_ENCOUNTERS)if(item.wave<wave)resolved.add(item.id);saveResolved(storage,resolved);}}
    const next=STAGE7_ENCOUNTERS.find(item=>item.wave<=wave&&!resolved.has(item.id));return next?show(next):false;
  };
  const start=()=>{if(started)return false;started=true;buildUi();timer=setInterval(check,Math.max(250,Number(pollMs)||650));check();return true;};
  const stop=()=>{started=false;clearInterval(timer);timer=null;clearTimeout(toastTimer);};
  const destroy=()=>{stop();ui.backdrop?.remove();ui.toast?.remove();Object.keys(ui).forEach(k=>ui[k]=null);};
  return Object.freeze({start,stop,destroy,check,showById:id=>show(STAGE7_ENCOUNTERS.find(item=>item.id===id)),hide,resolved:()=>[...resolved],definitions:STAGE7_ENCOUNTERS});
}

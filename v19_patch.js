/* V19 GAMEPLAY EXPANSION — additive patch, runs inside main game closure */
(function(){
  const V19_KEY='camp_v19_meta';
  const v19={roles:{},daily:{id:0,done:false},campSpec:'frontier',map:0,tech:[],events:0,elite:0};
  try{Object.assign(v19,JSON.parse(localStorage.getItem(V19_KEY)||'{}'));}catch(e){}
  const saveV19=()=>{try{localStorage.setItem(V19_KEY,JSON.stringify(v19));}catch(e){}};
  const notify=(s)=>{if(typeof showBanner==='function')showBanner(s);};
  const addRes=(r,n)=>{storage[r]=safe(storage[r])+n;};
  const roleNames={wood:'Лесоруб',stone:'Каменщик',food:'Охотник',gold:'Старатель',repair:'Механик'};
  const roleIcons={wood:'🪓',stone:'⛏️',food:'🏹',gold:'🪙',repair:'🔧'};
  function ensureRoles(){for(const v of villagers){if(!v.role)v.role='food';}for(const w of workers){if(!w.role)w.role='auto';}}
  function cycleRoles(){ensureRoles();const order=['wood','stone','food','gold','repair'];for(const v of villagers){const i=order.indexOf(v.role);v.role=order[(i+1)%order.length];}saveV19();notify('👥 Роли жителей обновлены');}
  function dailyTask(){
    const pool=[
      {t:'Собери 80 ресурсов',ok:()=>Object.values(stats.gathered).reduce((a,b)=>a+b,0)>=80,r:{gold:25}},
      {t:'Убей 8 врагов',ok:()=>kills>=8,r:{food:35}},
      {t:'Переживи ночной рейд',ok:()=>wave>=1&&dayT>60,r:{stone:35}},
      {t:'Сделай 2 улучшения',ok:()=>stats.upgrades>=2,r:{wood:40}}
    ];
    const d=pool[v19.daily.id%pool.length];return d;
  }
  function renderV19Panel(){
    let p=document.getElementById('v19Panel');if(!p){p=document.createElement('div');p.id='v19Panel';p.className='panel';p.style.cssText='position:fixed;left:50%;top:50%;transform:translate(-50%,-50%);z-index:40;width:min(520px,92vw);max-height:78vh;overflow:auto;padding:16px;color:#eee8d8;font-family:Alegreya,serif;';document.body.appendChild(p);}
    const d=dailyTask();const roleCount={};for(const v of villagers)roleCount[v.role]=(roleCount[v.role]||0)+1;
    p.innerHTML='<div style="font:700 24px Cormorant,serif;color:#f3d57a;margin-bottom:10px">🏕️ РАЗВИТИЕ ЛАГЕРЯ</div>'+
      '<div style="margin:8px 0"><b>🎯 Задание дня:</b> '+d.t+' · '+(d.ok()?'✅ ГОТОВО':'⏳ В ПРОЦЕССЕ')+'</div>'+
      '<div style="margin:8px 0"><b>👥 Роли:</b> '+Object.entries(roleCount).map(([k,n])=>roleIcons[k]+roleNames[k]+': '+n).join(' · ')+'</div>'+
      '<div style="margin:8px 0"><b>🏰 Специализация:</b> '+({frontier:'🧭 Пограничный лагерь',war:'⚔ Военный лагерь',trade:'🪙 Торговый лагерь'}[v19.campSpec])+'</div>'+
      '<div style="margin:8px 0"><b>🗺 Исследовано:</b> '+v19.map+' зон · <b>📐 Технологии:</b> '+v19.tech.length+'/6 · <b>⚡ События:</b> '+v19.events+'</div>'+
      '<div style="display:flex;gap:7px;flex-wrap:wrap;margin-top:14px">'+
      '<button id="v19Role" class="rs-buy">СМЕНИТЬ РОЛИ</button><button id="v19Map" class="rs-buy">РАЗВЕДАТЬ ЗОНУ</button><button id="v19Spec" class="rs-buy">СМЕНИТЬ СПЕЦИАЛИЗАЦИЮ</button><button id="v19Close" class="btn ghost">ЗАКРЫТЬ</button></div>';
    p.querySelector('#v19Role').onclick=()=>{cycleRoles();renderV19Panel();};
    p.querySelector('#v19Map').onclick=()=>{if(v19.map>=6){notify('🗺 Карта уже полностью исследована');return;}if(safe(storage.food)<20||safe(storage.gold)<10){notify('🗺 Нужно 20 еды и 10 золота');return;}storage.food-=20;storage.gold-=10;v19.map++;addRes('wood',15+v19.map*5);if(Math.random()<.35)addRes('pelts',1);saveV19();saveGame();notify('🗺 Новая зона открыта: '+v19.map+'/6');renderV19Panel();};
    p.querySelector('#v19Spec').onclick=()=>{const a=['frontier','war','trade'];v19.campSpec=a[(a.indexOf(v19.campSpec)+1)%a.length];saveV19();notify('🏕️ Специализация: '+v19.campSpec);renderV19Panel();};
    p.querySelector('#v19Close').onclick=()=>p.remove();
  }
  function openV19(){if(state!=='play')return;renderV19Panel();}
  const oldUpdate=update;
  update=function(dt){
    oldUpdate(dt);
    ensureRoles();
    if(villagers.length&&Math.floor(time*2)!==Math.floor((time-dt)*2)){
      let food=0,wood=0,stone=0,gold=0;
      for(const v of villagers){if(v.role==='food')food++;else if(v.role==='wood')wood++;else if(v.role==='stone')stone++;else if(v.role==='gold')gold++;}
      const mult=v19.campSpec==='war'?1.08:v19.campSpec==='trade'?1.05:1;
      if(food)addRes('food',Math.ceil(food*.25*mult));if(wood)addRes('wood',Math.ceil(wood*.25*mult));if(stone)addRes('stone',Math.ceil(stone*.2*mult));if(gold)addRes('gold',Math.ceil(gold*.12*mult));
    }
    if(Math.floor(time)!==Math.floor(time-dt)){
      let repairers=villagers.filter(v=>v.role==='repair').length;
      for(const b of buildings){if(b.hp<b.maxHp){b.hp=Math.min(b.maxHp,b.hp+repairers*2);}}
      if(dailyTask().ok()&&!v19.daily.done){const d=dailyTask();for(const r in d.r)addRes(r,d.r[r]);v19.daily.done=true;saveV19();saveGame();notify('🎯 ЗАДАНИЕ ДНЯ ВЫПОЛНЕНО!');}
    }
  };
  const oldRandomEvent=randomEvent;
  randomEvent=function(){
    oldRandomEvent();
    v19.events++;
    if(Math.random()<.18){const choices=[
      ()=>{addRes('wood',35);notify('🌲 Событие: богатая роща · +35 дерева');},
      ()=>{addRes('food',35);notify('🍓 Событие: удачная охота · +35 еды');},
      ()=>{for(const b of buildings)b.hp=Math.min(b.maxHp,b.hp+15);notify('🔧 Событие: добровольцы чинят лагерь');},
      ()=>{addRes('gold',20);notify('🪙 Событие: найден тайник · +20 золота');}
    ];choices[Math.floor(Math.random()*choices.length)]();}
    saveV19();
  };
  addEventListener('keydown',e=>{if(e.code==='KeyV'){e.preventDefault();openV19();initAudio();}});
  const oldUpdateHUD=updateHUD;
  updateHUD=function(){oldUpdateHUD();let el=document.getElementById('v19Mini');if(!el){el=document.createElement('div');el.id='v19Mini';el.className='panel';el.style.cssText='position:fixed;right:10px;top:230px;z-index:8;padding:6px 9px;font:700 11px Cormorant,serif;color:#d7e4cf;pointer-events:none;';document.body.appendChild(el);}el.textContent='🎯 '+dailyTask().t+' · 🗺 '+v19.map+'/6 · V19 [V]';};
  ensureRoles();saveV19();
})();

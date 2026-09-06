const STYLE_ID='aaa-visual-pass-style';
const CANVAS_ID='aaa-atmosphere';

function clamp(v,a,b){return v<a?a:(v>b?b:v);}
function seeded(i,t,m){
  const x=Math.sin(i*127.1+t*0.0017+m*311.7)*43758.5453123;
  return x-Math.floor(x);
}

export function createAAAVisualPass(doc=document){
  const root=doc.documentElement;
  const game=doc.getElementById('game');
  if(!root||!game) return {enabled:false,destroy(){}};
  if(doc.getElementById(CANVAS_ID)) return window.__myCampAAAVisuals||{enabled:true,destroy(){}};

  const style=doc.createElement('style');
  style.id=STYLE_ID;
  style.textContent=`
:root{
  --aaa-brightness:1;
  --aaa-panel-blur:10px;
  --aaa-panel-alpha:.78;
  --aaa-accent:#d9b867;
  --aaa-accent-soft:#f2d995;
}
html[data-aaa-visual="1"],html[data-aaa-visual="1"] body{background:#091109}
html[data-aaa-visual="1"] #game{
  filter:saturate(1.12) contrast(1.075) brightness(var(--aaa-brightness));
  transform:translateZ(0);backface-visibility:hidden;
}
#${CANVAS_ID}{position:fixed;inset:0;width:100%;height:100%;pointer-events:none;z-index:1;transform:translateZ(0)}
html[data-aaa-visual="1"] #vig{
  z-index:2;
  background:radial-gradient(ellipse at 50% 46%,transparent 48%,rgba(5,9,5,.12) 67%,rgba(3,5,3,.62) 100%),linear-gradient(180deg,rgba(255,223,164,.025),transparent 30%,rgba(5,12,13,.08));
}
html[data-aaa-visual="1"] #alarm{z-index:3;mix-blend-mode:screen}
html[data-aaa-visual="1"] .panel{
  background:linear-gradient(145deg,rgba(54,43,27,var(--aaa-panel-alpha)),rgba(20,18,14,.84)),radial-gradient(circle at 20% 0%,rgba(232,198,116,.10),transparent 48%);
  border:1px solid rgba(218,184,103,.58);
  box-shadow:inset 0 1px 0 rgba(255,239,194,.11),inset 0 -1px 0 rgba(0,0,0,.52),0 8px 28px rgba(0,0,0,.38),0 0 0 1px rgba(20,14,8,.42);
  backdrop-filter:blur(var(--aaa-panel-blur)) saturate(1.08);-webkit-backdrop-filter:blur(var(--aaa-panel-blur)) saturate(1.08);
}
html[data-aaa-visual="1"] .store-title{color:var(--aaa-accent-soft);text-shadow:0 1px 3px #000,0 0 14px rgba(217,184,103,.16)}
html[data-aaa-visual="1"] #levelVal,html[data-aaa-visual="1"] #bpName,html[data-aaa-visual="1"] #upName{color:#f0d991;text-shadow:0 1px 3px #000,0 0 18px rgba(230,193,101,.24)}
html[data-aaa-visual="1"] .bar{background:rgba(3,5,4,.68);border-color:rgba(176,141,70,.48);box-shadow:inset 0 1px 3px rgba(0,0,0,.75),0 1px 0 rgba(255,255,255,.035)}
html[data-aaa-visual="1"] #carryBar{background:linear-gradient(90deg,#6b9c53,#d9b85f 72%,#f3df9c)}
html[data-aaa-visual="1"] #xpBar{background:linear-gradient(90deg,#537ca5,#8f78b5 72%,#c9b5e6)}
html[data-aaa-visual="1"] .hbtn,html[data-aaa-visual="1"] .hire-btn,html[data-aaa-visual="1"] .ord-btn,html[data-aaa-visual="1"] .spd-btn,html[data-aaa-visual="1"] #buildBtn,html[data-aaa-visual="1"] #upgradeBtn{
  border-color:rgba(201,164,82,.66);background:linear-gradient(180deg,rgba(93,67,33,.92),rgba(37,27,16,.96));box-shadow:inset 0 1px 0 rgba(255,236,187,.09),0 4px 12px rgba(0,0,0,.28);transition:transform .14s ease,box-shadow .14s ease,border-color .14s ease,filter .14s ease;
}
@media (hover:hover){html[data-aaa-visual="1"] .hbtn:hover,html[data-aaa-visual="1"] .hire-btn:hover,html[data-aaa-visual="1"] .ord-btn:hover,html[data-aaa-visual="1"] .spd-btn:hover,html[data-aaa-visual="1"] #buildBtn:hover,html[data-aaa-visual="1"] #upgradeBtn:hover{border-color:#e3c477;box-shadow:inset 0 1px 0 rgba(255,244,211,.15),0 7px 18px rgba(0,0,0,.36),0 0 14px rgba(222,187,103,.12)}}
html[data-aaa-visual="1"] .hire-btn.no,html[data-aaa-visual="1"] #buildBtn.no,html[data-aaa-visual="1"] #upgradeBtn.no{filter:grayscale(.72) brightness(.57) saturate(.65)}
html[data-aaa-visual="1"] .screen{background:radial-gradient(circle at 50% 28%,rgba(79,69,46,.26),transparent 40%),linear-gradient(180deg,rgba(6,11,8,.86),rgba(8,8,8,.94));backdrop-filter:blur(7px);-webkit-backdrop-filter:blur(7px)}
html[data-aaa-visual="1"] .pause-title{text-shadow:0 4px 22px rgba(0,0,0,.75),0 0 26px rgba(218,184,103,.12)}
html[data-aaa-visual="1"] .skill-btn{border-color:rgba(225,190,105,.74);background:radial-gradient(circle at 35% 27%,rgba(113,82,38,.98),rgba(32,23,13,.98) 70%);box-shadow:inset 0 2px 5px rgba(255,235,185,.12),inset 0 -6px 12px rgba(0,0,0,.38),0 5px 18px rgba(0,0,0,.42),0 0 15px rgba(215,176,81,.11)}
html[data-aaa-quality="eco"]{--aaa-panel-blur:3px;--aaa-panel-alpha:.90}
html[data-aaa-quality="eco"] #game{filter:saturate(1.06) contrast(1.045) brightness(var(--aaa-brightness))}
@media (max-width:760px){:root{--aaa-panel-blur:6px;--aaa-panel-alpha:.84}html[data-aaa-visual="1"] .panel{box-shadow:inset 0 1px 0 rgba(255,239,194,.08),0 5px 18px rgba(0,0,0,.34)}}
@media (prefers-reduced-motion:reduce){#${CANVAS_ID}{display:none}}
`;
  doc.head.appendChild(style);

  const overlay=doc.createElement('canvas');
  overlay.id=CANVAS_ID;overlay.setAttribute('aria-hidden','true');
  game.insertAdjacentElement('afterend',overlay);
  const ctx=overlay.getContext('2d',{alpha:true,desynchronized:true});

  let W=1,H=1,DPR=1,raf=0,frames=0,fpsStamp=performance.now(),quality='high',particleScale=1,destroyed=false;
  const reduced=window.matchMedia?.('(prefers-reduced-motion: reduce)')?.matches===true;
  const isPhone=()=>Math.min(innerWidth||1,innerHeight||1)<700;

  function setQuality(next){if(next===quality)return;quality=next;root.dataset.aaaQuality=quality;particleScale=quality==='eco'?.42:(quality==='medium'?.68:1)}
  function resize(){
    W=Math.max(1,innerWidth||doc.documentElement.clientWidth||1);H=Math.max(1,innerHeight||doc.documentElement.clientHeight||1);
    DPR=Math.min(devicePixelRatio||1,isPhone()?1.25:1.6);overlay.width=Math.round(W*DPR);overlay.height=Math.round(H*DPR);overlay.style.width=W+'px';overlay.style.height=H+'px';ctx.setTransform(DPR,0,0,DPR,0,0);
    if(isPhone()&&quality==='high')setQuality('medium');
  }
  function hudText(id){return doc.getElementById(id)?.textContent||''}
  function envState(){const legacy=window.MyCampLegacy;const day=hudText('dayVal'),raid=hudText('raidVal');return{night:/НОЧЬ|🌙/.test(day)||/НОЧЬ|🌙/.test(raid),weather:legacy?.weather||'clear',enemies:Array.isArray(legacy?.enemies)?legacy.enemies.length:0}}

  function drawGrade(s){
    const sky=ctx.createLinearGradient(0,0,0,H);
    if(s.night){sky.addColorStop(0,'rgba(30,55,88,.16)');sky.addColorStop(.52,'rgba(18,35,57,.055)');sky.addColorStop(1,'rgba(5,12,18,.12)')}
    else{sky.addColorStop(0,'rgba(255,222,166,.075)');sky.addColorStop(.42,'rgba(245,210,151,.018)');sky.addColorStop(1,'rgba(20,39,25,.045)')}
    ctx.fillStyle=sky;ctx.fillRect(0,0,W,H);
    const lx=s.night?W*.76:W*.20,ly=s.night?H*.12:H*.08,lr=Math.max(W,H)*(s.night?.32:.42);const glow=ctx.createRadialGradient(lx,ly,0,lx,ly,lr);
    if(s.night){glow.addColorStop(0,'rgba(151,188,232,.075)');glow.addColorStop(1,'rgba(80,112,160,0)')}else{glow.addColorStop(0,'rgba(255,229,174,.12)');glow.addColorStop(1,'rgba(255,205,125,0)')}
    ctx.fillStyle=glow;ctx.fillRect(0,0,W,H);
    const haze=ctx.createLinearGradient(0,H*.52,0,H);haze.addColorStop(0,'rgba(10,18,12,0)');haze.addColorStop(1,s.night?'rgba(8,18,24,.09)':'rgba(30,50,31,.055)');ctx.fillStyle=haze;ctx.fillRect(0,H*.52,W,H*.48);
  }
  function drawMotes(t,s){
    const count=Math.round((isPhone()?15:32)*particleScale);ctx.save();ctx.globalCompositeOperation='screen';
    for(let i=0;i<count;i++){const speed=4+seeded(i,0,7)*11,x=(seeded(i,0,1)*W+Math.sin(t*.00018+i)*22+W)%W,y=(seeded(i,0,2)*H-t*.001*speed+H*10)%H,r=.45+seeded(i,0,3)*1.25,a=(s.night?.055:.075)*(.45+seeded(i,0,4)*.75);ctx.fillStyle=s.night?`rgba(170,205,232,${a})`:`rgba(255,226,165,${a})`;ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.fill()}
    ctx.restore();
  }
  function drawRain(t){
    const count=Math.round((isPhone()?42:78)*particleScale);ctx.save();ctx.lineCap='round';ctx.lineWidth=.8;ctx.strokeStyle='rgba(180,211,235,.18)';ctx.beginPath();
    for(let i=0;i<count;i++){const x=(seeded(i,0,11)*W+t*.48*(.65+seeded(i,0,12)))%(W+80)-40,y=(seeded(i,0,13)*H+t*.78*(.7+seeded(i,0,14)))%(H+80)-40,len=10+seeded(i,0,15)*18;ctx.moveTo(x,y);ctx.lineTo(x-4,y+len)}ctx.stroke();ctx.restore();
  }
  function drawSnow(t){
    const count=Math.round((isPhone()?32:64)*particleScale);ctx.save();
    for(let i=0;i<count;i++){const x=(seeded(i,0,31)*W+Math.sin(t*.00055+i*1.9)*18+W)%W,y=(seeded(i,0,32)*H+t*.025*(.7+seeded(i,0,33)))%(H+20)-10,r=.8+seeded(i,0,34)*1.8;ctx.fillStyle=`rgba(235,244,250,${.18+seeded(i,0,35)*.30})`;ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.fill()}ctx.restore();
  }
  function drawFog(t){
    ctx.save();ctx.globalCompositeOperation='screen';const bands=quality==='eco'?2:4;
    for(let i=0;i<bands;i++){const x=((t*.008*(i%2?1:-1)+i*W*.37)%(W*1.5))-W*.25,y=H*(.34+i*.13),rx=W*(.32+i*.04),ry=H*(.075+i*.015),g=ctx.createRadialGradient(x,y,0,x,y,rx);g.addColorStop(0,'rgba(191,208,201,.055)');g.addColorStop(1,'rgba(191,208,201,0)');ctx.fillStyle=g;ctx.beginPath();ctx.ellipse(x,y,rx,ry,0,0,Math.PI*2);ctx.fill()}ctx.restore();
  }
  function drawCombat(enemies,t){if(!enemies)return;const intensity=clamp(enemies/20,.12,.55)*(.78+Math.sin(t*.004)*.12),g=ctx.createRadialGradient(W/2,H/2,Math.min(W,H)*.27,W/2,H/2,Math.max(W,H)*.72);g.addColorStop(0,'rgba(120,15,10,0)');g.addColorStop(1,`rgba(125,18,12,${.08*intensity})`);ctx.fillStyle=g;ctx.fillRect(0,0,W,H)}

  function frame(now){
    if(destroyed)return;raf=requestAnimationFrame(frame);frames++;
    if(now-fpsStamp>=2000){const fps=frames*1000/(now-fpsStamp);frames=0;fpsStamp=now;if(fps<37)setQuality('eco');else if(fps<50)setQuality(isPhone()?'eco':'medium');else if(fps>56)setQuality(isPhone()?'medium':'high')}
    if(reduced)return;ctx.clearRect(0,0,W,H);const s=envState();root.style.setProperty('--aaa-brightness',s.night?'.94':'1.015');drawGrade(s);if(quality!=='eco')drawMotes(now,s);if(s.weather==='rain')drawRain(now);else if(s.weather==='snow')drawSnow(now);else if(s.weather==='fog')drawFog(now);drawCombat(s.enemies,now);
  }

  root.dataset.aaaVisual='1';root.dataset.aaaQuality=isPhone()?'medium':'high';quality=root.dataset.aaaQuality;particleScale=quality==='medium'?.68:1;resize();
  addEventListener('resize',resize,{passive:true});window.visualViewport?.addEventListener('resize',resize,{passive:true});raf=requestAnimationFrame(frame);
  const api={enabled:true,get quality(){return quality},setQuality(q){if(['high','medium','eco'].includes(q))setQuality(q)},destroy(){destroyed=true;cancelAnimationFrame(raf);removeEventListener('resize',resize);window.visualViewport?.removeEventListener('resize',resize);overlay.remove();style.remove();delete root.dataset.aaaVisual;delete root.dataset.aaaQuality;root.style.removeProperty('--aaa-brightness')}};
  window.__myCampAAAVisuals=api;return api;
}

// Stage 5 / V20.22 strategic AI dashboard.
// Stage 6 mobile cleanup: on phones the dashboard is available on demand
// through a compact launcher instead of permanently covering gameplay HUD.
export function createAgentPanel(agent,decisionEngine,autopilot,root=document.body){
  const doc=root?.ownerDocument||document;
  const win=doc.defaultView||window;
  const panel=doc.createElement('section');
  panel.id='v20-agent-panel';
  panel.setAttribute('aria-label','AI лагеря');
  panel.innerHTML=`<div class="v20-agent-head"><strong>AI лагеря</strong><span data-status>Выкл.</span><button class="v20-agent-close" type="button" data-close aria-label="Закрыть AI лагеря">×</button></div><div class="v20-agent-row">Стратегия: <b data-goal>—</b></div><div class="v20-agent-row">Причина: <span data-reason>—</span></div><div class="v20-agent-row">Следующее: <span data-action>—</span></div><div class="v20-agent-row">Журнал: <span data-log>нет действий</span></div><button type="button" data-step>Выполнить безопасный шаг</button><button type="button" data-toggle>Включить автопилот</button>`;
  root.appendChild(panel);

  const backdrop=doc.createElement('div');
  backdrop.id='v20-agent-backdrop';
  backdrop.setAttribute('aria-hidden','true');
  root.appendChild(backdrop);

  const launcher=doc.createElement('button');
  launcher.id='v20-agent-launcher';
  launcher.type='button';
  launcher.textContent='AI';
  launcher.setAttribute('aria-label','Открыть AI лагеря');
  launcher.setAttribute('aria-expanded','false');
  launcher.setAttribute('data-enabled','false');
  root.appendChild(launcher);

  const status=panel.querySelector('[data-status]'),goal=panel.querySelector('[data-goal]'),reason=panel.querySelector('[data-reason]'),action=panel.querySelector('[data-action]'),log=panel.querySelector('[data-log]'),toggle=panel.querySelector('[data-toggle]'),step=panel.querySelector('[data-step]'),closeBtn=panel.querySelector('[data-close]');
  const history=[];
  const mobile=typeof win.matchMedia==='function'?win.matchMedia('(max-width: 760px), (orientation: landscape) and (max-height: 520px)'):null;
  const isMobile=()=>mobile?mobile.matches:((win.innerWidth||9999)<=760||(win.innerWidth>win.innerHeight&&win.innerHeight<=520));
  const describe=a=>a?.type==='observe'?'наблюдение':`${a?.type||'—'}${Object.prototype.hasOwnProperty.call(a||{},'value')?': '+a.value:''}`;
  const push=text=>{if(!text||history[0]===text)return;history.unshift(text);history.splice(6);log.textContent=history.join(' · ')||'нет действий';};

  const setOpen=open=>{
    const active=Boolean(open&&isMobile());
    panel.classList.toggle('is-open',active);
    backdrop.classList.toggle('is-open',active);
    launcher.setAttribute('aria-expanded',String(active));
    backdrop.setAttribute('aria-hidden',String(!active));
    panel.setAttribute('aria-modal',active?'true':'false');
    if(active) closeBtn?.focus?.({preventScroll:true});
  };

  const refresh=()=>{
    const strategy=decisionEngine?.strategy?.()||{goal:'observe',action:{type:'observe',reason:'нет решения'}};
    goal.textContent=strategy.goal||'наблюдение';
    reason.textContent=strategy.action?.reason||'—';
    action.textContent=describe(strategy.action);
    const enabled=Boolean(autopilot?.isEnabled?.());
    status.textContent=enabled?'Вкл.':'Выкл.';
    toggle.textContent=enabled?'Выключить автопилот':'Включить автопилот';
    launcher.dataset.enabled=String(enabled);
    launcher.setAttribute('aria-label',`${enabled?'AI лагеря включён':'AI лагеря выключен'}. Открыть панель`);
  };

  step.addEventListener('click',()=>{const result=autopilot?.step?.();push(result?.ok?`✓ ${describe(result.action)}`:`— ${result?.reason||'нет действия'}`);refresh();});
  toggle.addEventListener('click',()=>{autopilot.isEnabled()?autopilot.disable():autopilot.enable();push(autopilot.isEnabled()?'автопилот включён':'автопилот выключен');refresh();});

  const openPanel=()=>setOpen(true);
  const closePanel=()=>setOpen(false);
  const onKey=event=>{
    if(event.key==='Escape'&&panel.classList.contains('is-open')){
      event.preventDefault();
      event.stopPropagation();
      closePanel();
      launcher.focus?.({preventScroll:true});
    }
  };
  const onMedia=()=>{if(!isMobile())setOpen(false);};

  launcher.addEventListener('click',openPanel);
  closeBtn?.addEventListener('click',closePanel);
  backdrop.addEventListener('click',closePanel);
  doc.addEventListener('keydown',onKey);
  mobile?.addEventListener?.('change',onMedia);

  const timer=setInterval(()=>{const last=autopilot?.lastResult?.();if(last?.ok)push(`✓ ${describe(last.action)}`);refresh();},1000);
  refresh();
  setOpen(false);

  return{
    element:panel,
    launcher,
    refresh,
    open:openPanel,
    close:closePanel,
    destroy(){
      clearInterval(timer);
      launcher.removeEventListener('click',openPanel);
      closeBtn?.removeEventListener('click',closePanel);
      backdrop.removeEventListener('click',closePanel);
      doc.removeEventListener('keydown',onKey);
      mobile?.removeEventListener?.('change',onMedia);
      panel.remove();
      launcher.remove();
      backdrop.remove();
    }
  };
}

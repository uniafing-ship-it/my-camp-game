// Stage 5 / V20.22: strategic AI dashboard with manual safe step.
export function createAgentPanel(agent,decisionEngine,autopilot,root=document.body){
  const panel=document.createElement('section');panel.id='v20-agent-panel';
  panel.innerHTML=`<div class="v20-agent-head"><strong>AI лагеря</strong><span data-status>Выкл.</span></div><div class="v20-agent-row">Стратегия: <b data-goal>—</b></div><div class="v20-agent-row">Причина: <span data-reason>—</span></div><div class="v20-agent-row">Следующее: <span data-action>—</span></div><div class="v20-agent-row">Журнал: <span data-log>нет действий</span></div><button type="button" data-step>Выполнить безопасный шаг</button><button type="button" data-toggle>Включить автопилот</button>`;
  root.appendChild(panel);
  const status=panel.querySelector('[data-status]'),goal=panel.querySelector('[data-goal]'),reason=panel.querySelector('[data-reason]'),action=panel.querySelector('[data-action]'),log=panel.querySelector('[data-log]'),toggle=panel.querySelector('[data-toggle]'),step=panel.querySelector('[data-step]');
  const history=[];
  const describe=a=>a?.type==='observe'?'наблюдение':`${a?.type||'—'}${Object.prototype.hasOwnProperty.call(a||{},'value')?': '+a.value:''}`;
  const push=text=>{if(!text||history[0]===text)return;history.unshift(text);history.splice(6);log.textContent=history.join(' · ')||'нет действий';};
  const refresh=()=>{const strategy=decisionEngine?.strategy?.()||{goal:'observe',action:{type:'observe',reason:'нет решения'}};goal.textContent=strategy.goal||'наблюдение';reason.textContent=strategy.action?.reason||'—';action.textContent=describe(strategy.action);status.textContent=autopilot?.isEnabled?.()?'Вкл.':'Выкл.';toggle.textContent=autopilot?.isEnabled?.()?'Выключить автопилот':'Включить автопилот';};
  step.addEventListener('click',()=>{const result=autopilot?.step?.();push(result?.ok?`✓ ${describe(result.action)}`:`— ${result?.reason||'нет действия'}`);refresh();});
  toggle.addEventListener('click',()=>{autopilot.isEnabled()?autopilot.disable():autopilot.enable();push(autopilot.isEnabled()?'автопилот включён':'автопилот выключен');refresh();});
  const timer=setInterval(()=>{const last=autopilot?.lastResult?.();if(last?.ok)push(`✓ ${describe(last.action)}`);refresh();},1000);refresh();
  return{element:panel,refresh,destroy(){clearInterval(timer);panel.remove();}};
}

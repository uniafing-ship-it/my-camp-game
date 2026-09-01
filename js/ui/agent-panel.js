// V20.18: compact in-game AI dashboard with status and recent decisions.
export function createAgentPanel(agent, decisionEngine, autopilot, root = document.body) {
  const panel = document.createElement('section');
  panel.id = 'v20-agent-panel';
  panel.innerHTML = `<div class="v20-agent-head"><strong>AI лагеря</strong><span data-status>Выкл.</span></div><div class="v20-agent-row">Цель: <b data-goal>—</b></div><div class="v20-agent-row">Причина: <span data-reason>—</span></div><div class="v20-agent-row">Действие: <span data-action>—</span></div><div class="v20-agent-row">Журнал: <span data-log>нет действий</span></div><button type="button" data-toggle>Включить автопилот</button>`;
  root.appendChild(panel);
  const status=panel.querySelector('[data-status]'), goal=panel.querySelector('[data-goal]'), reason=panel.querySelector('[data-reason]'), action=panel.querySelector('[data-action]'), log=panel.querySelector('[data-log]'), toggle=panel.querySelector('[data-toggle]');
  const history=[];
  const refresh=()=>{const plan=decisionEngine?.plan?.()||{type:'observe',reason:'нет решения'};goal.textContent=plan.value||plan.type||'наблюдение';reason.textContent=plan.reason||'—';status.textContent=autopilot?.isEnabled?.()?'Вкл.':'Выкл.';toggle.textContent=autopilot?.isEnabled?.()?'Выключить автопилот':'Включить автопилот';if(plan.type!=='observe'){const text=`${plan.type}${plan.value?': '+plan.value:''}`;action.textContent=text;if(history[0]!==text){history.unshift(text);history.splice(5);log.textContent=history.join(' · ')||'нет действий';}}};
  toggle.addEventListener('click',()=>{autopilot.isEnabled()?autopilot.disable():autopilot.enable();refresh();});
  const timer=setInterval(refresh,1000);refresh();
  return {element:panel,refresh,destroy(){clearInterval(timer);panel.remove();}};
}

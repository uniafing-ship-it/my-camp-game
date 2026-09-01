// V20.17: in-game agent control panel. No framework dependency.
export function createAgentPanel(agent, decisionEngine, autopilot, root = document.body) {
  const panel = document.createElement('section');
  panel.id = 'v20-agent-panel';
  panel.innerHTML = `<div><strong>AI лагеря</strong> <span data-status>Выкл.</span></div><div>Цель: <b data-goal>—</b></div><div>Причина: <span data-reason>—</span></div><button type="button" data-toggle>Включить автопилот</button>`;
  root.appendChild(panel);
  const status = panel.querySelector('[data-status]');
  const goal = panel.querySelector('[data-goal]');
  const reason = panel.querySelector('[data-reason]');
  const toggle = panel.querySelector('[data-toggle]');
  const refresh = () => {
    const plan = decisionEngine?.plan?.() || {type:'observe', reason:'нет решения'};
    goal.textContent = plan.value || plan.type || 'наблюдение';
    reason.textContent = plan.reason || '—';
    status.textContent = autopilot?.isEnabled?.() ? 'Вкл.' : 'Выкл.';
    toggle.textContent = autopilot?.isEnabled?.() ? 'Выключить автопилот' : 'Включить автопилот';
  };
  toggle.addEventListener('click', () => { autopilot.isEnabled() ? autopilot.disable() : autopilot.enable(); refresh(); });
  const timer = setInterval(refresh, 1000);
  refresh();
  return { element: panel, refresh, destroy() { clearInterval(timer); panel.remove(); } };
}

// V20.16: bounded optional autopilot. Disabled by default.
const DEFAULT_INTERVAL = 15000;
const MIN_RESERVE = Object.freeze({ food: 10, wood: 10, stone: 10, gold: 0 });

export function createAutopilot(agent, options = {}) {
  let enabled = false;
  let timer = null;
  let busy = false;
  const interval = Math.max(10000, Number(options.interval || DEFAULT_INTERVAL));
  const reserve = {...MIN_RESERVE, ...(options.reserve || {})};

  const safe = () => {
    const state = agent.state();
    const combat = state.combat || {};
    const phase = combat.raid?.phase || state.raid?.phase || 'idle';
    if (phase === 'active' || phase === 'boss' || phase === 'warning') return false;
    const resources = state.resources || {};
    return Object.entries(reserve).every(([key, min]) => Number(resources[key] || 0) >= Number(min));
  };

  const tick = () => {
    if (!enabled || busy || !safe()) return {ok:false, reason:'unsafe-or-disabled'};
    busy = true;
    try { return agent.decisionEngine?.execute?.() || {ok:false, reason:'decision-engine-unavailable'}; }
    finally { busy = false; }
  };

  return Object.freeze({
    version: '20.16',
    enable() { if (enabled) return; enabled = true; timer = setInterval(tick, interval); },
    disable() { enabled = false; if (timer) clearInterval(timer); timer = null; },
    isEnabled() { return enabled; },
    tick,
    safety: () => ({interval, reserve:{...reserve}})
  });
}

// V20.16: deterministic decision engine with bounded, safe execution.
const ORDER_PRIORITY = Object.freeze(['food','wood','stone','gold']);

function scoreNeed(resources = {}, key) {
  const value = Number(resources[key] ?? 0);
  const cap = Number(resources[`${key}Max`] ?? resources.max ?? 100);
  if (!Number.isFinite(value) || !Number.isFinite(cap) || cap <= 0) return 0;
  return Math.max(0, Math.min(1, 1 - value / cap));
}

export function createDecisionEngine(agent) {
  let lastAction = null;
  let lastAt = 0;
  const cooldown = 10000;
  return Object.freeze({
    version: '20.16',
    evaluate() {
      const state = agent.state();
      const resources = state.resources || {};
      const needs = ORDER_PRIORITY.map(key => ({ key, score: scoreNeed(resources, key) })).sort((a,b) => b.score - a.score);
      const top = needs[0] || { key: 'food', score: 0 };
      let action = { type: 'observe', reason: 'no-urgent-need', score: top.score };
      if (top.score >= 0.75) action = { type: 'workers.order', value: top.key, reason: `low-${top.key}`, score: top.score };
      return { action, needs, state };
    },
    plan() { return this.evaluate().action; },
    execute() {
      const now = Date.now();
      if (now - lastAt < cooldown) return { ok:false, reason:'cooldown' };
      const action = this.plan();
      if (action.type !== 'workers.order') return { ok:false, action, reason:'no-action' };
      if (lastAction === action.value && now - lastAt < cooldown * 3) return { ok:false, action, reason:'duplicate-action' };
      const result = agent.setOrder(action.value);
      if (result?.ok) { lastAction = action.value; lastAt = now; }
      return result;
    }
  });
}

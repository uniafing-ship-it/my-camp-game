// V20.15: deterministic decision engine. No autonomous mutation by default.
const ORDER_PRIORITY = Object.freeze(['food','wood','stone','gold']);

function scoreNeed(resources = {}, key) {
  const value = Number(resources[key] ?? 0);
  const cap = Number(resources[`${key}Max`] ?? resources.max ?? 100);
  if (!Number.isFinite(value) || !Number.isFinite(cap) || cap <= 0) return 0;
  return Math.max(0, Math.min(1, 1 - value / cap));
}

export function createDecisionEngine(agent) {
  return Object.freeze({
    version: '20.15',
    evaluate() {
      const state = agent.state();
      const resources = state.resources || {};
      const needs = ORDER_PRIORITY.map(key => ({ key, score: scoreNeed(resources, key) }))
        .sort((a,b) => b.score - a.score);
      const top = needs[0] || { key: 'food', score: 0 };
      let action = { type: 'observe', reason: 'no-urgent-need', score: top.score };
      if (top.score >= 0.75) action = { type: 'workers.order', value: top.key, reason: `low-${top.key}`, score: top.score };
      return { action, needs, state };
    },
    plan() { return this.evaluate().action; },
    execute() {
      const action = this.plan();
      if (action.type !== 'workers.order') return { ok: false, action, reason: 'no-action' };
      return agent.setOrder(action.value);
    }
  });
}

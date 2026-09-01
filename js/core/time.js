// V20 Foundation: deterministic clock helpers.
export function clampDelta(dt, max = 0.1) {
  return Math.max(0, Math.min(max, Number(dt) || 0));
}

export function formatSeconds(seconds) {
  const s = Math.max(0, Math.ceil(Number(seconds) || 0));
  const m = Math.floor(s / 60);
  return `${m}:${String(s % 60).padStart(2, '0')}`;
}

// V20.1: explicit runtime health check used before wiring more gameplay.
export function checkFoundation(runtime) {
  const required = ['loop','registry'];
  const missing = required.filter(name => !runtime?.get?.(name));
  return { ok: missing.length === 0, missing, version: runtime?.version || null };
}

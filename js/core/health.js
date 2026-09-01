// V20.2: explicit runtime and migration health check.
export function checkFoundation(runtime) {
  const required = ['bridge', 'migration', 'registry', 'loop'];
  const missing = required.filter(name => !runtime?.get?.(name));
  const migration = runtime?.get?.('migration');
  let migrationReadable = false;
  try {
    const snapshot = migration?.snapshot?.();
    migrationReadable = !!snapshot && typeof snapshot === 'object';
  } catch (_) {}
  return {
    ok: missing.length === 0 && migrationReadable,
    missing,
    migrationReadable,
    version: runtime?.version || null
  };
}

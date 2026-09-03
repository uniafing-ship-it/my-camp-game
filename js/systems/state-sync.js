// Stage 4: compatibility heartbeat only.
// Domain projections now publish through DomainAuthority; this system no
// longer writes resources/villagers/buildings/raid in parallel.
export const LegacyStateSync = {
  update(_dt, _now, runtime) {
    const migration = runtime?.get?.('migration');
    if (!migration) return;
    runtime.state.set('meta.legacy.available', migration.available?.() === true);
    runtime.state.set('meta.legacy.lastSync', Date.now());
  }
};

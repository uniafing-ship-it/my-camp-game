// V20.3: read-only synchronization from the legacy game into canonical StateStore.
// The legacy game remains authoritative for mutations during migration.
export const LegacyStateSync = {
  update(_dt, _now, runtime) {
    const migration = runtime?.get?.('migration');
    if (!migration) return;
    let snapshot = {};
    try { snapshot = migration.snapshot?.() || {}; } catch (_) { return; }

    const resources = migration.resources?.() || {};
    const villagers = migration.villagers?.() || [];
    const roleCounts = migration.roleCounts?.() || {};

    runtime.state.set('resources', {...resources});
    runtime.state.set('villagers.list', villagers.map(v => ({...v})));
    runtime.state.set('villagers.roleCounts', {...roleCounts});

    if (snapshot.buildings && typeof snapshot.buildings === 'object') {
      runtime.state.set('buildings', snapshot.buildings);
    }
    if (snapshot.raid && typeof snapshot.raid === 'object') {
      runtime.state.set('raid', snapshot.raid);
    }
    runtime.state.set('meta.lastLegacySync', Date.now());
  }
};

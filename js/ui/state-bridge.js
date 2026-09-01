// V20.10: one-way state -> UI bridge. It does not mutate legacy DOM.
export function createUIStateBridge(runtime, root = document.documentElement) {
  const render = () => {
    const state = runtime?.state?.get?.() || {};
    root.dataset.v20ResourcesCount = String(Object.keys(state.resources || {}).length);
    root.dataset.v20VillagersCount = String((state.villagers?.list || []).length);
    root.dataset.v20BuildingsCount = String(state.buildings?.count || 0);
    root.dataset.v20RaidPhase = String(state.combat?.raid?.phase || 'idle');
    root.dataset.v20WorldReady = String(!!state.world);
  };
  const unsubscribe = runtime?.state?.subscribe?.(render);
  render();
  return { render, destroy: () => unsubscribe?.() };
}

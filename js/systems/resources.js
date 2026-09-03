// Stage 4: resources are published through the V20 authority boundary.
// The legacy storage object remains the simulation backing store until the
// inline simulation is extracted, but writes from V20 cross one adapter only.
const safe = value => Math.max(0, Number(value) || 0);

export const ResourcesSystem = {
  get(state, key) { return safe(state?.resources?.[key]); },
  amount(state, key) { return this.get(state, key); },
  canAfford(state, costs = {}) {
    return Object.entries(costs || {}).every(([key, amount]) => this.get(state, key) >= safe(amount));
  },
  apply(state, delta = {}) {
    const resources = {...(state?.resources || {})};
    for (const [key, amount] of Object.entries(delta || {})) resources[key] = safe(resources[key]) + Number(amount || 0);
    return {...state, resources};
  },
  snapshot(source) {
    const resources = source?.resources?.() || source?.snapshot?.()?.resources || source?.snapshot?.()?.storage || {};
    return Object.fromEntries(Object.entries(resources).map(([key, value]) => [key, safe(value)]));
  }
};

export function createResourcesSystem(bridge, authority) {
  const publish = (source = 'legacy-driver', at = Date.now()) => {
    const snapshot = ResourcesSystem.snapshot(bridge);
    return authority?.commit?.('resources', snapshot, { source, at }) || snapshot;
  };

  return {
    name: 'resources',
    update(_dt, now) { publish('legacy-driver', now ?? Date.now()); },
    refresh(source = 'legacy-driver') { return publish(source); },
    snapshot() { return authority?.snapshot?.('resources') || ResourcesSystem.snapshot(bridge); },
    canAfford(costs) { return ResourcesSystem.canAfford({ resources: this.snapshot() }, costs); },
    replace(next = {}) {
      const written = bridge?.replaceResources?.(next);
      return written ? publish('v20-command') : null;
    },
    apply(delta = {}) {
      const written = bridge?.applyResourceDelta?.(delta);
      return written ? publish('v20-command') : null;
    }
  };
}

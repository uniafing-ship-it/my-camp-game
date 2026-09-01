// V20.4: resource system with a read-only legacy view during migration.
export const ResourcesSystem = {
  get(snapshot) { return snapshot?.resources || {}; },
  amount(snapshot, key) { return Number(this.get(snapshot)[key] || 0); },
  canAfford(snapshot, costs = {}) { return Object.entries(costs).every(([k,v]) => this.amount(snapshot,k) >= Number(v)); },
  apply(snapshot, delta = {}) {
    const resources = {...this.get(snapshot)};
    for (const [key, value] of Object.entries(delta)) resources[key] = Math.max(0, Number(resources[key] || 0) + Number(value || 0));
    return resources;
  },
  snapshot(bridge) {
    if (!bridge?.available?.()) return {};
    return {...(bridge.resources?.() || {})};
  }
};

export function createResourcesSystem(bridge) {
  return {
    name: 'resources',
    update(dt, now, runtime) {
      runtime.state.resources = ResourcesSystem.snapshot(bridge);
      runtime.state.resourcesAt = now ?? Date.now();
    },
    get(key) { return ResourcesSystem.amount({resources: ResourcesSystem.snapshot(bridge)}, key); },
    canAfford(costs) { return bridge?.canAfford?.(costs) ?? false; }
  };
}

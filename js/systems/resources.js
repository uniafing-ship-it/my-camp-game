export const ResourcesSystem = {
  get(snapshot) { return snapshot?.resources || {}; },
  amount(snapshot, key) { return Number(this.get(snapshot)[key] || 0); },
  canAfford(snapshot, costs = {}) { return Object.entries(costs).every(([k,v]) => this.amount(snapshot,k) >= Number(v)); },
  apply(snapshot, delta = {}) {
    const resources = {...this.get(snapshot)};
    for (const [key, value] of Object.entries(delta)) resources[key] = Math.max(0, Number(resources[key] || 0) + Number(value || 0));
    return resources;
  }
};

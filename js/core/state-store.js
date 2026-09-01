const copy = value => (typeof structuredClone === 'function' ? structuredClone(value) : JSON.parse(JSON.stringify(value)));

export class StateStore {
  constructor(initial = {}) { this.state = copy(initial); this.subscribers = new Set(); }
  get(path) { return path ? path.split('.').reduce((v, k) => v?.[k], this.state) : this.state; }
  set(path, value) { const keys = path.split('.'); let node = this.state; for (let i = 0; i < keys.length - 1; i++) node = node[keys[i]] ||= {}; node[keys.at(-1)] = value; this.subscribers.forEach(fn => fn(this.state, path)); }
  subscribe(fn) { this.subscribers.add(fn); return () => this.subscribers.delete(fn); }
}

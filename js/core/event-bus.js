export class EventBus {
  constructor() { this.listeners = new Map(); }
  on(name, handler) {
    if (!this.listeners.has(name)) this.listeners.set(name, new Set());
    this.listeners.get(name).add(handler);
    return () => this.off(name, handler);
  }
  off(name, handler) { this.listeners.get(name)?.delete(handler); }
  emit(name, payload) {
    for (const handler of this.listeners.get(name) || []) handler(payload);
  }
}

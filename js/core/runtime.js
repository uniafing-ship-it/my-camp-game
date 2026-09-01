export function createRuntime({ bus, state }) {
  const runtime = {
    version: '20.1.0',
    bus,
    state,
    startedAt: Date.now(),
    systems: new Map(),
    register(name, system) { this.systems.set(name, system); return system; },
    get(name) { return this.systems.get(name); },
    listSystems() { return [...this.systems.keys()]; }
  };
  return runtime;
}

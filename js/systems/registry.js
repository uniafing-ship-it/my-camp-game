export class SystemRegistry {
  constructor(runtime) { this.runtime = runtime; }
  add(name, system) { this.runtime.register(name, system); return system; }
  update(dt, now) {
    for (const system of this.runtime.systems.values()) system.update?.(dt, now);
  }
}

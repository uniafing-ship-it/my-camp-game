export class SystemRegistry {
  constructor(runtime) { this.runtime = runtime; }
  add(name, system) { this.runtime.register(name, system); return system; }
  update(dt, now) {
    // Only gameplay systems participate in the frame. Core runtime objects
    // (registry, loop, bridge) are deliberately excluded to prevent recursion.
    for (const [name, system] of this.runtime.systems.entries()) {
      if (name === 'registry' || name === 'loop' || name === 'bridge') continue;
      system?.update?.(dt, now, this.runtime);
    }
  }
}

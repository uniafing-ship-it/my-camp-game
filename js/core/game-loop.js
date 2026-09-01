export class GameLoop {
  constructor() { this.systems = new Set(); this.running = false; this.last = 0; this.raf = 0; }
  add(system) { this.systems.add(system); return () => this.systems.delete(system); }
  start() {
    if (this.running) return;
    this.running = true;
    const frame = now => {
      if (!this.running) return;
      const dt = Math.min(0.1, Math.max(0, (now - this.last) / 1000 || 0));
      this.last = now;
      for (const system of this.systems) system.update?.(dt, now);
      this.raf = requestAnimationFrame(frame);
    };
    this.raf = requestAnimationFrame(frame);
  }
  stop() { this.running = false; cancelAnimationFrame(this.raf); }
}

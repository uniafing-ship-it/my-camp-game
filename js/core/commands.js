// V20.11: guarded command boundary. Commands do not mutate legacy until explicitly wired.
export function createCommandBus(runtime) {
  const handlers = new Map();
  return {
    register(name, handler) { handlers.set(name, handler); },
    can(name, payload) { try { return !!handlers.get(name)?.can?.(payload, runtime); } catch (_) { return false; } },
    execute(name, payload) {
      const handler = handlers.get(name);
      if (!handler?.execute) throw new Error(`Unknown command: ${name}`);
      return handler.execute(payload, runtime);
    }
  };
}

import { EventBus } from './core/event-bus.js';
import { StateStore } from './core/state-store.js';
import { createState } from './core/state.js';
import { createRuntime } from './core/runtime.js';
import { GameLoop } from './core/game-loop.js';
import { SystemRegistry } from './systems/registry.js';
import { createSystems } from './systems/index.js';
import { legacyBridge } from './core/legacy-bridge.js';
import { createMigrationBridge } from './core/migration-bridge.js';

const bus = new EventBus();
const state = new StateStore(createState({ meta: { runtimeVersion: '20.4.0' } }));
const runtime = createRuntime({ bus, state });
const registry = new SystemRegistry(runtime);
const loop = new GameLoop();
const migration = createMigrationBridge(window);

runtime.register('bridge', legacyBridge());
runtime.register('migration', migration);
for (const [name, system] of Object.entries(createSystems(migration))) runtime.register(name, system);
runtime.register('registry', registry);
loop.add(registry);
runtime.register('loop', loop);

window.MyCampGame = Object.freeze({ runtime, bus, state, loop, migration });
document.documentElement.dataset.v20Foundation = '1';
document.documentElement.dataset.v20Migration = 'controlled';
document.documentElement.dataset.v20Resources = 'migrated-readonly';
window.dispatchEvent(new CustomEvent('mycamp:v20-ready', { detail: runtime }));

if (document.readyState === 'complete') loop.start();
else window.addEventListener('load', () => loop.start(), { once: true });

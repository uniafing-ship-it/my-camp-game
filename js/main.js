import { EventBus } from './core/event-bus.js';
import { StateStore } from './core/state-store.js';
import { createState } from './core/state.js';
import { createRuntime } from './core/runtime.js';
import { GameLoop } from './core/game-loop.js';
import { SystemRegistry } from './systems/registry.js';
import { registerSystems } from './core/register-systems.js';
import { legacyBridge } from './core/legacy-bridge.js';

const bus = new EventBus();
const state = new StateStore(createState({ meta: { runtimeVersion: '20.1.0' } }));
const runtime = createRuntime({ bus, state });
const registry = new SystemRegistry(runtime);
const loop = new GameLoop();

runtime.register('bridge', legacyBridge());
registerSystems(runtime);
runtime.register('registry', registry);
loop.add(registry);
runtime.register('loop', loop);

window.MyCampGame = Object.freeze({ runtime, bus, state, loop });
document.documentElement.dataset.v20Foundation = '1';
window.dispatchEvent(new CustomEvent('mycamp:v20-ready', { detail: runtime }));

if (document.readyState === 'complete') loop.start();
else window.addEventListener('load', () => loop.start(), { once: true });

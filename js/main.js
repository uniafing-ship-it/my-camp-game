import { EventBus } from './core/event-bus.js';
import { StateStore } from './core/state.js';
import { createRuntime } from './core/runtime.js';

const bus = new EventBus();
const state = new StateStore({ version: 20, systems: {} });
const runtime = createRuntime({ bus, state });

// Compatibility-first bootstrap: the migrated legacy game remains the source
// of gameplay truth while V20 systems are introduced behind stable interfaces.
window.MyCampGame = Object.freeze({ runtime, bus, state });
document.documentElement.dataset.v20Foundation = '1';
window.dispatchEvent(new CustomEvent('mycamp:v20-ready', { detail: runtime }));

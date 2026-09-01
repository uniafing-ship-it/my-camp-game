import { checkFoundation } from './health.js';
import { SYSTEMS } from '../systems/index.js';

export function registerSystems(runtime) {
  for (const [name, system] of Object.entries(SYSTEMS)) runtime.register(name, system);
  const health = checkFoundation(runtime);
  runtime.bus?.emit('v20:foundation-health', health);
  return health;
}

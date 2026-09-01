// V20 Foundation: unified event contract.
export const EVENT_TYPES = Object.freeze({MERCHANT:'merchant',WOLVES:'wolves',FIRE:'fire',CACHE:'cache',TRAVELLER:'traveller',HARVEST:'harvest'});

export function createEvent(type, data = {}) {
  return {id:`evt_${Date.now()}_${Math.random().toString(36).slice(2,7)}`, type, createdAt:Date.now(), ...data};
}

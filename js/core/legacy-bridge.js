export function legacyBridge() {
  return {
    save: window.saveGame || null,
    load: window.loadGame || null,
    build: window.tryBuild || window.buildBuilding || null
  };
}

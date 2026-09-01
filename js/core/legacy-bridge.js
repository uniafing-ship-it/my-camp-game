export function legacyBridge() {
  return {
    save: window.saveGame || null,
    load: window.loadGame || null,
    build: window.tryBuild || window.buildBuilding || null,
    repair: window.repairBuilding || null,
    upgrade: window.upgradeBuilding || null,
    assignVillager: window.assignVillager || window.setVillagerRole || null,
    startExpedition: window.startExpedition || null,
    explore: window.explore || window.exploreNode || null
  };
}

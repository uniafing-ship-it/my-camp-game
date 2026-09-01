export const ProductionSystem = {
  get(snapshot) { return snapshot?.production || {}; }
};

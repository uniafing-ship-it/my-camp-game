export const ResourcesSystem = {
  get(snapshot) { return snapshot?.resources || {}; }
};

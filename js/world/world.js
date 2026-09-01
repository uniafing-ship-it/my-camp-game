export const World = {
  getSnapshot() { return window.MyCampGame?.state?.get('world') || {}; }
};

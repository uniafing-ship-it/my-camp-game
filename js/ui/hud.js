export function refreshHud() {
  window.dispatchEvent(new CustomEvent('mycamp:hud-refresh'));
}

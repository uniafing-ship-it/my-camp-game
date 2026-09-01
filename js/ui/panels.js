export function setPanelVisible(element, visible) {
  if (!element) return;
  element.classList.toggle('on', Boolean(visible));
}

export function notify(message, level = 'info') {
  window.dispatchEvent(new CustomEvent('mycamp:notification', { detail: { message, level } }));
}

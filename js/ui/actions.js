// V20.12: route selected gameplay buttons through the command bus.
export function bindGameplayCommands(commands) {
  const bind = (selector, command) => {
    const el = document.querySelector(selector);
    if (!el || el.dataset.v20CommandBound === command) return false;
    el.dataset.v20CommandBound = command;
    el.addEventListener('click', event => {
      event.preventDefault();
      event.stopImmediatePropagation();
      try { commands.execute(command); } catch (error) { console.error(`[V20] ${command}`, error); }
    }, true);
    return true;
  };
  return { build: bind('#buildBtn', 'build'), upgrade: bind('#upgradeBtn', 'upgrade') };
}

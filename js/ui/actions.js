// V20.13: route gameplay actions through the command bus.
export function bindGameplayCommands(commands) {
  const bind = (selector, command, payload = undefined) => {
    const el = document.querySelector(selector);
    if (!el || el.dataset.v20CommandBound === command) return false;
    el.dataset.v20CommandBound = command;
    el.addEventListener('click', event => {
      event.preventDefault();
      event.stopImmediatePropagation();
      try { commands.execute(command, typeof payload === 'function' ? payload(el, event) : payload); }
      catch (error) { console.error(`[V20] ${command}`, error); }
    }, true);
    return true;
  };

  const actions = {
    build: bind('#buildBtn', 'build'),
    upgrade: bind('#upgradeBtn', 'upgrade'),
    hireWorker: bind('#hireWorkerBtn', 'hire.worker'),
    hireFoot: bind('#hireFootBtn', 'hire.foot'),
    hireHunter: bind('#hireHunterBtn', 'hire.hunter'),
    hireDog: bind('#hireDogBtn', 'hire.dog')
  };

  document.querySelectorAll('.ord-btn').forEach(el => {
    const order = el.dataset.ord;
    if (!order || el.dataset.v20CommandBound === 'workers.order') return;
    el.dataset.v20CommandBound = 'workers.order';
    el.addEventListener('click', event => {
      event.preventDefault();
      event.stopImmediatePropagation();
      try { commands.execute('workers.order', order); }
      catch (error) { console.error('[V20] workers.order', error); }
    }, true);
  });

  return actions;
}

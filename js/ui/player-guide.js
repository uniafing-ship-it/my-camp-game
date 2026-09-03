// Stage 6: player-facing onboarding guidance integrated into the existing quest card.
// The guide deliberately does not change gameplay, rewards, timings or controls.
// It only explains the next practical step for the early quests and then gets out
// of the player's way once the basic loop has been learned.

export const STAGE6_QUEST_HINTS = Object.freeze([
  Object.freeze({
    match: 'Сдай на склад 30',
    hint: 'Подойди к деревьям — сбор идёт автоматически. Затем вернись к складу в центре лагеря, чтобы сдать древесину.'
  }),
  Object.freeze({
    match: 'Построй ЛЕСОПИЛКУ',
    hint: 'Подойди к свободной строительной площадке у лагеря. Когда появится панель строительства, используй кнопку постройки.'
  }),
  Object.freeze({
    match: 'Собери 20 🍓',
    hint: 'Ищи ягодные кусты или добывай еду охотой. Следи за счётчиком квеста — он показывает засчитанный прогресс.'
  }),
  Object.freeze({
    match: 'Убей медведя',
    hint: 'Ищи медведя за пределами лагеря. После победы счётчик квеста обновится автоматически.'
  }),
  Object.freeze({
    match: 'Найми 2 крестьян',
    hint: 'Используй кнопку найма крестьянина в панели отряда слева внизу. Если кнопка недоступна — сначала накопи её стоимость.'
  }),
  Object.freeze({
    match: 'Убей кабана',
    hint: 'Ищи кабана вне лагеря. После победы прогресс квеста засчитается автоматически.'
  }),
  Object.freeze({
    match: 'Разделай 3 туши',
    hint: 'После охоты находи оставшиеся туши и разделывай их. Счётчик показывает, сколько уже засчитано.'
  }),
  Object.freeze({
    match: 'Убей оленя',
    hint: 'Ищи оленя вне лагеря. После победы прогресс квеста обновится автоматически.'
  }),
  Object.freeze({
    match: 'Построй ДОМ',
    hint: 'Подойди к следующей свободной строительной площадке и построй ДОМ, когда появится контекстная панель.'
  })
]);

export function questHintFor(text = '') {
  const normalized = String(text || '').trim();
  if (!normalized) return '';
  return STAGE6_QUEST_HINTS.find(item => normalized.includes(item.match))?.hint || '';
}

function ensureStyle(doc) {
  if (doc.getElementById('stage6PlayerGuideStyle')) return;
  const style = doc.createElement('style');
  style.id = 'stage6PlayerGuideStyle';
  style.textContent = `
    #playerGuideHint {
      display:none;
      margin-top:6px;
      padding-top:5px;
      border-top:1px solid rgba(201,170,99,.28);
      color:#cbd4c6;
      font:400 11px/1.25 'Alegreya',serif;
    }
    #playerGuideHint.on { display:block; }
    #playerGuideHint::before {
      content:'КАК: ';
      color:#d8b765;
      font-family:'Cormorant',serif;
      font-weight:700;
      letter-spacing:.7px;
    }
    #hud[data-hud-mode="phone"] #playerGuideHint,
    #hud[data-hud-mode="phone-narrow"] #playerGuideHint,
    #hud[data-hud-mode="landscape-phone"] #playerGuideHint {
      font-size:9.5px;
      line-height:1.18;
      margin-top:4px;
      padding-top:4px;
    }
    @media (prefers-reduced-motion:reduce) {
      #playerGuideHint { transition:none !important; }
    }
  `;
  (doc.head || doc.documentElement).appendChild(style);
}

export function createPlayerGuide(source = globalThis.document) {
  let observer = null;
  let started = false;

  const elements = () => ({
    box: source?.getElementById?.('questBox') || null,
    quest: source?.getElementById?.('questText') || null,
    hint: source?.getElementById?.('playerGuideHint') || null
  });

  const ensureHint = () => {
    if (!source) return null;
    ensureStyle(source);
    const { box, hint } = elements();
    if (hint) return hint;
    if (!box) return null;
    const node = source.createElement('div');
    node.id = 'playerGuideHint';
    node.setAttribute('aria-live', 'polite');
    node.dataset.stage = '6';
    box.appendChild(node);
    return node;
  };

  const refresh = () => {
    const node = ensureHint();
    const { quest } = elements();
    if (!node || !quest) return '';
    const hint = questHintFor(quest.textContent);
    node.textContent = hint;
    node.classList.toggle('on', Boolean(hint));
    node.dataset.active = hint ? 'true' : 'false';
    return hint;
  };

  const start = () => {
    if (started || !source) return false;
    const { quest } = elements();
    if (!quest) return false;
    started = true;
    refresh();
    const Observer = source.defaultView?.MutationObserver || globalThis.MutationObserver;
    if (typeof Observer === 'function') {
      observer = new Observer(refresh);
      observer.observe(quest, { childList: true, subtree: true, characterData: true });
    }
    return true;
  };

  const stop = () => {
    observer?.disconnect?.();
    observer = null;
    started = false;
  };

  return Object.freeze({ start, stop, refresh, hintFor: questHintFor });
}

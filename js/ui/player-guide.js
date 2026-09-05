// Stage 6: player-facing onboarding guidance integrated into the existing quest card.
// The guide deliberately does not change gameplay, rewards, timings or controls.
// It only explains the next practical step for the early quests and then gets out
// of the player's way once the basic loop has been learned.

export const STAGE6_QUEST_HINTS = Object.freeze([
  Object.freeze({
    match: 'Сдай на склад 30',
    hint: 'Подойди к деревьям — сбор идёт автоматически. Затем вернись к складу в центре лагеря, чтобы сдать древесину.',
    compact: 'Подойди к деревьям — сбор автоматический. Затем вернись к складу.'
  }),
  Object.freeze({
    match: 'Построй ЛЕСОПИЛКУ',
    hint: 'Подойди к свободной строительной площадке у лагеря. Когда появится панель строительства, используй кнопку постройки.',
    compact: 'Подойди к строительной площадке и нажми кнопку строительства.'
  }),
  Object.freeze({
    match: 'Собери 20 🍓',
    hint: 'Ищи ягодные кусты или добывай еду охотой. Следи за счётчиком квеста — он показывает засчитанный прогресс.',
    compact: 'Собирай ягодные кусты или добывай еду охотой.'
  }),
  Object.freeze({
    match: 'Убей медведя',
    hint: 'Ищи медведя за пределами лагеря. После победы счётчик квеста обновится автоматически.',
    compact: 'Найди медведя за пределами лагеря и победи его.'
  }),
  Object.freeze({
    match: 'Найми 2 крестьян',
    hint: 'Используй кнопку найма крестьянина в панели отряда слева внизу. Если кнопка недоступна — сначала накопи её стоимость.',
    compact: 'Найми крестьян в панели отряда слева внизу.'
  }),
  Object.freeze({
    match: 'Убей кабана',
    hint: 'Ищи кабана вне лагеря. После победы прогресс квеста засчитается автоматически.',
    compact: 'Найди кабана вне лагеря и победи его.'
  }),
  Object.freeze({
    match: 'Разделай 3 туши',
    hint: 'После охоты находи оставшиеся туши и разделывай их. Счётчик показывает, сколько уже засчитано.',
    compact: 'После охоты находи туши и разделывай их.'
  }),
  Object.freeze({
    match: 'Убей оленя',
    hint: 'Ищи оленя вне лагеря. После победы прогресс квеста обновится автоматически.',
    compact: 'Найди оленя вне лагеря и победи его.'
  }),
  Object.freeze({
    match: 'Построй ДОМ',
    hint: 'Подойди к следующей свободной строительной площадке и построй ДОМ, когда появится контекстная панель.',
    compact: 'Подойди к свободной площадке и построй ДОМ.'
  })
]);

export function questHintFor(text = '', compact = false) {
  const normalized = String(text || '').trim();
  if (!normalized) return '';
  const item = STAGE6_QUEST_HINTS.find(entry => normalized.includes(entry.match));
  if (!item) return '';
  return compact ? (item.compact || item.hint) : item.hint;
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
      line-height:1.16;
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
  let compactMedia = null;
  let compactListener = null;

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

  const isCompact = () => {
    const win = source?.defaultView;
    if (!win) return false;
    if (compactMedia) return compactMedia.matches;
    return ((win.innerWidth || 9999) <= 760 || (win.innerWidth > win.innerHeight && win.innerHeight <= 520));
  };

  const refresh = () => {
    const node = ensureHint();
    const { quest } = elements();
    if (!node || !quest) return '';
    const compact = isCompact();
    const hint = questHintFor(quest.textContent, compact);
    node.textContent = hint;
    node.classList.toggle('on', Boolean(hint));
    node.dataset.active = hint ? 'true' : 'false';
    node.dataset.compact = compact ? 'true' : 'false';
    return hint;
  };

  const start = () => {
    if (started || !source) return false;
    const { quest } = elements();
    if (!quest) return false;
    started = true;
    const win = source.defaultView;
    compactMedia = typeof win?.matchMedia === 'function' ? win.matchMedia('(max-width: 760px), (orientation: landscape) and (max-height: 520px)') : null;
    compactListener = () => refresh();
    compactMedia?.addEventListener?.('change', compactListener);
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
    compactMedia?.removeEventListener?.('change', compactListener);
    compactMedia = null;
    compactListener = null;
    started = false;
  };

  return Object.freeze({ start, stop, refresh, hintFor: questHintFor });
}

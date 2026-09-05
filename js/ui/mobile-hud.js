// Stage 6 mobile HUD cleanup: keep secondary controls available without
// permanently occupying scarce phone screen space.
const MOBILE_QUERY = '(max-width: 760px), (orientation: landscape) and (max-height: 520px)';

function ensureStyle(doc) {
  if (doc.getElementById('stage6MobileHudStyle')) return;
  const style = doc.createElement('style');
  style.id = 'stage6MobileHudStyle';
  style.textContent = `
    #mobileToolsBtn { display:none; }
    #relicRow:empty { display:none; }

    @media (max-width:760px), (orientation:landscape) and (max-height:520px) {
      #topRight {
        overflow:visible !important;
        padding-bottom:6px;
      }
      #topRight .tr-line {
        position:relative;
        padding-right:32px;
        min-height:28px;
        align-items:center;
      }
      #mobileToolsBtn {
        display:inline-flex;
        position:absolute;
        right:0;
        top:50%;
        transform:translateY(-50%);
        align-items:center;
        justify-content:center;
        width:28px;
        min-width:28px;
        height:28px;
        min-height:28px !important;
        padding:0;
        font-size:18px;
        line-height:1;
        letter-spacing:0;
      }
      #mobileToolsBtn:active { transform:translateY(-50%) scale(.96); }
      #topRight .tr-btns {
        display:none;
        position:absolute;
        right:0;
        top:calc(100% + 6px);
        width:min(160px,44vw);
        margin:0;
        padding:7px;
        grid-template-columns:repeat(3,1fr);
        gap:6px;
        z-index:45;
        border:1px solid rgba(201,170,99,.72);
        border-radius:10px;
        background:linear-gradient(180deg,rgba(57,76,64,.98),rgba(29,44,37,.98));
        box-shadow:0 8px 24px rgba(0,0,0,.42);
        backdrop-filter:blur(6px);
        -webkit-backdrop-filter:blur(6px);
      }
      #topRight.mobile-tools-open { z-index:44; }
      #topRight.mobile-tools-open .tr-btns { display:grid; }
      #topRight .tr-btns .hbtn {
        width:42px;
        min-width:42px;
        height:42px;
        min-height:42px;
        margin:0;
      }
      #questBox .store-title { margin-bottom:3px; }
      #squadPanel .store-title { letter-spacing:1.4px; }
      #skillPanel .store-title { letter-spacing:1.4px; }
    }

    @media (orientation:landscape) and (max-height:520px) {
      #topRight .tr-btns {
        width:min(280px,calc(100vw - 24px));
        grid-template-columns:repeat(6,1fr);
      }
      #topRight .tr-btns .hbtn {
        width:36px;
        min-width:36px;
        height:36px;
        min-height:36px;
      }
    }
  `;
  (doc.head || doc.documentElement).appendChild(style);
}

export function createMobileHud(doc = globalThis.document) {
  if (!doc) return Object.freeze({ refresh(){}, close(){}, destroy(){} });
  ensureStyle(doc);

  const topRight = doc.getElementById('topRight');
  const line = topRight?.querySelector('.tr-line');
  const tools = topRight?.querySelector('.tr-btns');
  const win = doc.defaultView || globalThis.window;
  if (!topRight || !line || !tools || !win) {
    return Object.freeze({ refresh(){}, close(){}, destroy(){} });
  }

  let button = doc.getElementById('mobileToolsBtn');
  if (!button) {
    button = doc.createElement('button');
    button.id = 'mobileToolsBtn';
    button.className = 'hbtn';
    button.type = 'button';
    button.textContent = '⋯';
    button.setAttribute('aria-label', 'Дополнительные действия');
    button.setAttribute('aria-expanded', 'false');
    line.appendChild(button);
  }

  const media = typeof win.matchMedia === 'function' ? win.matchMedia(MOBILE_QUERY) : null;
  const isMobile = () => media ? media.matches : ((win.innerWidth || 9999) <= 760 || (win.innerWidth > win.innerHeight && win.innerHeight <= 520));

  const close = () => {
    topRight.classList.remove('mobile-tools-open');
    button.setAttribute('aria-expanded', 'false');
  };

  const toggle = event => {
    event?.stopPropagation?.();
    if (!isMobile()) return;
    const open = !topRight.classList.contains('mobile-tools-open');
    topRight.classList.toggle('mobile-tools-open', open);
    button.setAttribute('aria-expanded', String(open));
  };

  const outside = event => {
    if (!isMobile() || !topRight.classList.contains('mobile-tools-open')) return;
    if (!topRight.contains(event.target)) close();
  };

  const refresh = () => {
    if (!isMobile()) close();
  };

  button.addEventListener('click', toggle);
  doc.addEventListener('pointerdown', outside, true);
  media?.addEventListener?.('change', refresh);
  win.addEventListener?.('orientationchange', close, { passive:true });

  return Object.freeze({
    element: topRight,
    button,
    refresh,
    close,
    destroy() {
      button.removeEventListener('click', toggle);
      doc.removeEventListener('pointerdown', outside, true);
      media?.removeEventListener?.('change', refresh);
      win.removeEventListener?.('orientationchange', close);
      close();
      button.remove();
    }
  });
}

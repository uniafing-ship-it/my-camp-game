import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const [main,mobileHud,agentPanel,agentCss,guide] = await Promise.all([
  readFile(new URL('../js/main.js', import.meta.url), 'utf8'),
  readFile(new URL('../js/ui/mobile-hud.js', import.meta.url), 'utf8'),
  readFile(new URL('../js/ui/agent-panel.js', import.meta.url), 'utf8'),
  readFile(new URL('../js/ui/agent-panel.css', import.meta.url), 'utf8'),
  readFile(new URL('../js/ui/player-guide.js', import.meta.url), 'utf8')
]);

assert.match(main,/createMobileHud/);
assert.match(main,/v20MobileHud='stage6-compact-v1'/);
assert.match(mobileHud,/mobileToolsBtn/);
assert.match(mobileHud,/mobile-tools-open/);
assert.match(agentPanel,/v20-agent-launcher/);
assert.match(agentPanel,/v20-agent-backdrop/);
assert.match(agentPanel,/setOpen/);
assert.match(agentCss,/@media\(max-width:760px\)/);
assert.match(agentCss,/#v20-agent-panel\.is-open\{display:block\}/);
assert.match(guide,/compact:/);
assert.match(guide,/dataset\.compact/);

console.log('Stage 6 mobile HUD static gate: PASS');

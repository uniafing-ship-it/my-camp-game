import { execFileSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';

const root = resolve('.');
const read = rel => readFileSync(join(root, rel), 'utf8');
const index = read('index.html');
const main = read('js/main.js');
const vercel = JSON.parse(read('vercel.json'));

const checks = new Map([
  ['agent panel CSS is linked from HTML', index.includes('<link rel="stylesheet" href="./js/ui/agent-panel.css">')],
  ['agent panel CSS is not imported as JavaScript', !main.includes("import './ui/agent-panel.css'")],
  ['V20 API is frozen only after agent panel creation', main.indexOf('api.agentPanel=createAgentPanel') > -1 && main.indexOf('api.agentPanel=createAgentPanel') < main.indexOf('window.MyCampGame=Object.freeze(api)')],
  ['V20.20 runtime marker exists', main.includes("runtimeVersion:'20.20.0'") && main.includes("dataset.v20Stabilization='20.20'")],
  ['adaptive HUD controller is executable script', index.includes('</script>\n<script>\n/* =========================================================\n   V4 ADAPTIVE HUD CONTROLLER')],
  ['approved first night is 180 seconds', index.includes('const FIRST_NIGHT_AT=180;')],
  ['approved recurring night cycle is 90 seconds', index.includes('const DAY_CYCLE=90,DAY_LEN=60,NIGHT_LEN=30;')],
  ['building completion uses BUILDINGS.length', index.includes('s.built>=BUILDINGS.length') && index.includes("s.built+'/'+BUILDINGS.length+' 🏙️'")],
  ['manual fishing path is absent', !index.includes('function playerFish()') && !index.includes('playerFish();')],
  ['night wave marker is persisted', index.includes('stats,dayT,nightWaveSpawned,wasNight,workersN:') && index.includes('Number.isFinite(d.nightWaveSpawned)')],
  ['hunter button gates affordability and disabled state', index.includes('hunterUnaffordable=!canAffordCost(hunterCost)') && index.includes('hireHunterBtn.disabled=hunterLocked||hunterUnaffordable')],
  ['V20 module entrypoint exists', index.includes('<script type="module" src="./js/main.js"></script>') && existsSync(join(root, 'js/main.js'))],
  ['duplicate Vercel project is guarded', typeof vercel.ignoreCommand === 'string' && vercel.ignoreCommand.includes('prj_MOy0bFQpENg7reA6VmEDZ61Fx5Uj')]
]);

let failed = false;
for (const [name, ok] of checks) {
  console.log(`${ok ? 'PASS' : 'FAIL'} ${name}`);
  if (!ok) failed = true;
}
if (failed) process.exit(1);

function walkJs(dir) {
  const out = [];
  for (const name of readdirSync(dir)) {
    const full = join(dir, name);
    if (statSync(full).isDirectory()) out.push(...walkJs(full));
    else if (name.endsWith('.js')) out.push(full);
  }
  return out;
}

for (const file of walkJs(join(root, 'js')).sort()) {
  execFileSync(process.execPath, ['--check', file], { stdio: 'inherit' });
  console.log(`PASS syntax ${file.slice(root.length + 1)}`);
}

const inlineScripts = [...index.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/gi)]
  .map(match => match[1])
  .filter(body => body.trim());
if (inlineScripts.length < 2) {
  throw new Error(`Expected at least 2 executable inline scripts, got ${inlineScripts.length}`);
}

const temp = mkdtempSync(join(tmpdir(), 'my-camp-inline-'));
inlineScripts.forEach((body, i) => {
  const file = join(temp, `inline-${i + 1}.js`);
  writeFileSync(file, body, 'utf8');
  execFileSync(process.execPath, ['--check', file], { stdio: 'inherit' });
  console.log(`PASS inline syntax ${i + 1}`);
});

console.log('STATIC QA PASS');

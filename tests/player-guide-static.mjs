import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { STAGE6_QUEST_HINTS, questHintFor } from '../js/ui/player-guide.js';

assert.equal(STAGE6_QUEST_HINTS.length, 9, 'Stage 6 should guide the compact early-game onboarding sequence only');
assert.match(questHintFor('Сдай на склад 30 🌲'), /деревьям/i);
assert.match(questHintFor('Построй ЛЕСОПИЛКУ'), /строительной площадке/i);
assert.match(questHintFor('Найми 2 крестьян'), /панели отряда/i);
assert.equal(questHintFor('Победи 25 орков'), '', 'late-game quests must not keep the onboarding coach visible');

const main = await readFile(new URL('../js/main.js', import.meta.url), 'utf8');
assert.match(main, /createPlayerGuide/);
assert.match(main, /runtimeVersion:'20\.23\.0'/);
assert.match(main, /v20PlayerGuide='stage6-quest-coach-v1'/);
assert.match(main, /playerGuidance:'stage6-early-quest-coach'/);

console.log('Stage 6 player guidance static gate: PASS');

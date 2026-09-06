import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { STAGE7_ENCOUNTERS } from '../js/content/camp-encounters.js';
import { EVENT_TYPES } from '../js/systems/events.js';

assert.equal(STAGE7_ENCOUNTERS.length,4,'Stage 7 first content slice should contain four post-raid encounters');
assert.deepEqual(STAGE7_ENCOUNTERS.map(item=>item.wave),[1,2,3,4]);
assert.ok(STAGE7_ENCOUNTERS.every(item=>item.id&&item.title&&item.text&&item.choices.length===3));
assert.ok(STAGE7_ENCOUNTERS.some(item=>item.type===EVENT_TYPES.CACHE));
assert.ok(STAGE7_ENCOUNTERS.some(item=>item.type===EVENT_TYPES.HARVEST));
assert.ok(STAGE7_ENCOUNTERS.some(item=>item.type===EVENT_TYPES.MERCHANT));
assert.ok(STAGE7_ENCOUNTERS.some(item=>item.choices.some(option=>Number(option.rewards.gold)>0)));
assert.ok(STAGE7_ENCOUNTERS.some(item=>item.choices.some(option=>Number(option.rewards.pelts)>0)));

const [main,commands] = await Promise.all([
  readFile(new URL('../js/main.js',import.meta.url),'utf8'),
  readFile(new URL('../js/core/command-registry.js',import.meta.url),'utf8')
]);
assert.match(main,/runtimeVersion:'20\.24\.0'/);
assert.match(main,/createCampEncounters/);
assert.match(main,/v20WorldEvents='stage7-encounters-v1'/);
assert.match(main,/worldEvents:'stage7-post-raid-encounters'/);
assert.match(commands,/world\.event\.resolve/);
assert.match(commands,/applyResourceDelta/);

console.log('Stage 7 world encounters static gate: PASS');

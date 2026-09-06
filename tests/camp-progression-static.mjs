import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { CAMP_TIERS, campTierFor, formatCampProgress } from '../js/content/camp-progression.js';

assert.equal(CAMP_TIERS.length,5);
assert.deepEqual(CAMP_TIERS.map(tier=>tier.minBuildings),[0,3,6,10,14]);
assert.deepEqual(CAMP_TIERS.map(tier=>tier.name),['СТОЯНКА','ЛАГЕРЬ','ПОСЕЛЕНИЕ','КРЕПОСТЬ','ЦИТАДЕЛЬ']);
assert.equal(campTierFor(0).id,'camp-site');
assert.equal(campTierFor(2).id,'camp-site');
assert.equal(campTierFor(3).id,'camp');
assert.equal(campTierFor(6).id,'settlement');
assert.equal(campTierFor(10).id,'fortress');
assert.equal(campTierFor(14).id,'citadel');
assert.equal(campTierFor(17).id,'citadel');
assert.match(formatCampProgress(6,17),/ПОСЕЛЕНИЕ/);
assert.match(formatCampProgress(6,17),/6\/17/);

const [main,progression] = await Promise.all([
  readFile(new URL('../js/main.js',import.meta.url),'utf8'),
  readFile(new URL('../js/content/camp-progression.js',import.meta.url),'utf8')
]);
assert.match(main,/runtimeVersion:'20\.25\.0'/);
assert.match(main,/createCampProgression/);
assert.match(main,/v20CampProgression='stage7-tiers-v1'/);
assert.match(main,/campProgression:'stage7-five-tiers'/);
assert.doesNotMatch(progression,/localStorage/,'camp tiers must remain derived from the existing save, not create a second progression save');
assert.doesNotMatch(progression,/commands\./,'camp tier display must not mutate gameplay through commands');
assert.doesNotMatch(progression,/migration\./,'camp tier display must not mutate the legacy simulation');

console.log('Stage 7 camp progression static gate: PASS');

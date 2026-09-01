// V20 Foundation: raid phases are explicit so UI, combat and audio can subscribe later.
export const RAID_PHASES = Object.freeze({DAY:'day', WARNING:'warning', NIGHT:'night', RESOLUTION:'resolution'});

export function getRaidPhase(secondsToRaid, nightActive) {
  if (nightActive) return RAID_PHASES.NIGHT;
  if (secondsToRaid <= 15) return RAID_PHASES.WARNING;
  return RAID_PHASES.DAY;
}

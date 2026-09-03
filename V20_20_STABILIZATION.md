# V20.20 Stabilization

Stage 1 stabilization baseline.

## Fixed
- Adaptive HUD controller executes inside a script tag.
- Agent panel CSS is loaded by HTML rather than imported as JavaScript.
- Agent panel is created before the public API object is frozen.
- Runtime stabilization version is 20.20.
- First night remains at 180 seconds; subsequent night starts are every 90 seconds (60s day + 30s night).
- Metropolis achievement/quest uses BUILDINGS.length instead of a hard-coded 16.
- Legacy manual fishing path was removed; automatic fishing is the single player fishing path.
- Night-wave marker is persisted to prevent a duplicate wave after reload during night.

## Gate
The workflow validates all JS syntax, inline script syntax, V20 boot ordering, HUD script placement, timing constants, dynamic building completion, fishing path removal, save/load night marker, and hunter button affordability/disabled logic before committing.

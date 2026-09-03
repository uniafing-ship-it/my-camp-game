# Stage 4 — V20 Domain Migration

Version: 20.21.0

## Goal

Move the public/canonical game state and command boundary from ad-hoc read-only legacy mirrors to one V20 DomainAuthority without changing gameplay timings or balance.

## Canonical V20 domains

- resources
- buildings
- production
- villagers/workers
- combat
- world
- save
- UI

`js/core/domain-authority.js` is the single publisher for those canonical domain snapshots. Every commit records a revision, source and update timestamp under `meta.authority`.

## Resource write boundary

V20 resource writes no longer mutate `window.MyCampLegacy.storage` directly. `js/systems/resources.js` writes through `js/core/migration-bridge.js`, then immediately republishes the canonical resources snapshot with source `v20-command`.

Gameplay spending is still executed by the existing inline simulation while that simulation remains authoritative for low-level mechanics. Command adapters refresh affected V20 domains immediately after the legacy mutation returns.

## Projection changes

- removed duplicate resources/villagers/buildings writers from `state-sync`;
- stabilized generated villager IDs;
- fixed legacy building level projection (`lvl` -> canonical `level`);
- added hired workers to the villagers/workers domain;
- changed world projection to a lightweight canonical summary instead of retaining full legacy entity arrays;
- initialized every Stage 4 domain before `window.MyCampGame` is exposed.

## QA

Stage 4 extends browser QA with a convergence scenario. It verifies that canonical V20 snapshots match the active legacy simulation driver for resources, buildings, workers, combat counts and world summary. Resource seeding in QA now uses the V20 resource service instead of direct legacy storage mutation.

## Explicit remaining legacy authority

Stage 4 does **not** claim that the 200 KB inline simulation has been physically removed. The following remain in the inline legacy engine for now:

- frame/tick simulation;
- movement and gathering internals;
- building construction/upgrade internals;
- unit spawning and combat internals;
- day/night and wave simulation;
- detailed world entities;
- canvas rendering;
- legacy save payload used by the live game;
- keyboard paths that still call legacy gameplay functions directly;
- compatibility DOM replay for commands not yet exported by the legacy boundary.

These components now sit behind or alongside the V20 canonical state/command boundary and can be extracted incrementally in later work without changing the public V20 API.

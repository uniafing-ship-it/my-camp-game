# V20 Foundation

The legacy game remains the gameplay source of truth during the migration.

- `core/` — state, runtime, event bus and loop infrastructure.
- `systems/` — domain boundaries introduced incrementally.
- `ui/` — presentation boundaries.
- `render/` — canvas/rendering boundaries.
- `world/` — world model boundaries.
- `save/` — save versioning and migrations.
- `legacy/` — original inline game scripts extracted without behavior changes.

New gameplay systems should depend on these boundaries rather than adding more code to `index.html`.

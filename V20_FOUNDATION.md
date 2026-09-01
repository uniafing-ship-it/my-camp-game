# V20 Foundation

This release moves the game toward a modular architecture without changing gameplay behavior.

## Migration rules
- `index.html` is the shell.
- Inline CSS is migrated to `css/game.css`.
- Inline gameplay scripts are preserved under `js/legacy/`.
- New systems use `js/core`, `js/systems`, `js/ui`, `js/render`, `js/world`, and `js/save`.
- The legacy runtime remains authoritative until each domain is migrated and verified.
- Save schema changes are versioned.

## Verification gate
Do not remove the legacy layer until production smoke tests pass for launch, build, upgrade, raid, save/load, mobile controls, and night timing.

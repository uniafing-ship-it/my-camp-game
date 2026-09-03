# Stage 5 — Strategic Agent (V20.22)

## Goal

Turn the existing observation/resource-order agent into a bounded strategic camp manager without bypassing gameplay rules.

## Architecture

- Agent reads migrated state from `DomainAuthority`.
- Compatibility reads are limited to unmigrated facts: current worker order, contextual build/upgrade availability, research ownership and expedition busy state.
- All mutations go through `CommandBus`.
- The agent never writes `MyCampLegacy` state directly.
- Autopilot stays disabled by default.

## Autonomous actions

- rebalance worker resource orders;
- hire workers;
- hire foot soldiers, hunters and dogs when unlocked and affordable;
- execute context-available build/upgrade actions;
- purchase research through the compatibility command boundary;
- launch expeditions when enough idle units are available;
- preserve resources through action-aware reserves;
- prepare defense before night;
- stop strategic spending during active combat/night.

## Non-cheating boundary

The strategic agent does not teleport the hero, edit resources, spawn units directly or bypass placement/proximity rules. Build/upgrade actions are considered only when the normal game UI reports that the action is currently available.

## Safety

`Autopilot` is disabled by default. A manual `step()` executes exactly one safe strategic action. Recovery actions such as `workers.order` are allowed even when resources are below reserve; spending actions are reserve-checked.

## QA acceptance

Stage 5 must pass the existing Stage 3/4 regression gate plus dedicated tests for:

1. DomainAuthority state consumption;
2. safe one-step workforce growth;
3. zero-resource recovery without reserve deadlock;
4. research via CommandBus;
5. expedition deployment via CommandBus;
6. no direct agent access to `MyCampLegacy`.

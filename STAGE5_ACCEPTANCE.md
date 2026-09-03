# Stage 5 acceptance

Stage 5 is complete only when all of the following are true:

- V20 strategic agent reads migrated state from DomainAuthority.
- No agent/planner/autopilot module accesses `MyCampLegacy` directly.
- Decision engine can select more than `workers.order`.
- Autopilot remains disabled by default.
- Manual `autopilot.step()` executes exactly one safety-checked action.
- Low-resource recovery is allowed below spending reserves.
- Research and expeditions cross CommandBus compatibility adapters.
- Existing gameplay regression tests remain green.
- Dedicated strategic-agent browser tests are green with retries disabled.
- Protected PR QA is green before merge.
- Post-merge QA is green on the exact `main` SHA deployed to Vercel production.

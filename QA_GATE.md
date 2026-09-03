# Stage 3 QA Gate

This repository has a release-blocking QA workflow in `.github/workflows/qa-gate.yml`.

## What is checked

### Static gate
- critical V20.20 stabilization invariants;
- duplicate Vercel project guard;
- syntax of every module under `js/`;
- syntax of executable inline scripts in `index.html`.

### Chromium smoke gate
- real browser boot without uncaught JavaScript errors;
- `window.MyCampLegacy` and frozen `window.MyCampGame` availability;
- V20 runtime, command bus, agent, decision engine, autopilot and agent panel boot;
- gameplay command bindings;
- adaptive HUD mode and top-row collision check on phone, plus desktop reflow;
- hunter button disabled/enabled state based on affordability;
- actual hunter hire through the V20 command-routing boundary;
- worker-order command routing;
- save persistence;
- first night starts at 180 game seconds;
- next night/wave starts 90 game seconds later;
- reload during night does not spawn a duplicate wave.

## Run locally

```bash
npm install
npx playwright install chromium
npm run qa
```

A pull request to `main` and every push to `main` run the same gate automatically.

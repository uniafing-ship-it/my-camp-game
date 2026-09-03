# Release contour

## Canonical production path

- Source repository: `uniafing-ship-it/my-camp-game`
- Release branch: `main`
- Canonical Vercel project: `my-camp-game`
- Canonical Vercel project ID: `prj_97nTI8zSr99gcp2TXnth0QbSvrsS`
- Production domain: `https://my-camp-game.vercel.app`

A release is considered current only when the GitHub `main` commit SHA equals the `githubCommitSha` of the latest READY production deployment of the canonical Vercel project.

## Duplicate deployment protection

`my-camp-game-zjx4` is a legacy duplicate Vercel project still linked to the same GitHub repository. `vercel.json` uses `ignoreCommand` and `VERCEL_PROJECT_ID` to skip Git deployments for that project while allowing the canonical project to build.

Legacy Vercel projects `my-camp-game-mobile` and `my-camp-game-mobile-hud-fix` are not linked to GitHub and are not part of the release path.

## Release rule

Do not treat preview deployments or deployments from legacy Vercel projects as production. The only production source of truth is:

`GitHub main -> Vercel my-camp-game -> my-camp-game.vercel.app`

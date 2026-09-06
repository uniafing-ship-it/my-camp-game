# My Camp Game — Godot 4 migration

This directory is the new engine foundation for **My Camp Game**. The existing HTML/Canvas build remains untouched while migration work is isolated in `migration/godot-4`.

## Stage 1 scope

- Godot 4 project foundation.
- Real 3D scene and perspective camera.
- CharacterBody3D player controller.
- Mobile virtual joystick.
- Touch / mouse camera rotation.
- Procedural 3D test terrain, forest, rocks, pond and camp prototype.
- Directional lighting, shadows, fog, animated water and camp fire light.
- Compatibility renderer selected for future Web/mobile export.

## Not migrated yet

Gameplay systems from the production HTML build are intentionally not copied during Stage 1: resources, harvesting, fishing logic, workers, buildings, combat, waves, research, quests, progression and saves remain in the legacy build until their dedicated migration stages.

## Controls

Desktop: WASD / arrow keys to move, Shift to sprint, hold right mouse button and move mouse to rotate the camera.

Mobile: left virtual joystick to move; drag the right side of the screen to rotate the camera.

## Project separation

This is **My Camp Game** only. It is independent from the separate Witcher/action-RPG project.

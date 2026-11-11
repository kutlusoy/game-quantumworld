# Quantum World

Android game built with Godot 4.3: a 3D anime-style open-world platformer for phones. Design documents are in `docs/`; start with `docs/PLAN.md` and `docs/GAMEPLAY-3D.md`. Engine choice and the AI-assisted asset pipeline are in `docs/ASSET-PIPELINE.md`; the avatar look is in `docs/ART-DIRECTION.md`.

## Status

The 3D prototype is the main scene:

- **World:** a smooth, seed-generated island (deterministic integer heightfield with rolling hills, cliffs, a beach and sea), a parkour tower, crystal islands that need a dash, ruins with shards, trees and 51 collectible shards.
- **Controller:** deterministic third-person movement (run, jump, double jump, dash, glide) with slope rules, coyote time and jump buffering, fixed 60 Hz and integer math.
- **Challenges and progression:** three challenges (Tower Climb, Crystal Leap, Ruin Run) with Gold, Silver and Bronze tiers, avatar XP and levels (saved locally), shard XP once per shard.
- **Avatars:** five original, procedurally generated anime characters (three female, two male, ages 20 to 27) with an articulated skeleton, human-looking hands, natural proportions, outfit variants (crop top, tank, shorts, jackets), friendly or neutral expressions and celebration animations that play only for achievements (or on demand with G). `scenes/avatar_lineup.tscn` shows all five.
- **Phone:** landscape layout and touch controls (stick, camera drag, JUMP, DASH, HAPPY).

The earlier match-3 prototype (core logic, 20 levels, UI, tests) is kept as a possible in-world minigame. Its scene is `scenes/main.tscn`; its UI layout was built for portrait and is not adapted to the landscape project settings.

## Run

Open the project in Godot 4.3 (GL Compatibility renderer) and run it, or:

```
godot --path .
godot --path . scenes/avatar_lineup.tscn
```

Controls on desktop: WASD move, Space jump (press again in the air to double jump, press again after that and hold to glide), Shift dash, G celebrate, Q/E or mouse drag for the camera. On touch devices: left stick, right-side drag for the camera, JUMP, DASH and HAPPY buttons. Gamepad: left stick, A jump, X dash, right stick camera.

## Tests

```
godot --headless --path . --import
godot --headless --path . -s tests/test_controller3d.gd
godot --headless --path . -s tests/test_challenges.gd
godot --headless --path . -s tests/world3d_smoke.gd
godot --headless --path . -s tests/avatar_smoke.gd
godot --headless --path . -s tests/run_tests.gd
godot --headless --path . -s tests/ui_smoke.gd
```

The challenge tests drive the controller with simple bots to prove that the tower, the dash gaps and the ruin run are completable and that the dash gap really needs a dash. If the physics constants change, re-check the par times in `scripts/core3d/challenge.gd`.

## Layout

- `scripts/core3d/`: deterministic simulation without scene dependency (terrain world, player controller, challenges, progress, replay)
- `scripts/world3d/`: rendering and input for the 3D scene (terrain mesher, procedural anime avatar, mesh kit, touch controls, game scene, avatar lineup)
- `shaders/`: toon terrain shader, character toon shader, hair, anime eye and outline shaders
- `scripts/core/`, `scripts/ui/`, `levels/`: match-3 prototype
- `tests/`: headless logic and smoke tests
- `docs/`: design documents

## Determinism

The controller uses integer fixed-point math (1024 sub-units per block) and a fixed 60 Hz tick. The terrain is an integer heightfield with a fixed triangulation, so ground height queries are exact and match the rendered mesh; set pieces use axis-aligned boxes. A world seed plus a list of per-tick inputs `[move_x, move_z, buttons]` fully determines the result, so replays give identical outcomes on every device. This is the basis for verifying claims later (`docs/CHAIN-DESIGN.md`, `docs/GAMEPLAY-3D.md`).

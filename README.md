# Quantum World

Android game built with Godot 4.3: a 3D anime-style open-world platformer. Design documents are in `docs/`; start with `docs/PLAN.md` and `docs/GAMEPLAY-3D.md`. Engine choice and the AI-assisted asset pipeline are in `docs/ASSET-PIPELINE.md`; the avatar look is in `docs/ART-DIRECTION.md`.

## Status

The 3D controller prototype is the main scene: a seeded voxel island (to be replaced by smooth terrain) with a deterministic third-person character controller (run, jump, double jump, dash, glide), a parkour tower, a dash chain, ruins with a secret, 51 collectible shards, touch controls and a landscape layout.

Avatars are generated in code from original presets (`scripts/world3d/avatar_presets.gd`): slim anime proportions, layered hair, shader-based anime eyes, toon shading with outline, about 4,800 triangles each. They are a generator-based first pass for style exploration and not the final art. `scenes/avatar_lineup.tscn` shows all five characters.

The earlier match-3 prototype (core logic, 20 levels, UI, tests) is kept as a possible in-world minigame. Its scene is `scenes/main.tscn`; its UI layout was built for portrait and is not adapted to the landscape project settings.

## Run

Open the project in Godot 4.3 (GL Compatibility renderer) and run it, or:

```
godot --path .
godot --path . scenes/avatar_lineup.tscn
```

Controls on desktop: WASD move, Space jump (press again in the air to double jump, press again after that and hold to glide), Shift dash, Q/E or mouse drag for the camera. On touch devices: left stick, right-side drag for the camera, JUMP and DASH buttons. Gamepad: left stick, A jump, X dash, right stick camera.

## Tests

```
godot --headless --path . --import
godot --headless --path . -s tests/test_controller3d.gd
godot --headless --path . -s tests/world3d_smoke.gd
godot --headless --path . -s tests/avatar_smoke.gd
godot --headless --path . -s tests/run_tests.gd
godot --headless --path . -s tests/ui_smoke.gd
```

## Layout

- `scripts/core3d/`: deterministic simulation without scene dependency (voxel world generation, player controller, replay)
- `scripts/world3d/`: rendering and input for the 3D scene (chunk mesher, procedural anime avatar, mesh kit, touch controls, game scene, avatar lineup)
- `shaders/`: toon terrain shader, character toon shader, hair, anime eye and outline shaders
- `scripts/core/`, `scripts/ui/`, `levels/`: match-3 prototype
- `tests/`: headless logic and smoke tests
- `docs/`: design documents

## Determinism

The controller uses integer fixed-point math (1024 sub-units per block) and a fixed 60 Hz tick, and world generation uses only integer arithmetic. A world seed plus a list of per-tick inputs `[move_x, move_z, buttons]` fully determines the result, so replays give identical outcomes on every device. This is the basis for verifying claims later (`docs/CHAIN-DESIGN.md`, `docs/GAMEPLAY-3D.md`).

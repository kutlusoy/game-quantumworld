# Quantum World

Android game built with Godot 4.3: a 3D anime-style open-world platformer with block-based building. Design documents are in `docs/`; start with `docs/PLAN.md` and `docs/GAMEPLAY-3D.md`.

## Status

The project direction changed from match-3 to a 3D open-world adventure. The repository currently contains the finished match-3 prototype (core logic, 20 levels, UI, tests), kept as a possible in-world minigame. The 3D vertical slice is the next phase.

## Run

Open the project in Godot 4.3 (GL Compatibility renderer) and run the main scene, or:

```
godot --path .
```

## Tests

```
godot --headless --path . --import
godot --headless --path . -s tests/run_tests.gd
godot --headless --path . -s tests/ui_smoke.gd
```

## Layout

- `scripts/core/`: match-3 logic without any scene dependency (board, level, session, replay, deterministic RNG)
- `scripts/ui/`: match-3 views and screens
- `levels/levels.json`: match-3 level definitions
- `tests/`: headless logic and UI smoke tests
- `docs/`: design documents

## Determinism

A level plus its move list fully determines the result. `scripts/core/rng.gd` is a self-contained xorshift generator so replays give identical results on every device and engine version. The 3D game follows the same principle with a deterministic character controller (`docs/GAMEPLAY-3D.md`).

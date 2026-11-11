# Quantum World

Android match-3 puzzle game built with Godot 4.3. Design documents are in `docs/`.

## Status

Phase 1 vertical slice: match-3 core, special pieces, 20 levels, level select, local save data. Everything runs offline.

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

- `scripts/core/`: game logic without any scene dependency (board, level, session, replay, deterministic RNG)
- `scripts/ui/`: views and screens
- `levels/levels.json`: level definitions (seed, size, colors, moves, target score)
- `tests/`: headless logic and UI smoke tests

## Determinism

A level plus its move list fully determines the result. `scripts/core/rng.gd` is a self-contained xorshift generator so replays give identical boards on every device and engine version. `scripts/core/replay.gd` verifies a move list and returns score, stars and a board fingerprint.

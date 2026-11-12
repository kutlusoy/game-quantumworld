# Quantum World: Hubs, Buildings and Escape Rooms (Draft v0.1)

This document extends `GAMEPLAY-3D.md`. The open island stays as the movement playground; the new core is a **city hub with enterable buildings**, each building holding **closed escape-room instances**. Real places come from open map data, stylized into the anime look.

## 1. Structure

- **Hub (open):** a stylized district of a real city. Smooth terrain, streets, parks, landmarks, other players as a ghost crowd, shops, crews. Short outdoor challenges (jump, collect, parkour) stay here.
- **Building (portal):** a door, tram stop, lift or manhole in the hub leads into a building. Entering is a scene transition with a short fade; the hub is paused, not unloaded on phones with enough memory.
- **Rooms (closed):** a building is a graph of rooms connected by doors, stairs, lifts, vents, windows or teleporters. A room is small (about 12 x 12 blocks), so it loads fast and renders cheaply on a phone.
- **Escape logic:** a room or building is a puzzle with a goal (open the exit, reach the roof, recover an item). Solving gives XP, Quanta, cosmetics and a tier (Bronze, Silver, Gold by time and hints used).
- **Links:** an exit can lead to another building, to another city (teleport gate) or back to the hub. This is how worlds, countries and cities connect (see `PLAN.md`).

## 2. Escape logic (no physics puzzles)

Puzzles are state machines, not physics. This keeps them deterministic, testable and easy on touch.

Primitives:

- **Key and lock:** item, door, colored lock.
- **Switch and plate:** lever, button, pressure plate, timed button.
- **Code:** numeric or symbol keypad, clues hidden in the room (posters, clocks, books).
- **Sequence:** light or sound order, symbol order, memory pattern.
- **Inventory use:** combine two items, use an item on an object.
- **Light and mirror:** rotate mirrors to hit a target (logic, not physics simulation: fixed angles).
- **Movement gates:** parts that need the avatar skills (double jump, dash, glide) to reach a spot. This ties the platformer controller to the puzzles.
- **Co-op:** two or more players must act in different rooms at once (one holds a plate, the other passes). Optional, never required for solo rooms.

Each room is data: `{objects, states, rules, goal}` with rules like `when lever_a and lever_b then door_1.open`. A small rule engine evaluates them each tick. The same engine runs on every device from the same inputs, so replays can be verified like the platformer runs.

Hints cost points, not progress: a hint reveals one step and lowers the tier. Rooms must always be completable without hints and without any network.

## 3. Real places from open data

Preferred sources and licenses (check each before use, record in the provenance list):

| Data | Source | License | Use |
|---|---|---|---|
| Streets, buildings, parks, water, landmarks | OpenStreetMap | ODbL (attribution, share-alike for the database) | Hub layout and building footprints |
| Buildings and places (alternative) | Overture Maps | CDLA / ODbL mix per theme | Backup source |
| Terrain height | Copernicus DEM, SRTM, national open DEMs | Open (attribution) | Hub ground |
| 3D models, textures | CC0 packs, own generator | CC0 or own | Props, facades |

Rules:

1. **Stylize, never reproduce photos.** Satellite imagery, street photos and commercial map tiles are not used. Facades are generated from building type, height and a seed, with anime-style textures.
2. **Pinned snapshots.** Each hub is a fixed data snapshot (source extract, date, hash) baked into a chunk pack. The generator must give the same result for the same snapshot so replays and shared leaderboards stay valid.
3. **Attribution and ODbL.** Credits screen lists OpenStreetMap contributors. The baked map data derived from OSM is published as an open data file next to the game (share-alike), while code and art stay proprietary. A short legal check is needed before launch.
4. **Safety and privacy.** No private homes as enterable places, no schools, no sensitive or secure sites, no real-person names on buildings. Real landmarks are shown only as stylized shapes. Players never get real-world location tracking; the hub is a fixed place, not tied to the player's position.
5. **Content rating.** Keep PEGI 12 / ESRB Teen. No violence-themed real locations.

## 4. How it fits the existing code

| Existing piece | Use in the new structure |
|---|---|
| Heightfield terrain, integer determinism | Hub ground from a DEM snapshot |
| Axis-aligned boxes (`add_box`) | Room walls, floors, furniture, doors |
| Player controller (run, jump, double jump, dash, glide) | Same controller in rooms; movement gates |
| Challenge tracker | Generalize into the room goal and tier tracker |
| Progress and save store | XP, solved rooms, best tiers |
| Replay and fingerprints | Verified escape times for leaderboards and rewards |
| Avatar and editor | Unchanged; outfit parts can be room rewards |

New pieces: a **portal/scene manager** (hub, building, room transitions with fixed spawn points), a **room data format** and **rule engine**, a **map baker** (offline tool that turns an OSM and DEM extract into a chunk pack), and **interaction UI** (touch to use, inventory strip, code pad).

## 5. Phone rules

- Rooms stay small and the hub streams in chunks; target 60 fps on a mid-range phone.
- One main action button plus context interaction ("Use" appears near objects); no precise drag puzzles.
- Landscape, two thumbs, as before. Text in puzzles is short, with icons, so it works across languages.
- Everything solvable offline. Online adds co-op rooms, crowds and leaderboards.

## 6. MMO-lite and network

- Hub: ghost crowd and crews as defined in `GAMEPLAY-3D.md`; no real-time PvP.
- Rooms: solo by default, co-op for 2 to 4 players with turn-friendly sync (state changes, not positions at high rate), which suits Tor/I2P latency.
- Time-attack leaderboard: submit the input log; verifiers replay it (the existing replay design).

## 7. First prototype plan

1. Core: room data format, rule engine, portal manager, tests with bots (headless), in `scripts/core3d/`.
2. One building with 3 rooms: a key, a code with a clue, a lever pair, a dash gate, exit to the hub. Tests prove it is solvable and that skipping a step is not.
3. A tiny hub district (hand-made first, not OSM) with the building door.
4. Map baker prototype for one open extract (a small neighborhood), to measure size and look. Decide on the data path only after seeing this.
5. UI pass for touch: interact button, inventory, code pad.

## 8. Open Questions

1. Which real city or district first? A small, recognizable, safe area works best for the first bake.
2. Are rooms hand-authored, procedural from templates, or both? Recommended: templates plus authored set pieces, with AI-assisted variants and a human review.
3. Is the open island kept as a separate tutorial and parkour area? Recommended: yes.
4. Legal review of ODbL share-alike for the baked map data before any release.
5. Budget for a level designer for the first authored buildings.

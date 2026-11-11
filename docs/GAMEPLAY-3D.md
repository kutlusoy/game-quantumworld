# Quantum World: 3D Open-World Direction (Draft v0.1)

This document replaces the match-3 core described in earlier versions of `PLAN.md`. The match-3 prototype stays in the repository as a possible in-world minigame (see section 9). Network, ledger, shop and offline documents remain valid; section 8 lists what changes in them.

## 1. Direction

Quantum World becomes a **3D third-person open-world adventure**: run, jump, glide, collect, explore, build. Think Mario-style movement and collecting combined with Minecraft-style blocky worlds and building, with **attractive anime-style avatars** and a style that appeals to teenagers and adults, not a toddler look. No physics puzzles.

## 2. Pillars

1. **Movement is the fun.** Tight, juicy platforming: run, jump, double jump, dash, glide, wall slide. It must feel good within the first 30 seconds.
2. **Explore and collect.** Shards, secrets, hidden areas, new worlds. Curiosity is the progression.
3. **Build and shape.** Block-based building in your own world.
4. **Style and identity.** Good-looking anime avatars and fashion as self-expression and progression.
5. **No physics puzzles.** Movement is kinematic and predictable; challenges are about timing, routes and exploration.
6. **Social, but latency-tolerant** (Tor/I2P, see section 6).
7. **Anonymous, decentralized, offline-capable** as before.

## 3. Art and Tone

- **Look:** stylized cel-shaded anime, clean outlines, expressive faces, 7 to 8 head proportions, a stylish and slightly mature adventure tone. Bright, saturated daytime worlds and moody neon night worlds. Sakura forests, crystal canyons, floating ruins, neon cities, deep ocean.
- **Avatars:** cool and attractive, not childish. Outfits: streetwear, techwear, fantasy armor, casual wear, accessories, auras, hair and eye styles, animation sets.
- **Hard content rules (not obscene):** all avatars and items are fully clothed, no sexualized outfits, poses or body options, no nudity, no exaggerated body features. This is enforced in the avatar kit itself (only approved parts exist) and in shop review. The audience starts at age 12; target rating PEGI 12 / ESRB Teen or lower. Violence is minimal: no blood, enemies bounce away or dissolve.
- **Music:** anime-style: energetic synth and rock for action, orchestral and lo-fi for calm exploration, adaptive layers. Original or commissioned only; no existing anime songs.
- **Avoid copying** existing characters or games. Build an own look.

## 4. World Structure

- **Universe -> worlds -> regions -> settlements.** Each world is generated from a **seed**; all clients generate identical terrain, so only differences (edits) need storing.
- **Terrain:** blocky voxel look with bevels, vertex ambient occlusion and toon shading, so it reads as stylish rather than a plain Minecraft clone.
- **Hand-made set pieces** (parkour towers, ruins, shrines, mini dungeons, secret chambers) are placed by the seed into the generated terrain. This avoids a generic procedural feel.
- **Nexus:** the social hub in the sky, reached through portals.
- **Teleport network:** portals link worlds, the Nexus and friends' worlds (interconnected, as in the earlier plan).
- **Public worlds are not editable.** They are shared seeds; only each player's collected items and discoveries are personal. This avoids griefing, moderation load and storage growth.
- **Private home worlds are editable.** Each player builds in their own world; others can visit it. Edits are stored as compact deltas on the device and cached by peers.

## 5. Core Loop and Progression

**Loop (2 to 10 minutes per trip):** enter a world, traverse and platform, collect Quantum shards, find secrets and complete parkour set pieces, return, spend and build, teleport on.

**Abilities as progression (Metroidvania style):** double jump, dash, glide, wall run, grapple. New abilities open previously unreachable areas, so worlds feel connected and revisiting pays off.

**Quantum-themed mechanics** (no physics puzzles, only timing and routes):
- *Phase blocks* (superposition): blocks appear and disappear on a rhythm.
- *Entangled portals:* paired portals teleport you between two places.
- *Tunneling:* a dash passes through thin walls.
- *Collapse:* a ground pound breaks cracked blocks.
- *Observer platforms:* exist only while you look at them.

**Hazards and enemies:** light and non-violent: glitch creatures to dodge, stomp or dash through, falling hazards, timed gates.

**Collectibles and events:** shards feed the Quanta event pools from `CHAIN-DESIGN.md`: daily fluctuation, discoveries (first finder of a secret), seasons, raids. See section 8.

## 6. Multiplayer Within Latency Limits

Tor and I2P give roughly 300 ms to 2 s round-trip time with jitter.

| Feature | Feasible over Tor/I2P? | Approach |
|---|---|---|
| See other players in the Nexus and worlds | Yes | Position updates at 2 to 5 Hz, interpolation, no collisions between players |
| Emotes, chat, parties of 2 to 4 | Yes | Visual presence only, no shared physics |
| Co-op events and raids | Yes | Shared progress counters, not shared real-time physics |
| Ghost races and time trials | Yes | Asynchronous: replay of a signed input recording |
| Real-time competitive play (PvP, race at the same moment) | No | Out of scope by default |

Optional later: an opt-in "fast mode" with direct low-latency connections for friends, with a clear warning that it exposes IP addresses. Not planned for v1.

## 7. Technology

- **Engine:** Godot 4.3, 3D. Mobile renderer (Vulkan) where supported, GL Compatibility as fallback. Toon shader with outline, simple dynamic lighting, baked or cheap shadows.
- **Rust core via GDExtension (godot-rust):** world generation and chunk meshing (greedy meshing, threaded), the deterministic character controller, and replay verification. The same crate `qw-core` runs in Keepers and servers (`SERVER.md`), so verification uses identical code.
- **Deterministic movement:** gameplay-critical movement uses a custom fixed-timestep kinematic controller with fixed-point or carefully controlled math, not Godot's physics engine. This makes input replays reproducible on any device.
- **Voxel budget on mid-range Android:** chunks of 16 x 16 x 64 or similar, view distance of about 6 to 8 chunks, LOD for far terrain, a strict draw-call budget. Target 30 fps minimum, 60 fps preferred.
- **Avatars:** glTF/VRM-style kit, under about 15k triangles per avatar, LOD or billboards beyond a distance, at most about 8 detailed avatars on screen. Only parameters travel over the network.
- **Controls:** left virtual stick, right-side camera drag, jump and dash buttons, assist features (coyote time, jump buffering, auto-step). Gamepad support.
- **Camera:** third-person orbit with collision handling.
- **Reuse from the existing prototype:** the xorshift RNG (`scripts/core/rng.gd`) idea and the replay pattern, local save store, level/session structure for minigames.

## 8. Impact on the Other Documents

- `CHAIN-DESIGN.md` 6.3 (claim verification): claims become **input-recording replays** plus collectible/discovery references instead of match-3 move lists. Compact encoding is needed (run-length encoded input at a fixed tick rate, a few KB per minute). Collectible claims can also use plausibility checks (speed and distance bounds) for low-value rewards, with replay verification for high-value or first-finder rewards. Leaves such as `ClearBitmap` become `CollectedBitmap(pubkey, world, bitmap)`.
- `SUSTAINABILITY.md`: avatar fashion becomes the main shop category. This fits a teenage audience well. Rules stay: cosmetics and convenience only, no pay to win, no paid random boxes.
- `IDENTITY-SHOP.md`: avatar content rules in section 3 above apply to the shop catalogue; age and minors rules remain.
- `OFFLINE.md`: single-player worlds, private home worlds and building work offline; presence and events need the network.
- `SERVER.md`, `PLAN.md` section 4: unchanged except the latency table in section 6 above.

## 9. The Match-3 Prototype

The tested match-3 core (`scripts/core/`, `scenes/main.tscn`, 20 levels) stays in the repository. Options: an in-world "puzzle terminal" minigame in the Nexus that pays small shard rewards with deterministic replay claims, or removal later. No further work on it until the 3D slice proves itself.

## 10. Phase 1 (new): 3D Vertical Slice

Goal: prove that moving through the world and collecting feels good, and that the avatar style appeals to the target audience.

- Third-person controller: run, jump, double jump, dash, glide, coyote time, jump buffering, camera.
- One seeded voxel island, about 10 minutes of traversal, about 50 shards, 3 parkour set pieces, 1 secret.
- Basic block placing and breaking (or breaking only) to test the building feel.
- One anime avatar with toon shader, 3 outfits and basic animations (idle, run, jump, glide, emote).
- Mobile touch controls, HUD, day/night cycle, placeholder music.
- Android build tested on 2 to 3 real devices; measure frame rate, heat and battery.
- Soft test with teenagers: session length, shards collected, return rate.

Out of scope for the slice: networking, ledger, shop, accounts.

Estimate: 3 to 5 months for a small team with an artist. Alone, with free or purchased assets, expect longer. Art (avatars, animation, environment) is the largest cost.

## 11. Risks

| Risk | Mitigation |
|---|---|
| Scope: open world, voxel, avatars, multiplayer and chain together are very large | Strict slice first, public worlds non-editable, networking later |
| Art cost and quality (anime avatars, animations) | Commission an artist, use licensed or CC0 base assets, check licenses of tools like VRoid for commercial use |
| Mobile performance of voxels plus toon rendering | Rust meshing, LOD, strict budgets, early device tests |
| Deterministic replay of a platformer is harder than match-3 | Custom fixed-timestep controller from day one, shared `qw-core` |
| Latency over Tor/I2P | Loose-sync presence, async competition, no real-time PvP |
| Content and moderation (teen audience, avatars) | Closed avatar kit, fully clothed rule, emotes-first chat, rating review |
| Looking like a Minecraft clone | Own art direction, set pieces, abilities and quantum mechanics |
| Teenage retention | Movement feel, secrets, fashion progression, seasons |

## 12. Open Questions

1. Voxel blocks with bevels (recommended), or smooth terrain?
2. Third-person only, or also a first-person option?
3. How much action: pure platforming and collecting, or light combat too?
4. Do you accept asynchronous races and loose-sync presence instead of real-time multiplayer, with an optional later fast mode?
5. Art plan: commission an artist, use VRoid-style base assets, or both?
6. Minimum device spec to target?
7. Keep the match-3 prototype as a minigame, or drop it?
8. Public worlds non-editable and private worlds editable, as proposed?

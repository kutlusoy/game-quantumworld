# Quantum World: 3D Open-World Direction (Draft v0.2)

Changes against v0.1: no level list, progression through **avatar levels**; one large **open world with challenges**, MMO-like within the limits of a decentralized design; **smooth terrain** instead of blocks; **phone first**; more elegant avatars. The match-3 prototype stays in the repository as a possible minigame (section 11).

## 1. Direction

Quantum World is a **3D third-person open-world adventure for Android phones**: run, jump, glide, climb, explore, take on challenges, and grow your avatar's level. It feels like a small MMO (other players are visible in the world and in the Nexus, crews, shared world events), with **attractive anime-style avatars** and a style for teenagers and adults. No physics puzzles, no real-time PvP.

## 2. Pillars

1. **Phone first.** Every feature is designed for touch, short sessions, battery and heat limits (section 3).
2. **Movement is the fun.** Tight, juicy platforming: run, jump, double jump, dash, glide, wall slide. It must feel good within the first 30 seconds.
3. **Challenges everywhere.** The open world is full of short challenges (1 to 3 minutes) with Bronze, Silver and Gold tiers.
4. **Avatar growth.** The avatar levels up, unlocks abilities, regions and style options. Progress belongs to the avatar, not to a level list.
5. **Style and identity.** Elegant, attractive anime avatars and fashion as self-expression.
6. **Social, but latency-tolerant** over Tor/I2P (section 8).
7. **Anonymous, decentralized, offline-capable** as before.

## 3. Phone-First Rules

- **Landscape, two thumbs:** left stick, right-side camera drag, large jump and dash buttons, optional auto-run and assist features (coyote time, jump buffering, ledge assist, aim assist for gliding). Layout is customizable.
- **Short sessions:** a rewarding loop in 3 to 5 minutes. Challenge starts are visible and close together; fast travel through portals.
- **Performance budget (mid-range phone, for example a Snapdragon 7 class GPU):** 30 fps stable, 60 fps optional; visible geometry around 100k to 150k triangles; under about 150 draw calls; one main texture atlas per area; avatar up to about 15k triangles.
- **Adaptive quality:** resolution scale, view distance and effect level adjust automatically to temperature and frame time.
- **Battery and heat:** frame cap options, no constant full-load rendering, network layer active only when needed.
- **Download size:** base install under about 150 MB; regions and cosmetics are downloaded or generated on demand and cached.
- **Offline:** the whole overworld is playable offline (`OFFLINE.md`).
- **Readable UI:** big touch targets, safe areas for notches, colorblind-safe symbols.

## 4. Art and Tone

- **Look:** stylized cel-shaded anime, clean outlines, expressive faces, soft rim light, bright saturated days and moody neon nights. Sakura valleys, crystal canyons, floating ruins, neon cities, island chains, deep ocean.
- **Avatars:** elegant and attractive, not chubby or childish. Target proportions 7 to 8 heads, slim build, long legs, large expressive eyes, hair with strands and secondary motion, cloth and accessory motion. Outfits: streetwear, techwear, fantasy armor, casual wear, accessories, auras, hair and eye styles, animation sets.
- **Hard content rules (not obscene):** all avatars and items are fully clothed, no sexualized outfits, poses or body options, no nudity, no exaggerated body features. This is enforced in the avatar kit (only approved parts exist) and in shop review. The audience starts at age 12; target rating PEGI 12 / ESRB Teen or lower. Violence is minimal: no blood; glitch enemies dissolve.
- **Music:** anime style: energetic synth and rock for action, orchestral and lo-fi for exploration, adaptive layers. Original or commissioned only.
- **Avoid copying** existing characters or games.

## 5. The Open World

- **One shared overworld** (working name: Aurora Archipelago): a large, seed-generated world of smooth terrain: rolling hills, cliffs, rivers, islands connected by bridges, gliding routes and portals. Several overworlds (biome themes) can follow as the universe grows.
- **Regions** have a recommended avatar level and ability requirements, but no hard walls: a skilled player can reach early any place their abilities allow.
- **Hand-made set pieces** (towers, ruins, shrines, floating ring paths, caves) are placed by the seed into generated terrain.
- **Public overworld is static:** terrain and structures are identical for everyone; only personal progress and discoveries differ. This avoids griefing and keeps storage tiny.
- **Home islands:** each player has a private home island to decorate with placeable objects (furniture, plants, structures, music stations) and to invite visitors. Smooth terrain sculpting is limited to soft tools (raise, lower, flatten), stored as compact deltas.
- **Nexus:** the sky hub with portals, shop, crews and events.
- **Day and night, weather** are cosmetic and synchronized by chain time (epoch) so players see the same sky.

## 6. Avatar Level and Progression

- **Avatar level 1 to 50** (cap raised with seasons). XP comes from challenges, discoveries, events and exploration, with daily caps on repeatable sources.
- **What levels unlock:** abilities (for example wall run, grapple, air dash), access recommendations for regions, challenge tiers, emote and outfit slots, titles, a small number of ability-tree points.
- **Ability tree (3 branches):** Mobility (movement upgrades), Exploration (map, scanning, detection), Style (customization, animations). Choices are about playstyle, not raw power.
- **No pay to win:** levels and XP cannot be bought. Cosmetics and convenience are the only shop categories. There is no PvP, so levels never create unfair advantage over other players.
- **Public signal:** avatar level and titles are shown above avatars in the Nexus and the world.
- **Ledger:** `AvatarProgress(pubkey, xp_total, level, ability_mask)` as a leaf in `CHAIN-DESIGN.md`. XP is minted by verified claims under per-epoch caps.

## 7. Challenges

| Challenge | Description | Verification |
|---|---|---|
| **Parkour trial** | Start ring, route through platforms, finish ring, time tiers | Input replay |
| **Shard run** | Collect all shards on a route within a time limit | Input replay or plausibility check |
| **Glitch hunt** | Chase or dodge glitch creatures, no violence | Input replay |
| **Secret** | Hidden chamber or path, first finder gets a bonus | Replay for first-finder claims |
| **Ghost race** | Beat the recorded run of another player | Signed replay of the ghost |
| **Photo task** | Pose avatar at a spot with an emote | Position plausibility |
| **World event** | Co-op event with a shared progress counter over hours or days (for example a Glitch Titan whose nodes players activate) | Aggregated verified contributions |
| **Daily fluctuation** | Rotating modifiers and bonus spots chosen by chain randomness | Per daily rules |

Rewards: XP, shards (Quanta event pools), cosmetics, titles. Pools and anti-farming are in `CHAIN-DESIGN.md` section 6.

## 9a. Quantum Mechanics (themes, no physics puzzles)

- *Phase platforms* (superposition) appear and disappear on a rhythm.
- *Entangled portals* link two places.
- *Tunneling:* a dash passes through thin barriers.
- *Collapse:* a ground pound breaks cracked structures.
- *Observer platforms* exist only while looked at.

## 8. MMO-Like Multiplayer Within Decentralized Limits

A real MMO (server-authoritative, real-time, thousands of players, PvP) needs central servers with low latency and costs money. It conflicts with no servers, Tor/I2P (300 ms to 2 s round trip) and anonymity. The realistic target is **MMO-lite**:

| Feature | Approach |
|---|---|
| Seeing other players in the overworld and Nexus | Channels of about 30 to 50 visible players, interest management by distance, position updates at 2 to 5 Hz with interpolation, no player collisions |
| World feels populated | **Ghost crowd:** recorded runs of real players (signed replays) appear as translucent ghost avatars, plus NPCs; real players are shown opaque |
| Crews (guilds) | Groups with a signed member list, crew chat with emotes, crew challenges and crew home |
| Co-op world events | Shared progress counters, not shared real-time physics |
| Trading | Asynchronous trade offers, signed by both sides |
| Competition | Asynchronous: ghost races, leaderboards from signed replays |
| PvP, real-time races | Not planned |

Optional later: operator-run "fast realms" with lower latency through direct connections, with a clear warning that they expose IP addresses. Not part of v1.

## 9. Technology

- **Engine:** Godot 4.3, 3D. Mobile-first rendering path; toon shader with outline; cheap or baked shadows.
- **Smooth terrain without losing determinism:** the world is a **heightfield** defined by an integer-only noise function (as in the current prototype's world generator). Gameplay collision uses the same integer heightfield plus analytic primitives (boxes, cylinders, ramps) for set pieces, never mesh physics. Rendering uses chunked, LOD'd meshes generated from the same function, with normals and splat colors from slope and height. Terrain3D or similar Godot addons may be evaluated for rendering only; collision stays in our core.
- **Deterministic controller on a heightfield:** fixed 60 Hz tick, fixed-point math, slope rules (walkable under a threshold, slide above), ledge and step assist. Replays of per-tick inputs verify challenge claims (`CHAIN-DESIGN.md` 6.3).
- **Rust core via GDExtension:** heightfield sampling, chunk meshing, the controller and replay verification in the shared `qw-core` crate, also used by Keepers and servers.
- **Streaming:** chunks around the player are generated or loaded on demand; far terrain as low-detail impostors.
- **Avatars:** glTF/VRM-style closed kit on a few base rigs, toon shading with outline and rim light, hair and cloth secondary motion kept cheap (bone chains), LOD or billboards beyond a distance, parameters only over the network.
- **Controls:** see section 3.

## 10. Impact on the Other Documents

- `CHAIN-DESIGN.md`: new leaf `AvatarProgress`; claims are input replays plus challenge ids; XP and Quanta pools per epoch; `CollectedBitmap` per region.
- `SUSTAINABILITY.md`: avatar fashion remains the main shop category; the Quantum Pass has an XP-free cosmetic track (no XP selling).
- `IDENTITY-SHOP.md`: the avatar content rules in section 4 apply to the shop; age and minors rules remain.
- `OFFLINE.md`: overworld, challenges and home island work offline; presence and events need the network.
- `SERVER.md`, `PLAN.md` section 4: unchanged except the MMO-lite table above and channel sizes.

## 11. Prototype Status and Next Phase

- **Existing:** a voxel-based controller prototype with deterministic movement, tests and a placeholder avatar, plus the match-3 prototype. The deterministic simulation, replay, tests, touch controls and camera are reusable; the voxel ground model is replaced by the heightfield.
- **Phase 1 (new):**
  1. Heightfield overworld island with smooth terrain, slope rules and the controller adapted to it.
  2. Avatar proxy with elegant proportions as an interim, then a first real avatar from the asset pipeline (`ASSET-PIPELINE.md`).
  3. Challenge framework: start ring, timer, finish, tiers, ghost replay, rewards.
  4. Avatar XP and level HUD, first ability unlock.
  5. Android export and tests on 2 to 3 real phones: frame rate, heat, battery, touch feel.
  6. Soft test with teenagers.
- **Match-3:** stays as a possible Nexus puzzle terminal; no further work until the slice proves itself.

## 12. Risks

| Risk | Mitigation |
|---|---|
| Scope: open world, MMO feel, avatars, ledger | Strict slice, one island first, MMO-lite only, networking later |
| Phone performance of smooth open terrain | Budgets, LOD, streaming, adaptive quality, early device tests |
| Determinism with smooth terrain and slopes | Integer heightfield, analytic colliders only, shared core, replay tests |
| Art cost and quality (avatars, animation, environment) | Artist plus AI pipeline, base rigs, clear style bible |
| MMO expectations vs Tor latency | Communicate MMO-lite, ghost crowd, async competition |
| Teen audience, moderation | Closed avatar kit, emotes first, rating review, local block lists |
| XP farming and bots | Daily caps, replay verification, pro rata pools |
| Retention in an open world | Challenges everywhere, seasons, crews, daily events |

## 13. Open Questions

1. Landscape two-thumb layout as the default, or also a portrait one-hand mode?
2. Minimum device: for example 4 GB RAM and a Snapdragon 7 class phone?
3. Level cap and ability list for the first season?
4. Are crews and ghost crowd the right MMO-lite features, or what else should feel MMO-like?
5. How much terrain editing on home islands (soft tools only, or also objects and structures)?
6. Art plan: who builds the first real avatar and base rigs?
7. Keep the match-3 prototype as a minigame, or drop it?

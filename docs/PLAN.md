# Quantum World: Project Plan and Gameplay Sketch

Status: Draft v0.4

Related documents: `GAMEPLAY-3D.md` (3D direction, replaces match-3), `CHAIN-DESIGN.md` (ledger), `SUSTAINABILITY.md` (decisions and revenue model), `IDENTITY-SHOP.md` (shop, accounts, addresses), `SERVER.md` (optional server layer and bootstrap), `OFFLINE.md` (offline play).

## 1. Vision

A 3D anime-style open-world adventure for Android with real addiction potential: Mario-style running, jumping and collecting combined with Minecraft-style blocky worlds and building. Attractive anime avatars, an energetic anime soundtrack, a style for teenagers and adults (not childish, not obscene), many interconnected worlds, an anonymous decentralized lobby, and a personal "Quantum Universe" for every player (worlds, countries, cities, villages, teleportation). No physics puzzles.

**Design pillars**
1. **Movement is the fun**: run, jump, double jump, dash, glide. It must feel great from the first 30 seconds.
2. **Explore and collect**: shards, secrets, hidden areas, new worlds.
3. **Style and identity**: attractive anime avatars and fashion as progression.
4. **Anonymous by default**: no login, no email, no phone number. Tor and I2P run invisibly in the background; players never see or configure anything technical.
5. **Decentralized and offline-capable**: the game keeps working even if no server or network exists.
6. **My world**: progress becomes visible as a world of your own that you build.

## 2. Key Decisions (honestly assessed)

| Topic | Recommendation | Reasoning |
|---|---|---|
| Engine | **Godot 4** with a Rust core (GDExtension) | Open source, small APK, good 3D on mobile. Rust gives fast voxel meshing and a deterministic controller shared with Keepers and servers. |
| Core gameplay | **3D third-person open-world platformer with block-based building** | Matches the target audience and the avatar focus. See `GAMEPLAY-3D.md`. |
| Worlds | **Seed-generated voxel worlds plus hand-made set pieces** | Only edits need storing, which fits decentralized storage. |
| Identity | **Cryptographic key pair (Ed25519) on the device** | No account server. The identity is the key. Layered recovery in `IDENTITY-SHOP.md`. |
| Network | **libp2p-style P2P over Tor/I2P transports** | See section 4. Loose-sync presence, no real-time PvP. |
| Ledger | **Attested, pruned, non-PoW chain** | See `CHAIN-DESIGN.md`. |
| Servers | **Optional Rust servers, expected but never required** | See `SERVER.md`. |
| Data | **Local first** | Save data and world edits live on the device. |
| 3D avatars | **Closed modular kit (VRM/glTF parts), toon shaded** | Cheap to transmit (parameters only), enforces the content rules. |
| Business model | **Free to play, cosmetic monetization** | Avatar fashion is the main shop category. See section 5.7 and `SUSTAINABILITY.md`. |

**Reality checks**
- **Tor/I2P on Android** is feasible (Tor via `tor-android`/Arti, I2P via `i2pd` or the I2P Android library). However, **latency is 300 ms to 2 s**, so **real-time competitive multiplayer is out**. Seeing other players (low update rate, interpolation), co-op counters and asynchronous races work.
- **3D on mobile** is demanding: voxel meshing, toon shading and avatars need strict budgets (target 30 fps minimum) and early tests on real devices.
- **Scope** is the biggest risk: open world, building, avatars, multiplayer and ledger together are very large. Strict phases, single-player first.
- **Google Play** allows Tor usage, but apps embedding Tor/I2P need a clean privacy statement. Alternative distribution: F-Droid, direct APK.
- **Battery/data usage**: Tor/I2P in the background is expensive. Solution: the network layer starts and stops automatically, **active only in the lobby and during sync**, worlds themselves run offline. Android background limits (Doze, app standby) require a short-lived foreground service for sync.
- **Fully serverless** is hard for peer discovery, cheat protection and moderation. Solution: a **hybrid** (see 4.3) with replaceable bootstrap endpoints and optional servers but no central authority over game state.
- **Anonymous does not mean unmoderated**: the audience starts at age 12. Chat is emotes/stickers only by default, free text optional plus local block lists. Avatars are fully clothed and there are no sexualized items.

## 3. Architecture Overview

```
+---------------- Android App (Godot) ----------------+
| 3D world | Avatar kit | Audio | UI | Shop            |
+------------------------------------------------------+
| Rust core (GDExtension): worldgen, meshing,           |
| deterministic controller, replay verification         |
+------------------------------------------------------+
| Local save data (encrypted, world edits as deltas)    |
| Identity: Ed25519 key + layered recovery              |
+------------------------------------------------------+
| Ledger client (light client, ChainBackend)            |
+------------------------------------------------------+
| P2P layer (libp2p/gossip/DHT)                         |
|   Transports: Tor (onion services) | I2P              |
+------------------------------------------------------+
| Optional: bootstrap endpoints (clearnet, Tor, I2P),   |
| Keepers, Shop service (anyone can run the first two,  |
| no trust required)                                    |
+------------------------------------------------------+
```

## 4. Decentralized Network in Detail

### 4.1 Identity
- On first start: generate a key pair, pick a display name and create an avatar. **No registration, no login.** The first start works fully offline.
- Public key = player ID. Recovery is layered (automatic OS backup, QR phone transfer, rescue card, trusted people, optional recovery account); see `IDENTITY-SHOP.md` section 3.

### 4.2 Transport
- Every client publishes itself as a **Tor v3 onion service** and/or an **I2P destination**, with persistent keys and signed address records (see `IDENTITY-SHOP.md` section 2).
- **No user-facing transport settings.** An internal transport manager chooses automatically: it starts Tor and I2P in parallel, uses whichever connects first and keeps the other as a fallback. If both fail, the game stays fully playable offline and retries silently.
- **Peer-to-peer traffic between players never uses direct connections**, because that would expose IP addresses to other players. Exception: public bootstrap data and optional server services may use clearnet (HTTPS) as the fast path, as defined in `SERVER.md` section 3.2a.
- An advanced/developer option may exist in a hidden menu (for example "Tor/I2P only"), but is not part of the normal UI.

### 4.3 Discovery and Lobby without a Central Server
- **DHT (Kademlia)** to find lobbies and world instances by hash.
- **Gossip PubSub** per room for presence, emotes and chat.
- **Bootstrap list**: a hard-coded list of at least 5 endpoints (clearnet, Tor, I2P) from different operators, plus signed list updates (`SERVER.md` section 3.2). It is a starting hint and never an authority. If everything fails: invite links/QR codes between friends.
- Instance size: about 20 to 30 avatars in the Nexus (more is too much traffic over Tor), parties of 2 to 4 in worlds; multiple instances are created automatically.

### 4.4 Save Data and Anti-Cheat
- Solo progress and private worlds: local, cheating only affects the cheater.
- Shared features (leaderboards, ghost races, events, discoveries): **signed results plus input-recording replays**, verified by Keepers with the deterministic controller (`GAMEPLAY-3D.md` section 7). The ledger for shared state is specified in `CHAIN-DESIGN.md`.
- Leaderboards: top lists computed locally from signed results of peers ("gossip leaderboard"). Not tamper-proof, but sufficient for fun.

### 4.5 Data That Is Shared
Only: public key, name, avatar parameters (~200 bytes), position in the Nexus or a world, signed results, emotes. World terrain is never transferred because it is generated from a seed; only edits of visited home worlds are. **No** device IDs, no IP (thanks to Tor/I2P), no analytics.

### 4.6 Invisible Networking (UX rules)
- The words "Tor", "I2P", "onion", "DHT", "peer" and "node" never appear in the normal UI. Neutral wording is used instead, e.g. "Connecting to the Nexus".
- Startup: the network layer boots in the background (first connection can take 10 to 60 seconds) while the player is already playing. Nothing blocks on the network.
- Connection state is shown as one small, friendly icon (e.g. a glowing portal: closed, opening, open). No error dialogs, no technical messages.
- Network failures degrade gracefully: the Nexus shows "Nexus is far away, try again later" and offers NPC avatars; progress is never lost. Offline behavior is specified in `OFFLINE.md`.
- Data usage and battery: sync only on Wi-Fi by default, a single toggle "Save data" in the settings.
- Legal/store: the privacy policy and the store listing still describe the use of anonymizing networks in plain language, even though the in-game UI does not.

## 5. Gameplay Sketch

Full details are in `GAMEPLAY-3D.md`.

### 5.1 Core Loop (2 to 10 minutes per trip)
1. Enter a world through a portal.
2. Run, jump, dash and glide across blocky terrain and parkour set pieces.
3. Collect **Quantum shards**, find secrets, defeat or dodge light glitch enemies.
4. Earn **quantum energy** and event rewards; unlock new abilities.
5. Return to your home world to build, decorate and dress your avatar.
6. Teleport to the next world: "just one more trip".

### 5.2 World Structure
- **Universe -> worlds -> regions -> settlements.** Worlds are generated from seeds with hand-made set pieces placed in them.
- Portals connect worlds, the Nexus and friends' worlds; new abilities (double jump, dash, glide, wall run, grapple) unlock new routes.
- **Secret paths** and hidden worlds reward exploration.
- Public worlds are shared seeds and not editable; home worlds are private and editable.

### 5.3 The Personal Quantum Universe
- Every player owns a home world they build in, block by block, and a universe of worlds they unlock.
- Worlds have biomes (sakura forest, crystal canyon, floating ruins, neon city, ocean depths).
- **Visiting**: other players can visit home worlds via link or lobby portal (edits are loaded P2P, only if the owner is online or cached).
- **Quantum randomness**: a daily "fluctuation" (random event, rare items).

### 5.4 Lobby ("Nexus")
- A sky hub with portals. Avatars walk around (virtual stick, emote wheel), no collisions between players.
- Activities: ghost races, trading post, cooperative **raid events** (shared progress over days), photo spots, music jam, the **Shop**, optional puzzle terminals.
- Chat: **emotes/stickers** by default, free text optional.

### 5.5 Avatars
- 3D anime style (cel-shaded), attractive and stylish, 7 to 8 head proportions. Kit: body shape, hair, eyes, outfits, accessories, auras, animation sets.
- **Content rules:** fully clothed, no sexualized outfits, poses or body options; only approved parts exist in the kit.
- Unlockable through play (never pay to win), cosmetic premium items in the Shop, sharing = parameters only.

### 5.6 Addiction/Retention Mechanics (responsible)
- Dense micro rewards (shard chimes, particles, ability unlocks).
- Daily login reward, daily quests, weekly events, seasons with the Quantum Pass.
- **Near-miss moments** (a secret just out of reach, a ghost time narrowly missed).
- Visible collections (outfits, auras, emotes, music tracks).
- Social: Nexus presence, cooperative raids.
- **Ethics**: no paid random loot boxes, no dark patterns, optional break reminders (also important for store policies).

### 5.7 Monetization
Free to play. Revenue through cosmetics and convenience only; details, rules and the Shop service are in `SUSTAINABILITY.md` section 5 and `SERVER.md`.
- **Quanta** (earned by playing) is never sold.
- **Crystals** (premium shop credit) are sold in packs, not transferable, not convertible to money.
- **Quantum Pass**: seasonal free and premium reward track, cosmetics only. Avatar fashion is the main category.
- **Limited drops, bundles, convenience slots**, optional supporter pack.
- Never: ads, paid random boxes, pay-to-win.

### 5.8 Minigames
The match-3 prototype may return as an in-world puzzle terminal (`GAMEPLAY-3D.md` section 9).

## 6. Art and Music

- **Visuals**: stylized cel-shaded anime, clean outlines, expressive faces, bright saturated daytime worlds and moody neon night worlds. A slightly mature adventure tone for teenagers and adults, not childish and not obscene.
- **Music** (anime style): energetic synth/rock for action, orchestral and lo-fi for exploration, adaptive layers.
- Licensing: original compositions or CC0/commissioned work (**no** copyrighted anime songs). Own art, music and brand stay proprietary to protect revenue.
- Sound design: shard chimes and ability sounds in key with the music.

## 7. Roadmap

| Phase | Content | Result |
|---|---|---|
| 0: Concept (done) | Documents, direction | Go |
| 1a: Match-3 prototype (done) | Tested logic and 20 levels in the repository | Possible minigame |
| 1: 3D vertical slice (3 to 5 months) | Controller, one seeded voxel island, avatar with 3 outfits, touch controls, Android tests, soft test with teenagers (see `GAMEPLAY-3D.md` section 10) | Playable APK, fun test |
| 2: World and building (3 to 4 months) | Abilities, several worlds, set pieces, home world building, universe progression, music | Single-player beta |
| 2.5: Ledger spec (1 to 2 months) | Leaf and claim formats (input replays), emission model, economy simulator, local `ChainBackend` | Spec v1 |
| 3: Identity and P2P (3 months) | Key-based identity, automatic transport manager (Tor first), DHT, bootstrap endpoints (clearnet, Tor, I2P), Nexus with 2 to 10 players, invisible-networking UX | Test Nexus |
| 3a to 3c: Chain and Shop | Private testnet, pruning and bootstrap, Shop Authority and Crystals, shop service, admin UI (see `CHAIN-DESIGN.md` section 10 and `SERVER.md` section 9) | Closed beta with first purchases |
| 4: I2P, ghost races, raids (2 to 3 months) | I2P added to the transport manager, asynchronous races, trading, events | Open beta |
| 5: Launch and live operation | F-Droid/Play, community nodes, content updates | 1.0 |

**Recommendation:** prove the fun first (phase 1), only then build the expensive networking and chain. The network must never block fun: the game must be **fully playable offline**.

## 8. Risks

| Risk | Mitigation |
|---|---|
| Scope too large | Strict phases, single-player first, public worlds non-editable |
| Art cost and quality | Commission an artist, licensed or CC0 base assets, check tool licenses |
| Mobile 3D performance | Rust meshing, LOD, strict budgets, early device tests |
| Tor/I2P too slow for real-time | Loose-sync presence, asynchronous competition, no real-time PvP |
| Few players -> empty Nexus | Bots/NPC avatars, offline Nexus simulation, events to concentrate players |
| Abuse/chat, teen audience | Emotes first, local block lists, closed avatar kit, rating review |
| Store rejection | Privacy documentation, F-Droid alternative |
| Cheating | Deterministic controller plus replay verification |
| Weak retention or conversion | Soft test in phase 1 before building network and chain |
| Regulation of virtual currency | Closed-loop currencies, legal review, see `CHAIN-DESIGN.md` section 9 |
| Server seizure, blocking or compromise | Multiple endpoints and mirrors, onion/I2P access, multisig shop key, servers untrusted for integrity |
| Looking like a Minecraft clone | Own art direction, set pieces, abilities, quantum mechanics |

## 9. Open Questions

1. Art plan, team and budget: who makes avatars, animations and environments?
2. Voxel blocks with bevels or smooth terrain?
3. How much action: pure platforming and collecting, or light combat too?
4. Minimum device spec to target?
5. Distribution: Google Play, F-Droid or both?
6. Keep the match-3 prototype as a minigame, or drop it?
7. Open questions on shop, accounts, servers, offline and governance: see `SUSTAINABILITY.md` section 7, `IDENTITY-SHOP.md` section 5, `SERVER.md` section 11 and `OFFLINE.md` section 7. Gameplay questions: `GAMEPLAY-3D.md` section 12.

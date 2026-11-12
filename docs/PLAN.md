# Quantum World: Project Plan and Gameplay Sketch

Status: Draft v0.5

Related documents: `GAMEPLAY-3D.md` (open world, avatar levels, phone first), `CHAIN-DESIGN.md` (ledger), `SUSTAINABILITY.md` (decisions and revenue model), `IDENTITY-SHOP.md` (shop, accounts, addresses), `SERVER.md` (optional server layer and bootstrap), `OFFLINE.md` (offline play), `ASSET-PIPELINE.md` (engine and AI-assisted assets).

## 1. Vision

A 3D anime-style open-world adventure **for Android phones** with real addiction potential. There is no level list: your **avatar levels up** while you explore one large open world full of short challenges. Elegant, attractive anime avatars, an energetic anime soundtrack, a style for teenagers and adults (not childish, not obscene), smooth landscapes, an MMO-like feel (other players visible, crews, shared world events), an anonymous decentralized design and a personal home island. No physics puzzles.

**Design pillars**
1. **Phone first**: touch controls, short sessions, battery and heat limits, small download.
2. **Movement is the fun**: run, jump, double jump, dash, glide. It must feel great from the first 30 seconds.
3. **Challenges everywhere**: short challenges with Bronze, Silver and Gold tiers across the open world.
4. **Avatar growth and style**: levels, abilities and fashion as progression and identity.
5. **Anonymous by default**: no login, no email, no phone number. Tor and I2P run invisibly in the background; players never see or configure anything technical.
6. **Decentralized and offline-capable**: the game keeps working even if no server or network exists.

## 2. Key Decisions (honestly assessed)

| Topic | Recommendation | Reasoning |
|---|---|---|
| Engine | **Godot 4** with a Rust core (GDExtension) | Open source, small APK, good 3D on mobile. Rust gives fast terrain meshing and a deterministic controller shared with Keepers and servers. |
| Core gameplay | **Phone-first 3D open-world action-platformer with avatar levels and challenges** | Matches the target audience and the avatar focus. See `GAMEPLAY-3D.md`. |
| Worlds | **Smooth seed-generated heightfield worlds plus hand-made set pieces** | Only personal state and home islands need storing. Integer heightfield and analytic colliders keep movement deterministic. |
| Progression | **Avatar level, ability tree, no level list** | Fits an open world and an MMO feel; no pay to win. |
| Identity | **Cryptographic key pair (Ed25519) on the device** | No account server. The identity is the key. Layered recovery in `IDENTITY-SHOP.md`. |
| Network | **libp2p-style P2P over Tor/I2P transports** | See section 4. MMO-lite: loose-sync presence, no real-time PvP. |
| Ledger | **Attested, pruned, non-PoW chain** | See `CHAIN-DESIGN.md`. |
| Servers | **Optional Rust servers, expected but never required** | See `SERVER.md`. |
| Data | **Local first** | Save data and home islands live on the device. |
| 3D avatars | **Closed modular kit (VRM/glTF parts), toon shaded, elegant proportions** | Cheap to transmit (parameters only), enforces the content rules. |
| Business model | **Free to play, cosmetic monetization** | Avatar fashion is the main shop category. See section 5.7 and `SUSTAINABILITY.md`. |

**Reality checks**
- **Tor/I2P on Android** is feasible (Tor via `tor-android`/Arti, I2P via `i2pd` or the I2P Android library). However, **latency is 300 ms to 2 s**, so **real-time competitive multiplayer is out**. Seeing other players (low update rate, interpolation), co-op counters, ghosts and asynchronous races work.
- **A true MMO** (server-authoritative, thousands of players, PvP) needs central low-latency servers and money. It conflicts with the decentralized, anonymous design. The target is **MMO-lite**: channels of about 30 to 50 visible players, a ghost crowd from recorded runs, crews, co-op world events.
- **3D open world on phones** is demanding: smooth terrain, avatars and effects need strict budgets (30 fps stable on mid-range phones) and early tests on real devices.
- **Scope** is the biggest risk: open world, avatars, MMO feel and ledger together are very large. Strict phases, single-player first.
- **Google Play** allows Tor usage, but apps embedding Tor/I2P need a clean privacy statement. Alternative distribution: F-Droid, direct APK.
- **Battery/data usage**: Tor/I2P in the background is expensive. The network layer starts and stops automatically, **active only in the Nexus, in shared channels and during sync**; solo play runs offline. Android background limits (Doze, app standby) require a short-lived foreground service for sync.
- **Fully serverless** is hard for peer discovery, cheat protection and moderation. Solution: a **hybrid** (see 4.3) with replaceable bootstrap endpoints and optional servers but no central authority over game state.
- **Anonymous does not mean unmoderated**: the audience starts at age 12. Chat is emotes/stickers only by default, free text optional plus local block lists. Avatars are fully clothed and there are no sexualized items.

## 3. Architecture Overview

```
+---------------- Android App (Godot) ----------------+
| 3D world | Avatar kit | Audio | UI | Shop            |
+------------------------------------------------------+
| Rust core (GDExtension): heightfield, meshing,        |
| deterministic controller, replay verification         |
+------------------------------------------------------+
| Local save data (encrypted, home island as deltas)    |
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

### 4.3 Discovery and Shared Channels without a Central Server
- **DHT (Kademlia)** to find channels (overworld instances, Nexus rooms) by hash.
- **Gossip PubSub** per channel for presence, emotes and chat, with interest management by distance.
- **Bootstrap list**: a hard-coded list of at least 5 endpoints (clearnet, Tor, I2P) from different operators, plus signed list updates (`SERVER.md` section 3.2). It is a starting hint and never an authority. If everything fails: invite links/QR codes between friends.
- Channel size: about 30 to 50 visible players (more is too much traffic over Tor), parties of 2 to 4; multiple channels are created automatically. A ghost crowd of recorded runs fills the world (`GAMEPLAY-3D.md` section 8).

### 4.4 Save Data and Anti-Cheat
- Solo progress and home islands: local, cheating only affects the cheater.
- Shared features (leaderboards, ghost races, events, discoveries, XP): **signed results plus input-recording replays**, verified by Keepers with the deterministic controller (`GAMEPLAY-3D.md` section 9). The ledger for shared state is specified in `CHAIN-DESIGN.md`.
- Leaderboards: top lists computed locally from signed results of peers ("gossip leaderboard"). Not tamper-proof, but sufficient for fun.

### 4.5 Data That Is Shared
Only: public key, name, avatar parameters (~200 bytes), avatar level and titles, position in the Nexus or a channel, signed results, emotes. World terrain is never transferred because it is generated from a seed; only home island deltas of visited islands are. **No** device IDs, no IP (thanks to Tor/I2P), no analytics.

### 4.6 Invisible Networking (UX rules)
- The words "Tor", "I2P", "onion", "DHT", "peer" and "node" never appear in the normal UI. Neutral wording is used instead, e.g. "Connecting to the Nexus".
- Startup: the network layer boots in the background (first connection can take 10 to 60 seconds) while the player is already playing. Nothing blocks on the network.
- Connection state is shown as one small, friendly icon (e.g. a glowing portal: closed, opening, open). No error dialogs, no technical messages.
- Network failures degrade gracefully: the Nexus shows "Nexus is far away, try again later" and offers ghosts and NPC avatars; progress is never lost. Offline behavior is specified in `OFFLINE.md`.
- Data usage and battery: sync only on Wi-Fi by default, a single toggle "Save data" in the settings.
- Legal/store: the privacy policy and the store listing still describe the use of anonymizing networks in plain language, even though the in-game UI does not.

## 5. Gameplay Sketch

Full details are in `GAMEPLAY-3D.md`.

### 5.1 Core Loop (3 to 5 minute sessions)
1. Open the map, pick a nearby challenge or just explore.
2. Run, jump, dash and glide across smooth terrain and set pieces to the challenge start ring.
3. Complete the challenge (parkour trial, shard run, glitch hunt, secret, ghost race) for Bronze, Silver or Gold.
4. Earn **XP, shards and cosmetics**; the avatar levels up and unlocks abilities.
5. Visit your home island to decorate, or the Nexus to meet others and shop.
6. See the next challenge on the horizon: "just one more".

### 5.2 The Open World
- One large overworld with regions that suggest an avatar level but have no hard walls; abilities open new routes.
- Hand-made set pieces and secrets inside generated smooth terrain.
- The public overworld is static; progress and discoveries are personal. Portals connect the overworld, home islands, friends' islands and the Nexus.

### 5.3 Avatar Level and Home Island
- Avatar level 1 to 50 and a three-branch ability tree (Mobility, Exploration, Style). No pay to win, no PvP.
- Every player has a private home island to decorate with objects and soft terrain tools; others can visit it.
- **Quantum randomness**: a daily "fluctuation" with bonus spots and modifiers.

### 5.4 Nexus and MMO-Lite
- The Nexus is a sky hub with portals. Avatars walk around (virtual stick, emote wheel), no collisions between players.
- Crews with shared challenges, co-op world events, ghost races, trading post, photo spots, the **Shop**, optional puzzle terminals.
- Chat: **emotes/stickers** by default, free text optional.

### 5.5 Avatars
- 3D anime style (cel-shaded), elegant and attractive, 7 to 8 head proportions, slim, expressive faces, hair and cloth motion. Kit: body shape, hair, eyes, outfits, accessories, auras, animation sets.
- **Content rules:** fully clothed, no sexualized outfits, poses or body options; only approved parts exist in the kit.
- Unlockable through play (never pay to win), cosmetic premium items in the Shop, sharing = parameters only.

### 5.6 Addiction/Retention Mechanics (responsible)
- Dense micro rewards (shard chimes, particles, level-up moments, ability unlocks).
- Daily quests, weekly events, seasons with the Quantum Pass, challenge tiers to master.
- **Near-miss moments** (a Gold time just out of reach, a secret just beyond a gap).
- Visible collections (outfits, auras, emotes, titles, music tracks).
- Social: Nexus presence, crews, co-op events.
- **Ethics**: no paid random loot boxes, no dark patterns, optional break reminders (also important for store policies).

### 5.7 Monetization
Free to play. Revenue through cosmetics and convenience only; details, rules and the Shop service are in `SUSTAINABILITY.md` section 5 and `SERVER.md`.
- **Quanta** (earned by playing) is never sold.
- **Crystals** (premium shop credit) are sold in packs, not transferable, not convertible to money.
- **Quantum Pass**: seasonal free and premium cosmetic reward track. Avatar fashion is the main category. XP and levels are never sold.
- **Limited drops, bundles, convenience slots**, optional supporter pack.
- Never: ads, paid random boxes, pay-to-win.

### 5.8 Minigames
The match-3 prototype may return as a puzzle terminal in the Nexus (`GAMEPLAY-3D.md` section 11).

## 6. Art and Music

- **Visuals**: stylized cel-shaded anime, clean outlines, soft rim light, bright saturated days and moody neon nights, smooth landscapes. A slightly mature adventure tone for teenagers and adults, not childish and not obscene.
- **Music** (anime style): energetic synth/rock for action, orchestral and lo-fi for exploration, adaptive layers.
- Licensing: original compositions or CC0/commissioned work (**no** copyrighted anime songs). Own art, music and brand stay proprietary to protect revenue.
- Sound design: shard chimes and ability sounds in key with the music.

## 7. Roadmap

| Phase | Content | Result |
|---|---|---|
| 0: Concept (done) | Documents, direction | Go |
| 1a: Prototypes (done) | Match-3 prototype and voxel controller prototype with deterministic simulation, replay and tests | Reusable simulation, input and test code |
| 1: Phone vertical slice (3 to 5 months) | Smooth heightfield island, adapted controller, elegant avatar, challenge framework with ghosts, avatar XP and level, Android tests on 2 to 3 phones, soft test with teenagers (see `GAMEPLAY-3D.md` section 11) | Playable APK, fun test |
| 2: Open world (3 to 4 months) | Larger overworld, set pieces, ability tree, more challenge types, home island, music | Single-player beta |
| 2.5: Ledger spec (1 to 2 months) | Leaf and claim formats (input replays, XP), emission model, economy simulator, local `ChainBackend` | Spec v1 |
| 3: Identity and P2P (3 months) | Key-based identity, automatic transport manager (Tor first), DHT, bootstrap endpoints (clearnet, Tor, I2P), Nexus and channels with ghosts, invisible-networking UX | Test Nexus |
| 3a to 3c: Chain and Shop | Private testnet, pruning and bootstrap, Shop Authority and Crystals, shop service, admin UI (see `CHAIN-DESIGN.md` section 10 and `SERVER.md` section 9) | Closed beta with first purchases |
| 4: I2P, crews, events (2 to 3 months) | I2P added to the transport manager, crews, co-op world events, trading | Open beta |
| 5: Launch and live operation | F-Droid/Play, community nodes, content updates, seasons | 1.0 |

**Recommendation:** prove the fun first (phase 1), only then build the expensive networking and chain. The network must never block fun: the game must be **fully playable offline**.

## 8. Risks

| Risk | Mitigation |
|---|---|
| Scope too large | Strict phases, single-player first, one island first, MMO-lite only |
| Phone performance of smooth open terrain | Budgets, LOD, streaming, adaptive quality, early device tests |
| Art cost and quality | Commission an artist, licensed or CC0 base assets, check tool licenses |
| MMO expectations vs Tor latency | Communicate MMO-lite, ghost crowd, async competition |
| Few players -> empty world | Ghost crowd, NPCs, events to concentrate players |
| Abuse/chat, teen audience | Emotes first, local block lists, closed avatar kit, rating review |
| Store rejection | Privacy documentation, F-Droid alternative |
| Cheating, XP farming | Deterministic controller, replay verification, daily caps |
| Weak retention or conversion | Soft test in phase 1 before building network and chain |
| Regulation of virtual currency | Closed-loop currencies, legal review, see `CHAIN-DESIGN.md` section 9 |
| Server seizure, blocking or compromise | Multiple endpoints and mirrors, onion/I2P access, multisig shop key, servers untrusted for integrity |

## 9. Open Questions

1. Landscape two-thumb layout as default, or also a portrait one-hand mode?
2. Minimum device spec to target?
3. Art plan, team and budget: who makes avatars, animations and environments?
4. Level cap and ability list for the first season?
5. Distribution: Google Play, F-Droid or both?
6. Keep the match-3 prototype as a minigame, or drop it?
7. Open questions on shop, accounts, servers, offline and governance: see `SUSTAINABILITY.md` section 7, `IDENTITY-SHOP.md` section 5, `SERVER.md` section 11 and `OFFLINE.md` section 7. Gameplay questions: `GAMEPLAY-3D.md` section 13.

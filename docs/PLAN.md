# Quantum World: Project Plan and Gameplay Sketch

Status: Draft v0.1

## 1. Vision

A colorful, cheerful Android game with real addiction potential: very easy to learn, anime visuals and anime-style music, hundreds of interconnected levels, an anonymous decentralized lobby with 3D avatars, and a personal "Quantum Universe" for every player (worlds, countries, cities, villages, teleportation).

**Design pillars**
1. **One-thumb play**: every action takes 1 to 2 taps, sessions last 2 to 5 minutes.
2. **Reward every second**: colors, sound and particles on every move.
3. **Anonymous by default**: no login, no email, no phone number. Tor and I2P run invisibly in the background; players never see or configure anything technical.
4. **Decentralized**: the game keeps working even if no server exists.
5. **My universe**: progress becomes visible as a growing world of your own.

## 2. Key Decisions (honestly assessed)

| Topic | Recommendation | Reasoning |
|---|---|---|
| Engine | **Godot 4** (or Unity) | Godot is open source, has a small APK and handles mixed 2D/3D well, which fits the decentralized philosophy. Unity has more Android tooling but carries licensing and privacy baggage. |
| Core gameplay | **Match-3 / puzzle hybrid on a world map** | Proven to be addictive, very easy, one-thumb friendly, and levels are easy to interconnect. |
| Identity | **Cryptographic key pair (Ed25519) on the device** | No account server. The identity is the key. Backup via seed phrase (12 words). |
| Network | **libp2p-style P2P over Tor/I2P transports** | See section 4. |
| Data | **Local first + CRDTs** | Save data lives on the device, sync works without a central instance. |
| 3D avatars | **Modular kit (VRM/glTF parts)** | Small files, cheap to transmit over P2P (parameters only, no mesh upload). |

**Reality checks**
- **Tor/I2P on Android** is feasible (Tor via `tor-android`/Arti, I2P via `i2pd` or the I2P Android library). However, **latency is 300 ms to 2 s**, so **real-time action multiplayer is out**. The planned turn-based/asynchronous design fits this well.
- **Google Play** allows Tor usage, but apps embedding Tor/I2P need a clean privacy statement. Alternative distribution: F-Droid, direct APK.
- **Battery/data usage**: Tor/I2P in the background is expensive. Solution: the network layer starts and stops automatically, **active only in the lobby and during sync**, levels themselves run offline. Android background limits (Doze, app standby) require a short-lived foreground service for sync.
- **Fully serverless** is hard for peer discovery, cheat protection and moderation. Solution: a **hybrid** (see 4.3) with optional, replaceable bootstrap nodes but no central authority.
- **Anonymous does not mean unmoderated**: children/teenagers and chat abuse are real concerns. Chat is emotes/stickers only by default, free text optional plus local block lists.

## 3. Architecture Overview

```
+---------------- Android App (Godot) ----------------+
| UI/Gameplay | Avatar kit | Audio engine              |
+------------------------------------------------------+
| Local save data (SQLite, encrypted, CRDT)             |
| Identity: Ed25519 key + seed backup                   |
+------------------------------------------------------+
| P2P layer (libp2p/gossip/DHT)                         |
|   Transports: Tor (onion services) | I2P | direct     |
+------------------------------------------------------+
| Optional: bootstrap/relay nodes (anyone can run one,  |
| no trust required)                                    |
+------------------------------------------------------+
```

## 4. Decentralized Network in Detail

### 4.1 Identity
- On first start: generate a key pair, pick a display name and avatar. **No registration, no login.**
- Public key = player ID. Seed phrase for restoring on a new device.
- Optional: device-to-device transfer via QR code.

### 4.2 Transport
- Every client publishes itself as a **Tor v3 onion service** and/or an **I2P destination**.
- **No user-facing transport settings.** An internal transport manager chooses automatically: it starts Tor and I2P in parallel, uses whichever connects first and keeps the other as a fallback. If both fail, the game stays fully playable offline and retries silently.
- Direct connections are never used for anything that exposes an IP address.
- An advanced/developer option may exist in a hidden menu, but is not part of the normal UI.

### 4.3 Discovery and Lobby without a Central Server
- **DHT (Kademlia)** to find lobbies ("rooms") by hash (e.g. room "Sakura Plaza").
- **Gossip PubSub** per room for presence, emotes and chat.
- **Bootstrap list**: built-in plus community-maintainable list of nodes (onion addresses). If everything fails: invite links/QR codes between friends.
- Lobby size per instance max. ~20 to 30 avatars (more is too much traffic over Tor); multiple instances of the same room are created automatically.

### 4.4 Save Data and Anti-Cheat
- Solo progress: local, cheating only affects the cheater.
- Shared features (leaderboards, trading, events): **signed results plus replay hash**; opponents/witnesses verify by replaying (levels are deterministic via seed).
- Leaderboards: top lists computed locally from signed results of peers ("gossip leaderboard"). Not tamper-proof, but sufficient for fun.

### 4.5 Data That Is Shared
Only: public key, name, avatar parameters (~200 bytes), lobby position, signed level results, emotes. **No** device IDs, no IP (thanks to Tor/I2P), no analytics.

### 4.6 Invisible Networking (UX rules)
- The words "Tor", "I2P", "onion", "DHT", "peer" and "node" never appear in the normal UI. Neutral wording is used instead, e.g. "Connecting to the Nexus".
- Startup: the network layer boots in the background (first connection can take 10 to 60 seconds) while the player is already playing the tutorial and first levels. Nothing blocks on the network.
- Connection state is shown as one small, friendly icon (e.g. a glowing portal: closed, opening, open). No error dialogs, no technical messages.
- Network failures degrade gracefully: lobby shows "Nexus is far away, try again later" and offers NPC avatars; progress is never lost.
- Data usage and battery: sync only on Wi-Fi by default, a single toggle "Save data" in the settings.
- Legal/store: the privacy policy and the store listing still describe the use of anonymizing networks in plain language, even though the in-game UI does not.

## 5. Gameplay Sketch

### 5.1 Core Loop (2 to 5 minutes)
1. The player picks a **node** on the world map (a level).
2. Solves a colorful **match-3 puzzle** ("quantum particles" in 6 colors, swipe/tap). 
3. Special effects: **Superposition** (a particle is two colors at once), **Entanglement** (two particles react together), **Tunneling** (a particle jumps through obstacles), **Collapse** (bomb).
4. Result: 1 to 3 stars plus **quantum energy** plus a random reward (dopamine loop).
5. Energy expands the player's own **universe** (meta game).
6. A new area unlocks, the next node lights up: "just one more level".

### 5.2 Level Structure ("interconnected levels")
Not a linear list but a **graph**:
- **World** (planet) -> **country** -> **city/village** -> **level node**.
- Nodes are linked by paths; stars open gates, teleporters connect distant worlds.
- **Secret paths**: certain patterns/star combinations reveal hidden levels (joy of discovery).
- Long-term target: 5 worlds x 5 countries x ~100 levels = **~2500 levels**. Start: **1 world, 150 levels**.

### 5.3 The Personal Quantum Universe
- Every player owns a universe made of **worlds** that they "collapse" with energy (= unlock/build).
- Worlds have biomes (sakura forest, crystal desert, cloud city, underwater neon, retro arcade).
- On worlds: **countries -> cities -> villages** that the player shapes (buildings, plants, decoration, music stations).
- **Visiting**: other players can visit universes via link/lobby portal (data is loaded P2P, only if the owner is online or cached).
- **Teleportation**: portals between own worlds, to friends and to the lobby. The fast-travel animation is a reward moment.
- **Quantum randomness**: a daily "fluctuation" (random event, rare items).

### 5.4 Lobby ("Nexus")
- A floating anime plaza in space. Avatars walk around (stick on the left, emote wheel on the right).
- Activities: mini duels (asynchronous puzzle with the same seed), trading post (decoration), cooperative **raid levels** (all players solve one mega level over several days), photo spots, music jam.
- Chat: **emotes/stickers** by default, free text optional.

### 5.5 Avatars
- 3D, chibi anime style (cel-shaded). Kit: body shape, hair (50+), eyes, outfits, wings/tails, aura.
- Unlockable through play (never pay to win), sharing = parameters only.
- The avatar walks in the lobby and the universe; in levels it appears as a mascot that cheers.

### 5.6 Addiction/Retention Mechanics (responsible)
- Dense micro rewards (combo sounds, confetti, stars).
- Daily login reward, daily quests, weekly events.
- **Near-win moments** (level narrowly missed -> "one more try").
- Visible collections (avatar parts, particle skins, music tracks).
- Social: lobby presence, cooperative raids.
- **Ethics**: no real-money loot boxes, no dark patterns, optional break reminders (also important for store policies).

### 5.7 Monetization (compatible with anonymity)
Without accounts, classic subscriptions/purchases are difficult. Options: one-time premium purchase, cosmetic purchases via Google Play, voluntary donations (Monero/Lightning), optional ad-free mode. To be decided later.

## 6. Art and Music

- **Visuals**: colorful, pastel plus neon, cel-shaded 3D, 2D puzzle with large, soft shapes.
- **Music** (anime style): J-pop/future bass/lo-fi chill per world, adaptive music (layers fade in on combos).
- Licensing: original compositions or CC0/commissioned work (**no** copyrighted anime songs).
- Sound design: every combo produces a tone sequence in key with the music.

## 7. Roadmap

| Phase | Content | Result |
|---|---|---|
| 0: Concept (2 to 3 weeks) | This plan, paper prototype sketches, engine decision | Go/No-Go |
| 1: Vertical slice (2 to 3 months) | Match-3 core, 20 levels, world map, placeholder music, basic avatar | Playable APK prototype, fun test |
| 2: Meta (2 to 3 months) | Universe building mode, progression, teleportation, 100+ levels, music | Single-player beta |
| 3: Identity and P2P (3 months) | Key-based identity, automatic transport manager (Tor first), DHT, lobby with 2 to 10 players, invisible-networking UX | Test lobby |
| 4: I2P, duels, raids (2 to 3 months) | I2P added to the transport manager, asynchronous duels, trading, events | Open beta |
| 5: Launch and live operation | F-Droid/Play, community nodes, content updates | 1.0 |

**Recommendation:** prove the fun first (phase 1), only then build the expensive networking. The network must never block fun: the game must be **fully playable offline**.

## 8. Risks

| Risk | Mitigation |
|---|---|
| Tor/I2P too slow | Asynchronous mechanics only; caching; automatic fallback between transports |
| Few players -> empty lobby | Bots/NPC avatars, offline lobby simulation, events to concentrate players |
| Abuse/chat | Emotes first, local block lists, report signals in gossip |
| Store rejection | Privacy documentation, F-Droid alternative |
| Scope too large | Strict phases, single-player first |
| Cheating | Deterministic levels plus replay verification |

## 9. Open Questions

1. Core gameplay: is match-3 fine, or rather runner/idle/builder?
2. Engine: Godot (open source) or Unity?
3. Target audience/age (affects chat and store rating)?
4. Monetization: free, one-time purchase, donations?
5. Team: solo or with an artist/composer?
6. Distribution: Google Play, F-Droid or both?

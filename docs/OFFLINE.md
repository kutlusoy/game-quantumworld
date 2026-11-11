# Quantum World: Offline Play (Draft v0.1)

Offline play is possible and is the default design: the game is offline-first, and network and ledger are background add-ons (`PLAN.md` 4.6, `CHAIN-DESIGN.md` 1).

## 1. What Works Offline

| Feature | Offline? | Notes |
|---|---|---|
| All levels, world map, progression | Yes | Level content ships in the app, levels are deterministic |
| Personal universe: building, decorating, teleporting between own worlds | Yes | Universe data lives on the device |
| Avatar creation and editing, owned cosmetics | Yes | Avatar kit ships in the app |
| Music, sound, events that are local (daily quests, local streaks) | Yes | |
| Earning Quanta | Yes, provisional | Claims are signed and queued; final after sync |
| Lobby (Nexus) | NPC-only | Real players need the network; offline shows NPC avatars |
| Duels, raids, tournaments, trading | No | Need peers; results can be played offline and submitted later where the event allows |
| Visiting other universes | Cached only | Previously visited universes may be cached |
| Shop purchases (Crystals) | No | Needs the Shop service and the store |
| Spending Crystals or Quanta on shop items | Queued | Optimistic local display, final after sync |
| Account recovery levels 1 to 3 | Partly | QR phone transfer works locally; others need network |

## 2. Local Ledger Mode

The game talks to the chain through `ChainBackend`. Offline it uses the **local ledger**: a signed, append-only local log of claims and spends, plus the last verified chain state.
- Balances shown offline are the last verified state plus local pending changes, marked as pending in the UI.
- On reconnect, the client syncs from a checkpoint (`CHAIN-DESIGN.md` 5.4), submits the queued claims in order and reconciles.

## 3. Queued Claims and Their Limits

- Claims carry a signature and an epoch validity window (proposal: event claims 14 days). Claims that arrive after the window expire cleanly and the UI says so in friendly words.
- One-time rewards (First Clear, recorded in `ClearBitmap`) do not need a short window; replay protection comes from the bitmap.
- **Conflicts on reconnect:** a Discovery may have been claimed by someone else, or a pool may be exhausted. The client shows the provisional reward as "not granted" without alarm. Design the UI so provisional Quanta is clearly provisional.
- **Cheating offline:** an offline client can fabricate claims, but Keepers replay every claim deterministically and reject invalid ones (`CHAIN-DESIGN.md` 6.3). Offline play adds no cheating surface.

## 4. Time and Clocks

- Chain time (epochs) is the authority for anything with value. A device clock set forward or back must not earn Quanta.
- Purely local features (streaks, local daily quests, energy regeneration) use the device clock, protected with a monotonic-time check, and grant cosmetic or local rewards only.
- Daily event rewards that pay Quanta (Daily Fluctuation) are only claimable against the on-chain epoch.

## 5. Offline Safety

- Save data: encrypted local database with atomic writes and periodic local backups, so crashes and low battery do not corrupt progress.
- Recovery level 0 (OS backup) works without the game's servers (`IDENTITY-SHOP.md` 3.2).
- First launch needs no network: the identity key is generated locally; the player can start playing immediately and the network layer connects in the background when available.

## 6. Design Rules

1. Nothing in the core loop may wait for the network.
2. Never show network errors as dialogs; show small neutral states instead.
3. Everything with value is provisional offline and final only after on-chain confirmation.
4. Content must be shipped or cached; avoid features that stream required content.

## 7. Open Questions

1. Claim validity window: 14 days for event claims, or longer?
2. Should offline-earned Quanta be spendable locally before confirmation (risk: reversal on conflict), or only after sync?
3. How much of other players' universes should be cached for offline visiting?

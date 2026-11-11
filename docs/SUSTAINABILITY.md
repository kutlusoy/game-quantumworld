# Quantum World: Decisions and Self-Sustaining Design (Draft v0.3)

## 1. Decisions

1. **Quanta is a closed-loop, earn-only currency.** It is earned by playing and spent in the game. It is never sold for money, cannot be cashed out and has no exchange integration.
2. **Servers are optional and never required.** The game plays offline and the chain stays verifiable without any server. Rust servers provide fast bootstrap, the shop, an admin UI and support (`SERVER.md`). They hold no power over balances or rules.
3. **Revenue model: free to play, cosmetic monetization.** The developer earns through Crystals (premium shop credit), a seasonal pass, limited cosmetic drops and convenience slots. See section 5.
4. **Never:** advertising, paid random loot boxes, pay-to-win items, selling Quanta.
5. **Self-sustaining where possible:** low operating cost, self-balancing in-game economy.

The two-currency model and the Shop Authority role are specified in `IDENTITY-SHOP.md` section 1.

## 2. Infrastructure

| Function | Who provides it | Notes |
|---|---|---|
| Anonymous transport | Tor and I2P networks | Existing public networks, no cost to us |
| Peer discovery | DHT, signed peer lists, invite links and QR codes | |
| Chain bootstrap | Redundant bootstrap endpoints and mirrors, later also peers | Untrusted: all data is verified against checkpoints (`SERVER.md` section 3) |
| Ledger validation | Keepers (volunteer and seed nodes) | See section 3 |
| State snapshots | Mirrors and any peer holding a verified snapshot | Verified against the attested hash |
| Universe data, avatars | Owner's device plus peers that cache it | Only hashes live on chain |
| Shop catalogue | Signed list spread P2P and served by the server | |
| Purchase confirmation, admin UI, recovery vault | Optional Rust server layer | `SERVER.md` |
| App distribution | F-Droid, signed APK, optionally Google Play | Each release embeds a recent trust checkpoint |
| Telemetry | None | |

**Cold start, stated honestly.** On day one there are no community Keepers. The developer runs a few seed Keepers and bootstrap endpoints. They hold no special rights in the protocol and are meant to be diluted as community operators join.

**Graceful degradation.** If the servers, the player base or the Keeper set shrink, solo play continues in offline mode behind `ChainBackend`; the shared layer gets quieter.

## 3. The Keeper Incentive Problem (closed-loop consequence)

With a closed-loop currency, running a Keeper earns nothing that can be sold. So Keeper participation must be cheap and rewarded in things players value:

- **Near-zero cost:** light Keeper mode on a phone while charging on Wi-Fi, or a Raspberry Pi.
- **In-game rewards:** the Keeper pool pays Quanta plus exclusive, non-transferable cosmetics (Keeper aura, Keeper-only worlds, a name in the Nexus hall).
- **Volunteer culture:** same model that sustains Tor relays, I2P routers and Bitcoin full nodes. Expect a committed minority.
- **No pretending:** if Keeper participation stays too low in the testnet, reduce the chain's security target (smaller committee, longer finality) rather than rely on promises of future rewards.

## 4. A Self-Balancing In-Game Economy

- **Sources** are fixed per epoch by the emission schedule and split into event pools (`CHAIN-DESIGN.md` section 6). Nothing is minted outside those pools.
- **Sinks** are universe building, teleport upgrades, event entry, Quanta-priced shop items, nickname registration and burned fees. At maturity, sinks should absorb at least what sources emit.
- **Crystals are separate.** Minted only by the Shop Authority against a confirmed payment and burned when spent, so they never build a float and never touch the Quanta supply.
- **No central economy controller.** Parameters are consensus rules. Changes ship as scheduled protocol upgrades in app releases and take effect at an announced epoch.
- **Before launch:** the economy simulator (roadmap phase 2.5) must show stable balances under normal, bot-heavy and Sybil-heavy populations.

Limit to be honest about: app releases are signed by the developer, so protocol upgrades and embedded checkpoints are not fully trustless. Open governance is a later topic.

## 5. Revenue Model

Operating cost target: low (a few small servers, see `SERVER.md`). What remains is development, art, music, audits, legal review, store fees and user acquisition.

### 5.1 Products
| Product | Description | Notes |
|---|---|---|
| **Crystal packs** | Premium shop credit, bundles from about 0.99 to 99.99 EUR, first-purchase bonus | Main revenue. Not transferable, not convertible to money, burned on spend |
| **Quantum Pass (season pass)** | Free and premium reward track per season, cosmetics only, tied to the season events | Strong retention driver, new content each season |
| **Limited drops and bundles** | Time-limited signed catalogue entries: outfits, auras, world skins, music tracks | Scarcity without randomness |
| **Convenience slots** | Extra universe and avatar slots | Never required for progress |
| **Supporter pack / donations** | Optional, supporter badge signed offline | No gameplay power |

Rules: cosmetics and convenience only, fixed visible prices, no paid randomized rewards, no gameplay advantage. Quanta-priced shop items act as a sink and are earnable by playing.

### 5.2 Shop service
The optional Rust Shop service confirms purchases and signs Crystal issues with a multisig key (`SERVER.md` section 6). If it is offline, only purchases and pass activation pause.

### 5.3 Distribution and payments
- Google Play generally requires its own billing for digital goods and charges a fee. In many countries Google acts as merchant of record and handles sales tax. Verify the current policy before building.
- F-Droid builds cannot use Play billing; offer donations or a separate payment option there.
- Check consumer law for selling virtual currency (clear pricing, minors, refunds) and your own tax and business obligations.

### 5.4 Protecting revenue in an open design
An open client can be forked and its shop bypassed. Protection is structural: Crystals and shop items are valid only if signed by the Shop Authority key on the official chain. A fork gets its own empty chain and no existing players. Keep art, music and brand under a proprietary license.

### 5.5 Validate before building the chain
The phase 1 vertical slice should be soft-launched to measure retention and payer conversion. Rough casual-game orientation (not a forecast): about 35 to 40 percent day-1 retention and 1 to 3 percent paying users. If retention is weak, fix the game before building the network.

## 6. Impact on Other Documents

- `CHAIN-DESIGN.md` is updated for Crystals, shop items and the Shop Authority; bootstrap per `SERVER.md`.
- `PLAN.md` section 5.7 is replaced by section 5 above.

## 7. Open Questions

1. Who operates the Shop service and holds the Shop Authority key shares; multisig from the start?
2. Crystal price ladder, pass price and season length?
3. Recovery levels and optional account as in `IDENTITY-SHOP.md` section 3?
4. Unique paid nicknames, tagged free nicknames, or both?
5. Retire developer seed Keepers after a fixed date or a Keeper-count threshold?
6. Open governance for protocol upgrades, or developer-signed releases only?
7. Further questions on servers: `SERVER.md` section 11.

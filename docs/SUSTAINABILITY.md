# Quantum World: Decisions and Self-Sustaining Design (Draft v0.2)

## 1. Decisions

1. **Quanta is a closed-loop, earn-only currency.** It is earned by playing and spent in the game. It is never sold for money, cannot be cashed out and has no exchange integration.
2. **No central game servers.** No account server, no matchmaking server, no analytics backend, no operator-controlled bootstrap, no hosted snapshot download. One optional exception: the Shop Keeper service (section 5.2).
3. **Revenue model: free to play, cosmetic monetization.** The developer earns through Crystals (premium shop credit), a seasonal pass, limited cosmetic drops and convenience slots. See section 5.
4. **Never:** advertising, paid random loot boxes, pay-to-win items, selling Quanta.
5. **Self-sustaining where possible:** near-zero operating cost, self-balancing in-game economy.

The two-currency model and the Shop Authority role are specified in `IDENTITY-SHOP.md` section 1. Its conflict note (section 1.1) is resolved by this document: Quanta stays unsold, Crystals are sold.

## 2. Infrastructure Without Servers

| Function | Who provides it | Notes |
|---|---|---|
| Anonymous transport | Tor and I2P networks | Existing public networks, no cost to us |
| Peer discovery | DHT, built-in bootstrap list, invite links and QR codes | Bootstrap list is community-maintainable and only a starting hint, never an authority |
| Ledger validation | Keepers (volunteer nodes) | See section 3 |
| State snapshots for new nodes | Any peer holding a verified snapshot | Verified against the attested hash, so peers need no trust |
| Universe data, avatars | Owner's device plus peers that cache it | Only hashes live on chain |
| Shop catalogue | Signed list spread P2P | No web server |
| Purchase confirmation | Shop Keeper service (optional, section 5.2) | The only operator-run component |
| App distribution | F-Droid, signed APK, optionally Google Play | No update server needed beyond those channels |
| Telemetry | None | |

**Cold start, stated honestly.** On day one there are no community Keepers. The developer runs a few seed Keepers to get the chain going. They hold no special rights in the protocol (same rules, same stake limits) and the plan is to dilute and retire them as community Keepers join. The seed phase is temporary and documented as such.

**Graceful degradation.** If the player base or the Keeper set shrinks, nothing breaks for solo play: the game is offline-first and falls back to the local ledger mode behind `ChainBackend`. The shared layer simply gets quieter.

## 3. The Keeper Incentive Problem (closed-loop consequence)

With a closed-loop currency, running a Keeper earns nothing that can be sold. So Keeper participation must be cheap and rewarded in things players value:

- **Near-zero cost:** light Keeper mode on a phone while charging on Wi-Fi, or a Raspberry Pi. No dedicated hardware required.
- **In-game rewards:** the Keeper pool pays Quanta plus exclusive, non-transferable cosmetics (Keeper aura, Keeper-only worlds, a name in the Nexus hall).
- **Volunteer culture:** same model that sustains Tor relays, I2P routers and Bitcoin full nodes. Expect a committed minority, not the majority of players.
- **No pretending:** if Keeper participation stays too low in the testnet, the chain's security target must be reduced (smaller committee, longer finality) rather than relying on promises of future rewards.

## 4. A Self-Balancing In-Game Economy

- **Sources** are fixed per epoch by the emission schedule and split into event pools (`CHAIN-DESIGN.md` section 6). Nothing is minted outside those pools.
- **Sinks** are universe building, teleport upgrades, event entry, Quanta-priced shop items, nickname registration and burned fees. At maturity, sinks should absorb at least what sources emit, so the currency does not inflate.
- **Crystals are separate.** They are minted only by the Shop Authority against a confirmed payment and burned when spent, so they never build a float and never touch the Quanta supply.
- **No central economy controller.** Parameters are consensus rules. Changes ship as scheduled protocol upgrades in app releases and take effect at an announced epoch. Users choose whether to update; there is no remote switch.
- **Before launch:** the economy simulator (roadmap phase 2.5) must show stable balances under normal, bot-heavy and Sybil-heavy populations.

Limit to be honest about: app releases are signed by the developer, so protocol upgrades are not fully trustless. Open governance for upgrades is a later topic.

## 5. Revenue Model

Operating cost target: near zero. What remains is development, art, music, audits, legal review, store fees and user acquisition. "Self-sustaining" applies to operations; paying for development needs the revenue below.

### 5.1 Products
| Product | Description | Notes |
|---|---|---|
| **Crystal packs** | Premium shop credit, bundles from about 0.99 to 99.99 EUR, first-purchase bonus | Main revenue. Not transferable, not convertible to money, burned on spend |
| **Quantum Pass (season pass)** | Free and premium reward track per season, cosmetics only, tied to the season events | Strong retention driver, new content each season |
| **Limited drops and bundles** | Time-limited signed catalogue entries: outfits, auras, world skins, music tracks | Scarcity without randomness |
| **Convenience slots** | Extra universe and avatar slots | Never required for progress |
| **Supporter pack / donations** | Optional, supporter badge signed offline | No gameplay power |

Rules: cosmetics and convenience only, fixed visible prices, no paid randomized rewards, no gameplay advantage. Quanta-priced shop items act as a sink and are earnable by playing.

### 5.2 Shop Keeper service (the one server)
To confirm a purchase with the payment provider and sign the Crystal issue, the admin runs a small Shop Keeper service (can be an onion service, small VPS). If it is offline, only purchases and pass activation pause; playing, earning, trading and the Quanta shop continue.

### 5.3 Distribution and payments
- Google Play generally requires its own billing for digital goods and charges a fee. In many countries Google acts as merchant of record and handles sales tax. Verify the current policy before building.
- F-Droid builds cannot use Play billing; offer donations or a separate payment option there.
- Check consumer law for selling virtual currency (clear pricing, minors, refunds) and your own tax and business obligations.

### 5.4 Protecting revenue in an open design
An open client can be forked and its shop bypassed. Protection is structural: Crystals and shop items are valid only if signed by the Shop Authority key on the official chain. A fork gets its own empty chain and no existing players. Keep art, music and brand under a proprietary license, not an open one.

### 5.5 Validate before building the chain
The phase 1 vertical slice should be soft-launched to measure retention and payer conversion. Rough casual-game orientation (not a forecast): about 35 to 40 percent day-1 retention and 1 to 3 percent paying users. If retention is weak, fix the game before building the network.

## 6. Impact on Other Documents

- `CHAIN-DESIGN.md` is updated for Crystals, shop items and the Shop Authority.
- `PLAN.md` section 5.7 is replaced by section 5 above.

## 7. Open Questions

1. Who operates the Shop Keeper service and holds the Shop Authority key; multisig from the start?
2. Crystal price ladder, pass price and season length?
3. Seed phrase as default account, with email + password only as an optional strong-passphrase login (`IDENTITY-SHOP.md` section 3)?
4. Unique paid nicknames, tagged free nicknames, or both?
5. Retire developer seed Keepers after a fixed date or a Keeper-count threshold?
6. Open governance for protocol upgrades, or developer-signed releases only?

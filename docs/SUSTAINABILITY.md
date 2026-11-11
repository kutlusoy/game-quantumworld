# Quantum World: Decisions and Self-Sustaining Design (Draft v0.1)

## 1. Decisions

1. **Closed-loop game currency.** Quanta is earned by playing and spent in the game. No purchase with fiat, no cash-out, no exchange integration, no earning-potential marketing. This resolves open question 1 of `CHAIN-DESIGN.md` and the legal recommendation in its section 9.
2. **No central servers.** No account server, no matchmaking server, no analytics backend, no operator-controlled bootstrap, no hosted snapshot download.
3. **Self-sustaining where possible.** The running game should cost the developer close to nothing to operate, and the in-game economy should balance itself.

## 2. Infrastructure Without Servers

| Function | Who provides it | Notes |
|---|---|---|
| Anonymous transport | Tor and I2P networks | Existing public networks, no cost to us |
| Peer discovery | DHT, built-in bootstrap list, invite links and QR codes | Bootstrap list is community-maintainable and only a starting hint, never an authority |
| Ledger validation | Keepers (volunteer nodes) | See section 3 |
| State snapshots for new nodes | Any peer holding a verified snapshot | Verified against the attested hash, so peers need no trust |
| Universe data, avatars | Owner's device plus peers that cache it | Only hashes live on chain |
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
- **Sinks** are universe building, teleport upgrades, event entry, cosmetics and burned fees. At maturity, sinks should absorb at least what sources emit, so the currency does not inflate.
- **No central economy controller.** Parameters are consensus rules. Changes ship as scheduled protocol upgrades in app releases and take effect at an announced epoch. Users choose whether to update; there is no remote switch.
- **Before launch:** the economy simulator (roadmap phase 2.5) must show stable balances under normal, bot-heavy and Sybil-heavy populations.

Limit to be honest about: app releases are signed by the developer, so protocol upgrades are not fully trustless. Open governance for upgrades is a later topic.

## 5. How the Project Pays for Itself

Operating cost target: near zero (no servers, no domain required, no bandwidth bills). What remains is development, art, music, audits, legal review and store fees. "Self-sustaining" therefore applies to operations. Funding development needs revenue or volunteers.

Options compatible with closed-loop and no servers (can be combined):

| Option | Works without a server? | Notes |
|---|---|---|
| One-time premium purchase | Yes, store handles it | Simplest; fits a casual audience |
| Cosmetic packs via store billing | Yes, receipts checked on the device | Unlocks are local and non-transferable, never sold as Quanta |
| Voluntary donations | Yes | Optional "supporter badge" signed offline with a developer key; verifiable by anyone, grants no gameplay power |
| Grants and open source funding | Yes | Fits the open, decentralized design |
| Ads | Needs ad networks, conflicts with anonymity | Not recommended |

Hard rule: store purchases never convert into Quanta and Quanta never converts into money. That keeps the currency closed-loop.

## 6. Impact on Other Documents

- `CHAIN-DESIGN.md` section 12, question 1: answered (closed-loop). Questions 2 to 5 remain open.
- `PLAN.md` section 5.7 (monetization): use the table in section 5 above. Donations by Monero/Lightning remain possible as voluntary supporter funding, not as an in-game currency purchase.
- `PLAN.md` section 4.3: the bootstrap list is explicitly a hint, not an authority.

## 7. Open Questions

1. Premium one-time price vs free with cosmetic packs, or both?
2. Retire developer seed Keepers after a fixed date or a Keeper-count threshold?
3. Which Keeper-only cosmetics are attractive enough to motivate volunteers?
4. Do you want an open governance process for protocol upgrades, or developer-signed releases only?

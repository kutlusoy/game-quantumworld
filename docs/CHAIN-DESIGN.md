# Quantum World: Ledger Design (Draft v0.2)

This document extends sections 4.4 and 4.5 of `PLAN.md`. Where the two differ, this document wins. Business decisions are in `SUSTAINABILITY.md`; shop, accounts and addresses are in `IDENTITY-SHOP.md`. Like the rest of the networking, the ledger is invisible to players: no wallets, no addresses, no gas, no crypto vocabulary in the UI. Players see "Quantum Energy", Crystals and their universe.

## 1. Goals and Non-Goals

**Goals**
1. A tamper-evident shared ledger for the things that must be shared: the currency, rare items, universe ownership commitments, one-time discoveries, event results, shop issuance.
2. No proof of work. No mining hardware, no battery drain.
3. Bounded storage forever: old blocks are pruned, integrity is preserved by per-block state attestation (the Elektron Net principle).
4. Runs over the Tor/I2P layer from `PLAN.md`, tolerant of 0.3 to 2 s latency.
5. The game stays fully playable offline; the ledger only syncs in the background.

**Non-goals (v1)**
- No exchange listing, no purchase of Quanta with money, no cashing out of any currency (see section 9).
- No smart-contract VM. Game rules are consensus code, not user scripts.
- No on-chain gameplay. Levels are played locally; only signed claims are submitted.

## 2. What We Take From Elektron Net

Reference: `kutlusoy/elektron-net` (`WHITEPAPER.md` 4.3, `doc-elektron/CHANGELOG-muhash-attestation.md`, `doc-elektron/AUDIT_PRUNING_SNAPSHOT.md`). Concepts adopted, not code:

| Elektron Net mechanism | Reference in source | Use in Quantum World |
|---|---|---|
| Per-block attestation: every block commits to a MuHash of the full UTXO set in the coinbase | `ComputeBlockUTXOAttestationHash()` in `src/validation.cpp` | Every block header commits to a MuHash of the full ledger state. Any node that applies the block can check the commitment. |
| Incremental accumulator, add/remove coins without rescans, survives reorgs | `kernel::UTXOMuHashState` in `src/kernel/utxo_muhash.h` | Same: state leaves are added/removed from a `MuHash3072`-style accumulator, O(changes) per block. |
| Time-bounded pruning, only recent blocks kept (137 days) | `MandatoryPruneDepth` | Only a retention window of recent blocks is kept (default 30 days, tunable). |
| Checkpoint snapshots verified against the on-chain attestation, bootstrap peer-to-peer | `NODE_SNAPSHOT`, `getutxosnapshot`, `getsnapshotdata` | New nodes fetch a state snapshot from peers and verify it against the attested hash. No trusted download server. |
| Headers permanent, bodies prunable | whitepaper 4.3.2 | Only compact epoch checkpoints are permanent. |

Where we differ: Elektron Net is Bitcoin-style UTXO plus PoW. Quantum World uses an account/leaf state model plus stake-and-play based block production (section 4).

## 3. Why Not a Kaspa-Style DAG

Kaspa's GHOSTDAG gets its throughput and security from proof of work. Without PoW a DAG gives no Sybil protection and adds ordering complexity. DAG protocols that work without PoW exist (Narwhal/Bullshark style) but assume well-connected, always-online validators, which is the opposite of Tor and phones.

Recommendation for v1: a simple **linear chain** with one leader per slot and committee attestation. It is easy to prune, easy to run over high-latency anonymous transports and easy to audit. A DAG can be revisited later if throughput ever becomes the bottleneck; a match-3 game's ledger load is tiny.

## 4. Consensus: Stake-and-Slots, No PoW

### 4.1 Roles
- **Players (light clients):** phones. Hold their own keys and leaves, verify epoch checkpoints and their own state proofs. They do not produce blocks.
- **Keepers (validators):** opt-in nodes (Raspberry Pi, VPS, desktop, or a phone charging on Wi-Fi). They lock Quanta as stake to participate. Anyone can become a Keeper; there is no admin key and no whitelist for block production.

Honest tradeoff: most players are light clients, so day-to-day validation is done by Keepers. It stays decentralized as long as Keeper participation is open and the Keeper set is large and diverse, which is a social and incentive problem as much as a technical one (see risks).

### 4.2 Slots and leaders
- Slot time: 12 s. Epoch: 1 day (7200 slots).
- Per slot, a leader is chosen by a **VRF** (verifiable random function) over the previous epoch's randomness beacon, weighted by locked stake. Only the leader may propose a block for that slot.
- Stake has a minimum, a lock period and an age requirement, so a fresh Sybil swarm cannot instantly take over.

### 4.3 Finality
- Per epoch a **committee** of ~100 Keepers is sampled by VRF, stake-weighted.
- A block is final when more than 2/3 of the committee signs its hash. Signatures are collected and aggregated into the next block.
- Equivocation (two blocks in one slot, two conflicting votes) is provable and slashes the stake. This is the PoW-free equivalent of "work was wasted on a fork".

### 4.4 Randomness beacon
Committee members reveal VRF outputs each slot; the XOR/hash of valid reveals is the epoch randomness. It also drives the daily "fluctuation" event (section 6), so game randomness is fair and unpredictable.

### 4.5 Do not write this from scratch
Consensus is the riskiest component. Evaluate existing building blocks (a BFT-style engine such as CometBFT, or a Rust implementation of a slot/VRF protocol) before deciding to build. A `ChainBackend` interface in the game keeps the game independent of the choice.

## 5. State, Attestation and Pruning

### 5.1 State model
The ledger is a set of **leaves**, each a small canonical byte string:
- `Account(pubkey, quanta_balance, nonce)`
- `Crystals(pubkey, balance)`: shop credit, minted only by the Shop Authority, burned on spend, not transferable
- `Item(item_id, owner)` for rare cosmetics and world deeds; shop-issued items are non-transferable
- `Name(nickname, owner)`: optional unique nickname registration
- `UniverseRoot(owner, hash)`: only a hash of the player's universe; the universe data itself lives P2P and is never stored on chain
- `Discovery(discovery_id, first_finder)`: one-time global claims
- `ClearBitmap(pubkey, bitmap)`: which levels have paid out their one-time reward
- `ShopAuthority(keyset, threshold)`: the recognised Shop Authority key (multisig)

Keeping bulky game data off chain is the main reason the chain stays small.

### 5.2 Per-block attestation
Every block header contains `state_attestation = MuHash(all leaves after this block)`. The accumulator is updated incrementally (add new leaf encoding, remove old). MuHash is order-independent, so Keepers and verifying nodes need no canonical ordering of leaves.

Tradeoff: MuHash gives whole-state integrity but no inclusion proofs. Therefore, once per epoch the checkpoint additionally carries a **sparse Merkle root** of the state, so light clients can verify their own balance and items with a Merkle proof against a committee-signed checkpoint.

### 5.3 Pruning
- Keep: block bodies for the **retention window** (default 30 days, about 216,000 blocks), the current state, and epoch checkpoints.
- Prune: everything older. Nobody can reconstruct history, which is also a privacy feature, same as in Elektron Net.
- **Epoch checkpoint** (permanent, a few KB): epoch number, state MuHash, state Merkle root, next committee commitment, aggregated committee signatures. Roughly 1 to 3 MB per year of chain life.

### 5.4 Bootstrap of a new node
1. Hard-coded genesis checkpoint and committee.
2. Fetch the chain of epoch checkpoints from any peer; each is signed by the committee committed in the previous one, so trust chains back to genesis.
3. Fetch the latest state snapshot from peers (chunked, same idea as `getsnapshotdata`).
4. Recompute the MuHash of the snapshot and compare with the attested value in the checkpoint and the recent headers. Reject on mismatch.
5. Replay the blocks inside the retention window.

No trusted server, no full-history download, no unbounded growth.

## 6. Currencies and Minting by Events

Two currencies (see `SUSTAINABILITY.md`):
- **Quanta:** earn-only, minted by events, never sold. Everything in sections 6.1 to 6.5 concerns Quanta.
- **Crystals:** premium shop credit, minted only by the Shop Authority against a confirmed payment (section 6.6).

### 6.1 Emission
- A fixed emission schedule defined in consensus: a per-epoch budget that halves on a long cycle (e.g. every 2 years), with a hard supply cap. Numbers are placeholders until the economy is simulated.
- Each epoch's budget is split into **event pools** (below). A pool that is not claimed is not minted (no inflation by inactivity), or rolls into the next epoch up to a cap.

### 6.2 Event pools
| Event | Trigger | Distribution |
|---|---|---|
| **Daily Fluctuation** | Epoch randomness picks a modifier and a set of "hot" levels | Players with a verified clear of a hot level share the pool pro rata by score |
| **Raid** | Cooperative mega level; many players submit partial progress claims | Released when global progress passes a threshold, split by verified contribution |
| **Discovery** | First finder of a secret path, hidden level or new world | One fixed reward per discovery, first valid claim on chain wins |
| **Season / Tournament** | Time-boxed score race, deterministic seed | Top-N by verified score; the season also drives the Quantum Pass track |
| **First Clear** | First time a level is cleared by an account | Small fixed amount per level, recorded in `ClearBitmap` |
| **Keeper reward** | Producing and attesting blocks | Fixed share of the epoch budget plus burned-fee rebate, pro rata to stake and uptime |

### 6.3 Claim verification
A claim contains: level id, level seed commitment, compact move list (~100 to 300 bytes), claimed score, signature. Levels are deterministic, so a Keeper replays the moves in milliseconds and checks the score. Payout amounts are functions of the level id and event rules in consensus; the claimant never chooses an amount. Invalid claims burn the submission fee. Committee members spot-verify claims in bulk to keep phones and Pis cheap.

### 6.4 Sinks (keep the economy alive)
Universe building, teleport upgrades, rare cosmetics, event entry, Quanta-priced shop items, nickname registration, and fees (small, auto-deducted, burned). The UI shows none of this as currency math, only as "Quantum Energy".

### 6.5 Bots and Sybils (be honest)
- Splitting play across many identities does not raise total payouts because pools are fixed per epoch and distributed pro rata by verified score. Sybils are neutral, not profitable.
- Bots that solve match-3 puzzles can still win a share. They cannot be fully prevented without identity. Mitigations: per-account daily caps on paid activity, minimum human-plausible move timing, harder events weighted toward cooperative or social play, and stake-weighted rather than count-weighted tournament rewards. Treat this as a continuing tuning problem, not a solved one.

### 6.6 Crystals and the Shop Authority
The consensus recognises one **Shop Authority** (multisig keyset, rotation through a scheduled protocol upgrade) with exactly three transaction types:
- `PublishCatalogue(entries)`: signed shop catalogue, also gossiped P2P
- `IssueCrystals(account, amount, receipt_ref)`
- `IssueItem(account, item_id)`

Players spend Crystals with `PurchaseItem(item_id)`, which burns the Crystals and creates the `Item` leaf. Consensus **rejects** any Shop Authority transaction that changes Quanta balances, removes or alters items or balances, changes rules or halts the chain. Crystals are never transferable and never convertible. Payment confirmation is done off chain by the Shop Keeper service (`SUSTAINABILITY.md` section 5.2); the chain only sees the signed issue.

## 7. Privacy

- Wallet key, lobby key and avatar key are separate derived keys by default, so a lobby presence cannot be trivially tied to a balance.
- The ledger is public and pseudonymous. Transfers are visible to everyone who holds recent blocks. Confidential amounts and unlinkable transfers are out of scope for v1 (possible later work).
- Pruning removes history older than the retention window.
- Network identity is hidden by the Tor/I2P layer, including for Keepers.
- Purchases: the payment provider knows the buyer, the chain only sees `receipt_ref` as an opaque reference. Use a salted hash so the chain cannot be linked to the payment record without the Shop Keeper.

## 8. Invisible Ledger UX

- No words like wallet, token, gas, address, mining, stake in the normal UI. Keepers have their own advanced app screen (or a separate headless binary) where technical language is fine.
- Claims are submitted automatically in the background after a level; the player sees stars and Quantum Energy immediately (optimistic local display), final confirmation arrives later.
- Keys are created silently, backed up by the same seed phrase as the identity.
- If the chain is unreachable, claims queue locally and are retried; claims carry an epoch validity window so stale ones expire cleanly.
- The shop is a normal in-game screen with clear prices; a purchase shows a short "confirming" state until the Shop Authority issue is final.

## 9. Legal and Store Considerations (needs review before building)

- **Decided:** Quanta is a closed-loop game currency. Earn by playing, spend in game, no purchase with money, no exchange, no cash-out, no earning-potential marketing.
- **Crystals** are sold as premium shop credit. They are not transferable, not redeemable for money and burned on spend, which keeps them outside the tradeable-token model. Still check consumer law (pricing transparency, minors, refund rights), store billing policy and tax duties before enabling sales.
- Do not sell paid randomized rewards. Disclose all prices.
- Get legal advice before enabling any path from Quanta or Crystals to money.

## 10. Roadmap Additions

| Phase | Content | Result |
|---|---|---|
| 2.5: Ledger spec and simulator | Leaf formats, claim format, emission model, economy simulation with bots and Sybils; `ChainBackend` interface with a local single-node implementation so the game works end to end | Spec v1, simulator results |
| 3a: Private testnet | 5 to 10 Keepers on Tor, slots, VRF leaders, committee finality, attestation, snapshot sync | Chain that survives churn and restarts |
| 3b: Pruning and bootstrap | Retention window, epoch checkpoints, snapshot bootstrap, light client proofs | New node syncs from checkpoint |
| 3c: Shop | Shop Authority, Crystals, catalogue gossip, Shop Keeper service, store billing integration, Quantum Pass | First real purchases in a closed beta |
| 4: Public testnet | Open Keepers, event pools live, economy tuning, security review | Long-running testnet (at least 3 months) |
| 5: Mainnet | Only after testnet, audit and legal review | Launch |

The single-player game must never wait for the chain. The chain starts as a thin background service behind `ChainBackend`.

## 11. Risks

| Risk | Mitigation |
|---|---|
| Consensus bugs, large engineering cost | Reuse an existing BFT/slot engine, long testnet, external audit |
| Too few Keepers, centralization | Low entry barrier, light Keeper mode, community nodes, incentive tuning |
| Stake concentration | Stake caps per key per epoch, age requirement, slashing, committee rotation |
| Bots farming events | Pro rata fixed pools, caps, timing heuristics, tuning loop |
| Latency over Tor | 12 s slots, small blocks, parallel Tor/I2P, tolerant timeouts |
| Regulation and store policy | Closed-loop Quanta, non-convertible Crystals, legal review, no cash-out |
| Economy exploits (inflation, farm loops) | Fixed emission, simulation before launch, scheduled protocol upgrades |
| Shop Authority key compromise | Multisig, key rotation procedure, consensus limits on what the key can do |
| Shop Keeper is a single operator-run service | Optional, only pauses purchases, can be redeployed from the same key setup |
| Forks bypassing the shop | Crystals valid only with the Shop Authority signature on the official chain, proprietary art and brand |
| Data growth | Retention window, off-chain universe data, epoch checkpoints only |

## 12. Open Questions

1. Should phones act as Keepers while charging on Wi-Fi, or only dedicated nodes?
2. Retention window: 30 days (default here) or longer, like the 137 days of Elektron Net?
3. Reuse of Elektron Net code (same license family as Bitcoin Core) for MuHash and snapshot logic, or a clean implementation in the game's language?
4. Total supply and halving schedule: fixed cap as in Elektron Net, or an inflationary reward curve?

Answered: closed-loop currency (see `SUSTAINABILITY.md`).

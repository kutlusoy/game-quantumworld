# Quantum World: Optional Server Layer (Draft v0.1)

This document refines `SUSTAINABILITY.md` (decision 2) and `CHAIN-DESIGN.md` section 5.4 (bootstrap). Servers are written in Rust.

## 1. Principle

Servers are **optional, replaceable and untrusted for integrity**. The game must stay playable offline, and the chain must stay verifiable, even if every server disappears. Servers add convenience (fast bootstrap), business functions (shop) and support (admin UI, recovery). They never hold power over balances or game rules; the consensus rules in `CHAIN-DESIGN.md` do.

## 2. Roles

| Role | Purpose | Required for play? |
|---|---|---|
| **Bootstrap and snapshot mirror** | Serves checkpoints, state snapshots, recent blocks and signed peer lists to new nodes | No (peers can do it too) |
| **Shop service (Shop Keeper)** | Verifies store purchases, signs Crystal issues, publishes the catalogue | No, only purchases need it |
| **Admin UI** | Management of shop, seasons, support, moderation | No |
| **Recovery vault (optional)** | Stores client-side encrypted account backups | No |
| **Seed Keeper** | Same `qw-keeper` binary as community Keepers, run by the developer at the start | No |

## 3. Redundant Blockchain Bootstrap

### 3.1 Goals
A new install gets to a verified, current chain state in seconds to minutes, through one or several servers, with redundancy, and without having to trust any of them.

### 3.2 Endpoints
- The app ships with a hard-coded **bootstrap list** of at least 5 endpoints, run by different operators, hosts and countries. The developer runs 2 to 3; community operators can be added.
- Endpoints are onion and I2P addresses. A clearnet fallback is optional and is only reached through the anonymizing layer, so servers never see user IPs.
- A **signed bootstrap list update** (version number, signed by a Bootstrap Authority key, multisig) can be gossiped and served. The app accepts only newer valid lists. The hard-coded list remains the root.
- Anyone can run a **mirror**: the data is a static file layout (checkpoints, snapshot chunks, manifest), so any static host, rsync target or object store works. Mirrors need no trust (see 3.4).

### 3.3 Client procedure
1. Query at least 3 distinct endpoints in parallel for the latest finalized epoch checkpoint.
2. Require agreement (for example 2 of 3) on the checkpoint hash, and require that it extends the **embedded trust anchor** (3.5).
3. Download the checkpoint chain and the latest state snapshot (chunked, resumable) from whichever endpoints answer fastest; chunks may come from different mirrors.
4. Verify: committee signatures on each checkpoint chain back to the anchor; the snapshot's MuHash equals the attested state hash in the checkpoint; reject on any mismatch.
5. Fetch blocks inside the retention window and signed peer records, then join the gossip layer. After that, peers advertise snapshot service as well, so servers become a fallback rather than a dependency.
6. Rank endpoints by latency and success rate, fall back automatically, retry silently.

### 3.4 What a malicious or broken server can and cannot do
- **Cannot:** forge state, balances or items, because every snapshot is checked against a committee-signed checkpoint that chains to the trust anchor.
- **Can:** withhold data, serve stale data, go offline, or log metadata. Mitigations: multiple independent endpoints, agreement across them, peer fallback, access over Tor/I2P.

### 3.4a Eclipse or stale-chain risk
If every endpoint a client can reach is hostile, the client could be fed a stale or alternative history. The agreement rule, the embedded anchor and the peer fallback reduce this. Offline-first play continues regardless.

### 3.5 Trust anchor and long-range safety
Proof-of-stake chains need a recent checkpoint to defend against long-range attacks by old, withdrawn keys. Therefore:
- Genesis checkpoint and committee are hard-coded.
- **Every app release embeds a recent checkpoint.** A node that has been offline longer than the stake withdrawal period (the weak-subjectivity window) must refresh from a quorum of independent servers or from an app update. Set the stake lock period longer than the expected release cadence.
- This is the one place where "trust the app release" is unavoidable. State it openly in the docs.

### 3.6 Load and cost
Snapshots and checkpoints are static, cacheable files; a state snapshot is small (order of tens to hundreds of MB for large player counts, compressed). Static hosting keeps cost low. Rate limits protect the dynamic endpoints.

## 4. Architecture (Rust)

One Cargo workspace shared by all components:
- `qw-core`: leaf encodings, MuHash accumulator, claim verifier, checkpoint verification
- `qw-keeper`: validator node
- `qw-server`: bootstrap, shop, admin API
- `qw-client-ffi`: bindings into the Godot client (godot-rust)

Suggested stack: `tokio`, `axum`, `tower-http`, `sqlx` with PostgreSQL (SQLite for small setups), `rustls`, `webauthn-rs` for admin passkeys, `askama` or `maud` plus `htmx` for the admin UI, `arti` or a Tor daemon in front for onion service reachability. Evaluate Arti's onion service maturity before relying on it. No telemetry or third-party trackers.

## 5. Admin UI

- **Roles:** Admin, Support, Moderator, read-only Analyst.
- **Login:** passkeys (WebAuthn) plus recovery codes; no passwords for admins.
- **Functions:** catalogue and price management, season and Quantum Pass scheduling, Crystal issue log and refunds, support cases (account rescue), reports and nickname blocklist, signed bootstrap list management, aggregated privacy-preserving statistics.
- **Approvals:** price changes and refunds above a threshold need two admins.
- **Audit log:** append-only, hash-chained, every admin action recorded.
- **No access to player keys.** The UI cannot read or reset player secrets.

## 6. Shop Service and Keys

- The Shop Authority key is a multisig (for example 2 of 3). The server holds one share online; the other shares are offline (hardware keys). A server break-in alone cannot issue arbitrary Crystals.
- Purchase flow: Play purchase -> server verifies with the Google Play Developer API -> server prepares `IssueCrystals(account, amount, receipt_ref)` -> multisig signature -> chain.
- **Refunds and chargebacks:** the Shop Authority may need to undo its own issues. Proposal: a fourth limited action `RevokeIssue(issue_id)` that can only reduce Crystals or remove a shop item that the Shop Authority itself issued, within 30 days, and never touches earned Quanta or other items. This requires an update to `CHAIN-DESIGN.md` section 6.6 once agreed.

## 7. Optional Recovery Account

- The key remains the identity. An account on the server is only an optional recovery helper (see `IDENTITY-SHOP.md` section 3).
- The client encrypts the key backup with a password-derived key (for example with OPAQUE-style protocol) and uploads only the encrypted blob. A server leak exposes no keys.
- Email is optional and used for receipts and notices only. Forgetting the password loses this backup; other recovery levels still apply.
- No mandatory accounts.

## 8. Security and Operations

- Run at least 2 servers at different providers; bootstrap mirrors on separate hosts.
- Threat model: server compromise gives an attacker metadata and the ability to withhold service, but not state forgery or free Crystals (multisig); DDoS is mitigated by static caching and mirrors.
- No IP logging; minimal retention; privacy policy matching actual behavior.
- Minors: no storage of personal data without a legal basis; check consent age rules (13 to 16 depending on country) before enabling email features.
- Rough cost: 2 to 3 small VPS plus static hosting, in the order of 10 to 40 EUR per month, to be confirmed.

## 9. Roadmap Placement

- Phase 3: bootstrap server and mirrors with peer lists (also useful before the chain exists).
- Phase 3b: checkpoint and snapshot serving.
- Phase 3c: shop service, admin UI, recovery account.

## 10. Impact on Other Documents

- `SUSTAINABILITY.md`: decision 2 changes from "no servers" to "servers optional, never required".
- `CHAIN-DESIGN.md` 5.4: servers are an untrusted bootstrap source; trust anchor per 3.5. 6.6: `RevokeIssue` if agreed.
- `IDENTITY-SHOP.md`: recovery levels and optional account.

## 11. Open Questions

1. Who operates the bootstrap endpoints besides you, and how many at launch?
2. Allow a clearnet fallback (through Tor) or onion and I2P only?
3. Accept the `RevokeIssue` limited action for refunds?
4. Accounts optional (recommended) or mandatory?
5. Checkpoint embedding cadence: every app release only, or also signed checkpoints delivered by servers with quorum?

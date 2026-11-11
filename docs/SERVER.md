# Quantum World: Optional Server Layer (Draft v0.3)

This document refines `SUSTAINABILITY.md` (decision 2), `CHAIN-DESIGN.md` section 5.4 (bootstrap) and `PLAN.md` section 4.2 (transport). Servers are written in Rust.

## 1. Principle

Servers are **not mandatory, but at least one will probably exist** (run by the developer). They are **replaceable and untrusted for integrity**. The game must stay playable offline (`OFFLINE.md`), and the chain must stay verifiable, even if every server disappears. Servers add convenience (fast bootstrap), business functions (shop) and support (admin UI, recovery). They never hold power over balances or game rules; the consensus rules in `CHAIN-DESIGN.md` do.

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

### 3.2 Endpoints and transports
- The app ships with a hard-coded **bootstrap list** of at least 5 endpoints, run by different operators, hosts and countries. The developer runs 2 to 3; community operators can be added.
- Endpoints are reachable over **clearnet (HTTPS), Tor onion and I2P**. An endpoint may offer one or several of them (hosting details in section 8a).
- **Clearnet is allowed and is the fast path.** Tor and I2P can need 10 to 60 seconds to start, so a first-time user would otherwise wait. Clearnet endpoints use TLS with pinned public keys.
- Clearnet weaknesses, accepted knowingly: the server and its host see the client's IP address, and domains and IPs can be blocked or seized. Mitigations: several independent domains plus IP fallbacks in the hard-coded list, mirrors on other hosts, and onion/I2P endpoints as the censorship-resistant path.
- A **signed bootstrap list update** (version number, signed by a Bootstrap Authority key, multisig) can be gossiped and served. The app accepts only newer valid lists. The hard-coded list remains the root.
- Anyone can run a **mirror**: the data is a static file layout (checkpoints, snapshot chunks, manifest), so any static host, CDN, rsync target or object store works. Mirrors need no trust (see 3.4).

### 3.2a Transport policy (what goes over which path)
| Traffic | Allowed paths | Reason |
|---|---|---|
| Public static bootstrap data (checkpoints, snapshots, peer lists, catalogue) | Clearnet, Tor, I2P, in parallel | Public data, verified by the client, so the path does not matter for integrity |
| Shop purchases and receipts | Clearnet or Tor/I2P | The payment provider already knows the buyer, so clearnet adds little exposure |
| Recovery account | Clearnet or Tor/I2P | Server-side service, HTTPS or onion |
| Admin UI | Onion only (see 8a) | Keep the management surface off the open internet |
| Lobby, peer-to-peer gossip, address records, claims, chat | **Tor/I2P only** | Direct connections would expose a player's IP to other players |

This refines the statement in `PLAN.md` section 4.2 that direct connections are never used: the exception is public bootstrap data and server services, never peer-to-peer traffic between players.

The player sees no setting for this. A hidden advanced option "Tor/I2P only" disables clearnet entirely for users who want maximum privacy, at the cost of slower first start.

### 3.3 Client procedure
1. Query at least 3 distinct endpoints in parallel (clearnet first for speed, onion/I2P as they come up) for the latest finalized epoch checkpoint.
2. Require agreement (for example 2 of 3) on the checkpoint hash, and require that it extends the **embedded trust anchor** (3.5).
3. Download the checkpoint chain and the latest state snapshot (chunked, resumable) from whichever endpoints answer fastest; chunks may come from different mirrors.
4. Verify: committee signatures on each checkpoint chain back to the anchor; the snapshot's MuHash equals the attested state hash in the checkpoint; reject on any mismatch.
5. Fetch blocks inside the retention window and signed peer records, then join the gossip layer over Tor/I2P. After that, peers advertise snapshot service as well, so servers become a fallback rather than a dependency.
6. Rank endpoints by latency and success rate, fall back automatically, retry silently.

### 3.4 What a malicious or broken server can and cannot do
- **Cannot:** forge state, balances or items, because every snapshot is checked against a committee-signed checkpoint that chains to the trust anchor.
- **Can:** withhold data, serve stale data, go offline, or log metadata (including IPs on clearnet). Mitigations: multiple independent endpoints, agreement across them, peer fallback, optional Tor/I2P access.

### 3.4a Eclipse or stale-chain risk
If every endpoint a client can reach is hostile, the client could be fed a stale or alternative history. The agreement rule, the embedded anchor and the peer fallback reduce this. Offline-first play continues regardless.

### 3.5 Trust anchor and long-range safety
Proof-of-stake chains need a recent checkpoint to defend against long-range attacks by old, withdrawn keys. Therefore:
- Genesis checkpoint and committee are hard-coded.
- **Every app release embeds a recent checkpoint.** A node that has been offline longer than the stake withdrawal period (the weak-subjectivity window) must refresh from a quorum of independent servers or from an app update. Set the stake lock period longer than the expected release cadence.
- This is the one place where "trust the app release" is unavoidable. State it openly in the docs.

### 3.6 Load and cost
Snapshots and checkpoints are static, cacheable files; a state snapshot is small (order of tens to hundreds of MB for large player counts, compressed). Static hosting or a CDN keeps cost low and makes clearnet bootstrap cheap. Rate limits protect the dynamic endpoints.

## 4. Architecture (Rust)

One Cargo workspace shared by all components:
- `qw-core`: leaf encodings, MuHash accumulator, claim verifier, checkpoint verification
- `qw-keeper`: validator node
- `qw-server`: bootstrap, shop, admin API
- `qw-client-ffi`: bindings into the Godot client (godot-rust)

Suggested stack: `tokio`, `axum`, `tower-http`, `sqlx` with PostgreSQL (SQLite for small setups), `rustls`, `webauthn-rs` for admin passkeys, `askama` or `maud` plus `htmx` for the admin UI, `arti` or a Tor daemon in front for onion service reachability, `i2pd` for I2P. Evaluate Arti's onion service maturity before relying on it. No telemetry or third-party trackers.

## 5. Admin UI

- **Roles:** Admin, Support, Moderator, read-only Analyst.
- **Login:** passkeys (WebAuthn) plus recovery codes; no passwords for admins.
- **Functions:** catalogue and price management, season and Quantum Pass scheduling, Crystal issue log and refunds, support cases (account rescue), reports and nickname blocklist, signed bootstrap list management, aggregated privacy-preserving statistics.
- **Approvals:** price changes and refunds above a threshold need two admins.
- **Audit log:** append-only, hash-chained, every admin action recorded.
- **No access to player keys.** The UI cannot read or reset player secrets.
- **Reachable only as an onion service** (section 8a).

## 6. Shop Service and Keys

- The Shop Authority key is a multisig (for example 2 of 3). The server holds one share online; the other shares are offline (hardware keys). A server break-in alone cannot issue arbitrary Crystals.
- Purchase flow: Play purchase -> server verifies with the Google Play Developer API -> server prepares `IssueCrystals(account, amount, receipt_ref)` -> multisig signature -> chain.
- **Refunds and chargebacks:** the Shop Authority may need to undo its own issues. Proposal: a fourth limited action `RevokeIssue(issue_id)` that can only reduce Crystals or remove a shop item that the Shop Authority itself issued, within 30 days, and never touches earned Quanta or other items. This requires an update to `CHAIN-DESIGN.md` section 6.6 once agreed.

## 7. Optional Recovery Account

- The key remains the identity. An account on the server is only an optional recovery helper (see `IDENTITY-SHOP.md` section 3).
- The client encrypts the key backup with a password-derived key (for example with an OPAQUE-style protocol) and uploads only the encrypted blob. A server leak exposes no keys.
- Email is optional and used for receipts and notices only. Forgetting the password loses this backup; other recovery levels still apply.
- No mandatory accounts.

## 8. Security and Operations

- Run at least 2 servers at different providers; bootstrap mirrors on separate hosts.
- Threat model: server compromise gives an attacker metadata and the ability to withhold service, but not state forgery or free Crystals (multisig); DDoS is mitigated by static caching, CDN and mirrors.
- **Clearnet privacy:** IP addresses are visible to the server and its host. Do not log IPs, keep retention minimal, and describe this accurately in the privacy policy. Under GDPR an IP address is personal data, so a legal basis and disclosure are needed.
- Minors: no storage of personal data without a legal basis; check consent age rules (13 to 16 depending on country) before enabling email features.
- Rough cost: 2 to 3 small VPS plus static hosting or CDN, in the order of 10 to 40 EUR per month, to be confirmed.

## 8a. Hosting the Servers on Tor and I2P

Every public server service can be reachable over clearnet, Tor and I2P at the same time.

- **Layout:** the Rust server listens only on localhost. A reverse proxy handles clearnet HTTPS. A Tor daemon (or Arti) publishes a v3 onion service and `i2pd` publishes an I2P destination; both forward to the same local port. One application, three front doors.
- **Persistent addresses:** onion and I2P keys are long-term, stored encrypted and backed up, so the addresses survive a host migration. The addresses are listed in the signed bootstrap list and match the persistent-address approach in `IDENTITY-SHOP.md` section 2.
- **Separate onions by purpose:** one onion for public player services, a different one for the admin UI. The admin onion should additionally use Tor v3 client authorization so only authorized admin devices can even connect, on top of passkeys.
- **Admin UI never on clearnet.** Optionally restrict further with an allowlist or VPN.
- **Purchase verification without an open port:** the server calls the Google Play Developer API outbound over clearnet (unavoidable; this reveals the server's own IP only). For purchase notifications prefer a pull subscription instead of a public push endpoint, so no clearnet inbound endpoint is needed for the shop.
- **Redundancy:** run several instances behind OnionBalance-style load sharing so one onion address survives the loss of a host. Use more than one provider.
- **DoS resistance:** enable Tor's proof-of-work defense for onion services where available, rate limits, and keep heavy data (snapshots) on static mirrors and CDNs rather than the origin.
- **Performance:** Tor and I2P are slower and can flap. That is why clients query several endpoints in parallel and clearnet and mirrors remain part of the redundancy.
- **Privacy gain:** players who connect over Tor or I2P are not visible to the server by IP; the server host cannot be tied to the player's network location.

## 9. Roadmap Placement

- Phase 3: bootstrap server and mirrors with peer lists, reachable over clearnet, Tor and I2P (also useful before the chain exists).
- Phase 3b: checkpoint and snapshot serving.
- Phase 3c: shop service, admin UI (onion), recovery account.

## 10. Impact on Other Documents

- `SUSTAINABILITY.md`: decision 2 is "servers optional, never required", with at least one server expected and reachable over clearnet, Tor and I2P (done).
- `PLAN.md` 4.2, 4.3: clearnet exception and bootstrap list (done).
- `CHAIN-DESIGN.md` 5.4: servers are an untrusted bootstrap source with the trust anchor from 3.5, unchanged text remains valid. 6.6: `RevokeIssue` if agreed.
- `IDENTITY-SHOP.md`: recovery levels and optional account (done).
- `OFFLINE.md`: offline behavior when no server is reachable.

## 11. Open Questions

1. Who operates the bootstrap endpoints besides you, and how many at launch?
2. Accept the `RevokeIssue` limited action for refunds?
3. Accounts optional (recommended) or mandatory?
4. Checkpoint embedding cadence: every app release only, or also signed checkpoints delivered by servers with quorum?
5. Which clearnet domains and hosts, and how do you want to handle domain blocking or seizure?
6. Arti or the classic Tor daemon for onion hosting, after a maturity check?

Answered: clearnet is allowed, servers are optional but expected, servers may also run on Tor and I2P.

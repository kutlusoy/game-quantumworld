# Quantum World: Shop, Persistent Addresses and Account Design (Draft v0.2)

Status: proposals for decision. Server-side parts are specified in `SERVER.md`. The conflict noted in section 1.1 is resolved by `SUSTAINABILITY.md`: Quanta stays unsold, Crystals are sold.

## 1. Shop and Game Admin Role

### 1.1 Conflict with the closed-loop decision (resolved)
`SUSTAINABILITY.md` decided: Quanta is never sold for money. A direct Quanta sale by an admin would reverse that. Consequences of selling the earned currency itself:
- It becomes a purchasable token, which pulls the project into token-sale and e-money style regulation (for example MiCA in the EU) and into store rules on blockchain assets.
- It breaks the economy math: money-bought Quanta competes with earned Quanta and inflates supply outside the event pools.
- Players can no longer be told "you cannot buy it, you play for it".

### 1.2 Design: two currencies
| | **Quanta** | **Crystals** (working name) |
|---|---|---|
| Source | Earned by playing (event pools) | Sold by the Game Admin for money |
| Transferable between players | Limited (gifts, trades of earned items) | No |
| Spendable at | Shop (earnable items), universe building, events | Shop (premium items) |
| Convertible to money | No | No, no refunds beyond legal minimum |
| Effect on supply | Fixed emission schedule | Burned on spend, so no float builds up |

The sale is of **Crystals (shop credit)**, a normal closed-loop premium currency. Quanta stays earn-only.

### 1.3 The Shop
- In the Nexus there is a Shop: avatar clothes and accessories, auras, emotes, universe decoration, world skins, music tracks.
- The **catalogue** is a signed list (item id, name, price, currency, preview hash) published by the admin key and spread P2P by gossip. The server also serves it, but nothing depends on that.
- Quanta-priced items are a **sink** that supports the economy. Crystal-priced items are premium cosmetics.
- Bought items are non-transferable (soulbound) in v1. Cosmetics only, never gameplay power, never randomized paid loot boxes.

### 1.4 Admin role, limited by consensus
- A **Shop Authority key** (m-of-n multisig, with key rotation through a scheduled protocol upgrade) is recognised by consensus for exactly three actions: publish catalogue entries, issue Crystals to an account, issue shop items. A fourth limited action `RevokeIssue` for refunds is proposed in `SERVER.md` section 6.
- It **cannot** change balances, take items, change game rules, mint Quanta or halt the chain. The protocol rejects such transactions.
- If the admin misbehaves or disappears, the chain and game continue. Players can fork or rotate the authority through a protocol upgrade.

### 1.5 Payment flow
Selling for money needs someone to confirm a payment and then sign a Crystal issue. This is the optional Shop service in `SERVER.md`:
1. Player buys Crystals through the store's billing (or another payment method).
2. The Shop service verifies the purchase with the payment provider and prepares `IssueCrystals(account, amount, receipt_ref)`, signed by the multisig.
3. Keepers verify the signature and apply it.
If the Shop service is offline, only purchases pause.

Store policy notes (verify before building): Google Play generally requires its own billing for digital goods, with its fee. F-Droid builds cannot use Play billing, so they would offer donations or a separate payment option. Selling virtual currency also brings consumer law duties and tax duties for the admin.

## 2. Persistent Tor and I2P Addresses

- Each install generates a long-term **onion service key** and **I2P destination key**, stored encrypted on the device. The addresses stay the same across restarts.
- A **signed address record** `(identity pubkey, onion address, i2p address, sequence number, expiry)` is published in the DHT, spread in the lobby and served by bootstrap endpoints. Peers verify the signature, so an address cannot be hijacked.
- Every client keeps a **peer book** of last-seen peers and their addresses, plus Tor guard persistence, so reconnecting after a restart does not repeat full discovery.
- Bootstrap list entries are also persistent addresses.

Tradeoffs to accept:
- A fixed address makes a player linkable over time. Provide a **"new identity"** action that rotates all keys and addresses.
- Phones are often offline, so onion services on phones are reachable only while the app is active. Peers cache the record and retry; Keepers and always-on nodes do the real relaying.
- Keeping an onion service published costs battery. Publish only when the lobby or sync is active (see `PLAN.md` section 4.6).

## 3. Accounts and Recovery (target group: age 12 and up)

### 3.1 Why not a 12-word seed, and why not email + password as identity
A 12-word phrase is too complex for children from 12. Deriving the ID from `hash(email + password + salt)` is weak: the ID is public, so weak passwords can be guessed offline; the salt cannot stay secret; there is no recovery; typos silently create a new empty account. Kids also choose weak passwords. So the identity stays a random key, and recovery is layered and mostly invisible.

### 3.2 Recovery levels
| Level | What the player does | Notes |
|---|---|---|
| **0: Automatic** | Nothing | The key lives in the Android Keystore and is included in the OS's encrypted backup. A new phone restores it during setup. Needs Android backup enabled |
| **1: Phone transfer** | Scan a QR code from the old phone | Takes seconds, no words. Also an encrypted export file |
| **2: Rescue card (optional)** | Save an image with a QR code and a 20-character code such as `K7M2-9QXA-4TPW-H8DN-3RZV` | Random code, strong, easy to screenshot or print |
| **3: Trusted people (optional)** | 2 of 3 chosen friends or a parent approve recovery | Good fit for ages 12 to 15 |
| **4: Optional recovery account** | Email (optional) + password to protect an encrypted backup on the server | See `SERVER.md` section 7; no mandatory accounts |
| **Later: PIN recovery** | 6-digit PIN protects a backup split across Keepers, with attempt limits | Cryptographically complex, later phase |

Purchases: paid Crystals and items are the real value at risk. Support can verify a rescue through the store's order history (see `SERVER.md`). This is a support path, not an automatic one.

### 3.3 Nickname and public ID
- Public identity is the **public key**; its short fingerprint is the real ID. Players never see it unless they choose to share it.
- **Nickname** is chosen by the player. Uniqueness has two options:
  1. **Unique on-chain nickname:** a `Name(nickname, owner)` leaf, first come first served, small Quanta fee as a sink, verified by Keepers.
  2. **Non-unique with tag:** `Nickname#4821` from the fingerprint, free.
  Recommendation: both. Free tagged nickname by default, optional paid unique name.
- Nicknames pass a local profanity filter plus a signed blocklist from the server. Reports and block lists use the key, not the nickname.

### 3.4 Minors (12 and up)
- Consent age for data processing varies by country (13 to 16); the game collects very little personal data, but have it reviewed.
- Purchases only through store billing, using family controls and parental approval, plus a spending limit.
- Chat: emotes only for players under 16.
- Age rating through the store's rating process.

## 4. Impact on Other Documents
- `SUSTAINABILITY.md`: decision 2 and the infrastructure table now include optional servers.
- `CHAIN-DESIGN.md`: leaves `Crystals`, `ShopItem`, `Name` and Shop Authority transactions are already included; add `RevokeIssue` once agreed.
- `PLAN.md` sections 4.1 and 4.3: account creation per section 3, persistent address records per section 2.

## 5. Open Questions
1. Who runs the Shop service and holds the Shop Authority key shares; multisig from the start?
2. Accept the recovery levels above (automatic backup as the default, seed phrase dropped)?
3. Optional recovery account (recommended) or mandatory accounts?
4. Unique paid nicknames, tagged free nicknames, or both?

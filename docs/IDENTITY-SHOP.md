# Quantum World: Shop, Persistent Addresses and Account Design (Draft v0.1)

Status: proposals for decision. Items marked "conflict" change earlier decisions in `SUSTAINABILITY.md`.

## 1. Shop and Game Admin Role

### 1.1 Conflict with the closed-loop decision
`SUSTAINABILITY.md` decided: Quanta is never sold for money. A direct Quanta sale by an admin reverses that. Consequences of selling the earned currency itself:
- It becomes a purchasable token, which pulls the project into token-sale and e-money style regulation (for example MiCA in the EU) and into store rules on blockchain assets.
- It breaks the economy math: money-bought Quanta competes with earned Quanta and inflates supply outside the event pools.
- Players can no longer be told "you cannot buy it, you play for it".

### 1.2 Recommended design: two currencies
| | **Quanta** | **Crystals** (working name) |
|---|---|---|
| Source | Earned by playing (event pools) | Sold by the Game Admin for money |
| Transferable between players | Limited (gifts, trades of earned items) | No |
| Spendable at | Shop (earnable items), universe building, events | Shop (premium items) |
| Convertible to money | No | No, no refunds beyond legal minimum |
| Effect on supply | Fixed emission schedule | Burned on spend, so no float builds up |

The sale is of **Crystals (shop credit)**, a normal closed-loop premium currency. Quanta stays earn-only. This gives the admin a revenue stream, which is the funding answer from `SUSTAINABILITY.md` section 5, without turning the project into a token sale.

If you still want to sell Quanta directly, get legal advice first and plan for the economy changes above.

### 1.3 The Shop
- In the Nexus there is a Shop: avatar clothes and accessories, auras, emotes, universe decoration, world skins, music tracks.
- The **catalogue** is a signed list (item id, name, price, currency, preview hash) published by the admin key and spread P2P by gossip. No web server needed.
- Quanta-priced items are a **sink** that supports the economy. Crystal-priced items are premium cosmetics.
- Bought items are non-transferable (soulbound) in v1. Cosmetics only, never gameplay power, never randomized paid loot boxes.

### 1.4 Admin role, limited by consensus
- A **Shop Authority key** (ideally an m-of-n multisig, with key rotation through a scheduled protocol upgrade) is recognised by consensus for exactly three actions: publish catalogue entries, issue Crystals to an account, issue shop items.
- It **cannot** change balances, take items, change game rules, mint Quanta or halt the chain. The protocol rejects such transactions.
- If the admin misbehaves or disappears, the chain and game continue. Players can fork or rotate the authority through a protocol upgrade. This is the honest limit of a decentralized system: the admin is trusted only for the shop.

### 1.5 Payment flow without a central game server
Selling for money needs someone to confirm a payment and then sign a Crystal issue. That is the **one centralized component**, and it stays optional:
1. Player buys Crystals through the store's billing (or another payment method).
2. A **Shop Keeper service**, run by the admin (can be an onion service), verifies the purchase with the payment provider and signs `IssueCrystals(account, amount, receipt_ref)`.
3. Keepers on the chain verify the admin signature and apply it.
If the Shop Keeper is offline, only purchases pause. Playing, earning, trading and the Shop's Quanta items continue.

Store policy notes (verify before building): Google Play generally requires its own billing for digital goods, with its fee. F-Droid builds cannot use Play billing, so they would offer donations or a separate payment option. Selling virtual currency also brings consumer law duties (clear pricing, minors, refund rules) and tax duties for the admin.

## 2. Persistent Tor and I2P Addresses

Yes, this makes sense. Proposed:
- Each install generates a long-term **onion service key** and **I2P destination key**, stored encrypted on the device. The addresses stay the same across restarts.
- A **signed address record** `(identity pubkey, onion address, i2p address, sequence number, expiry)` is published in the DHT and spread in the lobby. Peers verify the signature, so an address cannot be hijacked.
- Every client keeps a **peer book** of last-seen peers and their addresses, plus Tor guard persistence, so reconnecting after a restart does not repeat full discovery.
- Bootstrap list entries are also persistent addresses.

Tradeoffs to accept:
- A fixed address makes a player linkable over time. Provide a **"new identity"** action that rotates all keys and addresses.
- Phones are often offline, so onion services on phones are reachable only while the app is active. Peers cache the record and retry; Keepers and always-on nodes do the real relaying.
- Keeping an onion service published costs battery. Publish only when the lobby or sync is active (see `PLAN.md` section 4.6).

## 3. Account Design: email + password hash?

### 3.1 Assessment
The goal (a stable ID, nickname for display, everything else via the derived ID) is right. The mechanism "hash(email + password + salt) = ID" has real problems in a system with no server:

1. **The ID is public.** Everyone can see it. An attacker can guess email and password combinations offline and compare the result with the public ID. This is the brain-wallet attack. Weak passwords are cracked quickly, and the account holds balance and items.
2. **A salt cannot stay secret.** To log in on a new device the salt must be reproducible, so it is effectively a fixed app constant. It does not stop targeted guessing. A per-user random salt would have to be stored somewhere, which needs a server or the device itself.
3. **No recovery.** There is no server to send a reset mail. Forgotten password means lost account.
4. **Silent typo accounts.** A mistyped email or password produces a different valid ID, so the player lands in a fresh empty account without any error.
5. **The email adds almost no secrecy** (it is guessable or known to the attacker) and nothing verifies it. It would only be an extra input the user must remember.

Your observation "same email, different password gives a different user" is correct and is exactly what causes points 3 and 4.

### 3.2 Recommended design
- **Primary: random seed phrase.** The device generates a key pair from a random 12-word phrase (about 128 bits of entropy). That key is the account. The phrase is shown once for backup. A local **PIN or biometric lock** protects it on the device. Nothing to crack offline.
- **Optional convenience login (email + password), strengthened:**
  - Derive the key with **Argon2id** (memory at least 64 MiB, tuned to about 1 s on a mid-range phone) from `email + password` with an app-specific domain separator.
  - Enforce high entropy: a generated passphrase of 5 or more random words, or a long random password. Reject weak passwords outright.
  - Warn clearly: lose the passphrase and the account is gone. Do not store or transmit the email anywhere.
  - Add a **confirmation step on first creation** (type the passphrase twice and show a short ID fingerprint) to avoid silent typo accounts.
  - Even so, a derived key is weaker than a random seed. Treat it as a second option.
- **Device transfer** by QR code, as already planned.

### 3.3 Nickname and public ID
- Public identity is the **public key**; its short fingerprint is the real ID. Players never see it unless they choose to share it.
- **Nickname** is chosen by the player and shown in the game. Uniqueness has two options:
  1. **Unique on-chain nickname:** a `Name(nickname, owner)` leaf, first come first served, small Quanta fee as a sink, verified by Keepers. Fits the ledger design and still needs no central server.
  2. **Non-unique with tag:** `Nickname#4821` from the fingerprint, free, no registration.
  Recommendation: both. Free tagged nickname by default, optional paid unique name.
- Nicknames pass a local profanity filter. Reports and block lists use the key, not the nickname.

## 4. Impact on Other Documents
- `SUSTAINABILITY.md` decision 1 and section 5: update to the two-currency model if you agree; otherwise stays closed-loop with no premium currency.
- `CHAIN-DESIGN.md`: add leaves `Crystals(account, balance)`, `ShopItem(item_id, owner)`, `Name(nickname, owner)` and the three Shop Authority transaction types.
- `PLAN.md` sections 4.1 and 4.3: account creation and persistent address records as described above.

## 5. Open Questions
1. Do you accept two currencies (earn-only Quanta plus sold Crystals), or do you want to sell Quanta itself despite the legal and economy risks?
2. Who runs the Shop Keeper service and the Shop Authority key, and should it be multisig from the start?
3. Seed phrase as the default and email + password only as an optional strong-passphrase login, as recommended?
4. Unique paid nicknames, tagged free nicknames, or both?

# Quantum World – Projektplan & Gameplay-Skizze

Status: Entwurf v0.1

## 1. Vision

Ein buntes, fröhliches Android-Spiel mit Suchtfaktor: sehr leicht zu lernen, Anime-Optik und Anime-Musik, hunderte verbundene Level, eine anonyme dezentrale Lobby mit 3D-Avataren und ein persönliches „Quanten-Universum" pro Spieler (Welten, Länder, Städte, Dörfer, Teleportation).

**Designsäulen**
1. **Ein-Daumen-Spiel**: jede Aktion in 1–2 Taps, Session 2–5 Minuten.
2. **Belohnung in jeder Sekunde**: Farben, Sound, Partikel bei jedem Zug.
3. **Anonym by default**: kein Login, keine E-Mail, keine Telefonnummer.
4. **Dezentral**: das Spiel läuft auch, wenn kein Server existiert.
5. **Mein Universum**: der Fortschritt wird sichtbar als eigene, wachsende Welt.

## 2. Zentrale Entscheidungen (ehrlich bewertet)

| Thema | Empfehlung | Begründung |
|---|---|---|
| Engine | **Godot 4** (oder Unity) | Godot: Open Source, kleine APK, gute 2D/3D-Mischung, passt zur Dezentral-Philosophie. Unity hat mehr Android-Tooling, aber Lizenz-/Datenschutz-Ballast. |
| Spielkern | **Match-3 / Puzzle-Hybrid auf einer Weltkarte** | Bewiesen süchtig machend, sehr leicht, 1-Daumen, Level lassen sich leicht verknüpfen. |
| Identität | **Kryptografisches Schlüsselpaar (Ed25519) auf dem Gerät** | Kein Account-Server. Die Identität ist der Schlüssel. Backup per Seed-Phrase (12 Wörter). |
| Netzwerk | **libp2p-artig P2P über Tor/I2P-Transport** | siehe 4. |
| Daten | **Lokal zuerst + CRDTs** | Spielstand liegt auf dem Gerät, Sync ohne zentrale Instanz. |
| 3D-Avatare | **Baukasten (VRM/glTF-Teile)** | Kleine Dateien, schnell über P2P übertragbar (nur Parameter, kein Mesh-Upload). |

**Wichtige Realitätschecks**
- **Tor/I2P auf Android**: machbar (Tor via `tor-android`/Arti, I2P via `i2pd` oder I2P-Android-Library). Aber **Latenz 300 ms – 2 s**, daher **kein Echtzeit-Action-Multiplayer**. Das Spielkonzept (rundenbasiert/asynchron) passt deshalb ideal.
- **Google Play** erlaubt Tor-Nutzung, aber Apps mit eingebettetem I2P/Tor brauchen saubere Datenschutz-Erklärung. Alternative Verteilung: F-Droid, direkte APK.
- **Akku/Datenverbrauch**: Tor/I2P im Hintergrund ist teuer. Lösung: **nur in der Lobby/beim Sync aktiv**, Level selbst laufen offline.
- **Komplett serverlos** ist schwer bei: Auffinden anderer Spieler (Discovery), Cheating-Schutz, Moderation. Lösung: **Hybrid** (siehe 4.3): optionale, austauschbare „Bootstrap-Knoten", aber keine zentrale Autorität.
- **Anonym ≠ unmoderiert**: Kinder/Jugendliche, Chat-Missbrauch → Chat standardmäßig nur Emotes/Sticker, Freitext optional + lokale Blocklisten.

## 3. Architektur-Überblick

```
┌─────────────── Android App (Godot) ───────────────┐
│ UI/Gameplay │ Avatar-Baukasten │ Audio-Engine     │
├────────────────────────────────────────────────────┤
│ Spielstand lokal (SQLite, verschlüsselt, CRDT)     │
│ Identität: Ed25519-Key + Seed-Backup               │
├────────────────────────────────────────────────────┤
│ P2P-Schicht (libp2p/Gossip/DHT)                    │
│   Transporte:  Tor (Onion Services) │ I2P │ direkt │
├────────────────────────────────────────────────────┤
│ Optional: Bootstrap-/Relay-Knoten (jeder kann       │
│ einen betreiben, nicht vertrauenswürdig nötig)     │
└────────────────────────────────────────────────────┘
```

## 4. Dezentrales Netzwerk im Detail

### 4.1 Identität
- Beim ersten Start: Schlüsselpaar erzeugen, Anzeigename + Avatar wählen. **Kein Register, kein Login.**
- Public Key = Spieler-ID. Seed-Phrase zum Wiederherstellen auf neuem Gerät.
- Optional: Gerät-zu-Gerät-Transfer per QR-Code.

### 4.2 Transport
- Jeder Client veröffentlicht sich als **Tor Onion Service v3** und/oder **I2P-Destination**.
- Der Nutzer wählt in den Einstellungen: *Tor* / *I2P* / *Beides* / *Direkt (schnell)*.
- Standard: Tor für Lobby, direkt für nichts Privates.

### 4.3 Discovery & Lobby ohne Zentralserver
- **DHT (Kademlia)** für Auffinden von Lobbys („Räume") anhand eines Hashes (z. B. Raum „Sakura-Platz").
- **Gossip-PubSub** pro Raum für Anwesenheit, Emotes, Chat.
- **Bootstrap-Liste**: fest eincompilierte + von der Community pflegbare Knotenliste (Onion-Adressen). Fällt alles aus: Einladungs-Links/QR zwischen Freunden.
- Lobby-Größe pro Instanz max. ~20–30 Avatare (sonst zu viel Traffic über Tor); automatisch mehrere Instanzen des gleichen Raums.

### 4.4 Spielstand & Anti-Cheat
- Solo-Fortschritt: lokal, Cheating betrifft nur einen selbst.
- Gemeinsame Dinge (Ranglisten, Handel, Events): **signierte Ergebnisse + Replay-Hash**; Gegenspieler/Zeugen verifizieren durch Nachspielen (Level sind deterministisch per Seed).
- Ranglisten: lokal berechnete Top-Listen aus signierten Ergebnissen von Peers („gossip leaderboard"), nicht manipulationssicher, aber ausreichend für Spaß.

### 4.5 Daten, die geteilt werden
Nur: öffentlicher Schlüssel, Name, Avatar-Parameter (~200 Byte), Position in der Lobby, signierte Level-Ergebnisse, Emotes. **Keine** Geräte-IDs, keine IP (durch Tor/I2P), keine Analytics.

## 5. Gameplay-Skizze

### 5.1 Kernloop (2–5 Minuten)
1. Spieler wählt einen **Knoten** auf der Weltkarte (Level).
2. Löst ein farbenfrohes **Match-3-Puzzle** („Quanten-Teilchen" in 6 Farben verbinden, wischen/tippen).
3. Spezialeffekte: **Superposition** (Teilchen ist 2 Farben gleichzeitig), **Verschränkung** (zwei Teilchen reagieren gemeinsam), **Tunneln** (Teilchen springt durch Hindernisse), **Kollaps** (Bombe).
4. Ergebnis: 1–3 Sterne + **Quanten-Energie** + Zufallsbelohnung (Dopamin-Loop).
5. Energie baut das eigene **Universum** aus (Meta-Spiel).
6. Neues Gebiet freigeschaltet, nächster Knoten leuchtet → „nur noch ein Level".

### 5.2 Level-Struktur („verbundene Level")
Keine lineare Liste, sondern ein **Graph**:
- **Welt** (Planet) → **Land** → **Stadt/Dorf** → **Level-Knoten**.
- Knoten sind durch Pfade verbunden; Sterne öffnen Tore, Teleporter verbinden entfernte Welten.
- **Geheime Pfade**: Bestimmte Muster/Sternkombinationen enthüllen versteckte Level (Entdeckerlust).
- Ziel: 5 Welten × 5 Länder × ~100 Level ≈ **2500 Level** langfristig. Start: **1 Welt, 150 Level**.

### 5.3 Das persönliche Quanten-Universum
- Jeder Spieler besitzt ein Universum aus **Welten**, die er mit Energie „kollabieren lässt" (= freischaltet/baut).
- Welten haben Biome (Sakura-Wald, Kristallwüste, Wolkenstadt, Unterwasser-Neon, Retro-Arcade).
- Auf Welten: **Länder → Städte → Dörfer**, die der Spieler gestaltet (Gebäude, Pflanzen, Deko, Musikstationen).
- **Besuchen**: Andere Spieler können Universen per Link/Lobby-Portal besuchen (Daten werden P2P geladen, nur wenn Besitzer online/gecacht).
- **Teleportation**: Portale zwischen eigenen Welten, zu Freunden und zur Lobby. Schnellreise-Animation = Belohnungsmoment.
- **Quanten-Zufall**: Täglich wechselnde „Fluktuation" (zufälliges Ereignis, seltene Objekte).

### 5.4 Lobby („Nexus")
- Ein schwebender Anime-Platz im Weltall. Avatare laufen herum (Stick links, Emote-Rad rechts).
- Aktivitäten: Mini-Duelle (asynchron-Puzzle mit gleichem Seed), Tauschbörse (Dekoration), gemeinsame **Raid-Level** (alle Spieler lösen gemeinsam einen Mega-Level über Tage), Fotospot, Musik-Jam.
- Chat: Standard **Emotes/Sticker**, Freitext optional.

### 5.5 Avatare
- 3D, Chibi-Anime-Stil (cel-shaded). Baukasten: Körperform, Haare (50+), Augen, Outfits, Flügel/Schwänze, Aura.
- Freischaltbar durch Spielen (nie Pay-to-Win), Teilen = nur Parameter.
- Avatar läuft in Lobby + Universum, im Level erscheint er als Maskottchen, das jubelt.

### 5.6 Sucht-/Bindungsmechaniken (verantwortungsvoll)
- Dichte Mikro-Belohnungen (Combo-Sound, Konfetti, Sterne).
- Tägliche Login-Belohnung, tägliche Quests, wöchentliche Events.
- **Fast-Gewinn-Momente** (Level knapp verpasst → „Noch ein Versuch").
- Sichtbare Sammlungen (Avatar-Teile, Teilchen-Skins, Musik-Tracks).
- Soziales: Lobby-Anwesenheit, gemeinsame Raids.
- **Ethik**: keine Lootboxen mit Echtgeld, keine Dark Patterns, optionale Pausenhinweise. (Wichtig für Store-Richtlinien.)

### 5.7 Monetarisierung (anonym kompatibel)
Kein Account → klassische Abos/Käufe schwierig. Optionen: einmaliger Premium-Kauf, kosmetische Käufe über Google Play, freiwillige Spenden (Monero/Lightning), optional werbefrei. Entscheidung später.

## 6. Kunst & Musik

- **Optik**: bunt, Pastell + Neon, cel-shaded 3D, 2D-Puzzle mit großen, weichen Formen.
- **Musik** (Anime-Stil): J-Pop/Future-Bass/Lo-Fi-Chill pro Welt, adaptive Musik (Layer werden bei Combos zugeschaltet).
- Lizenzen: Eigenkompositionen oder CC0/auftragsbasiert beauftragen (**keine** urheberrechtlich geschützten Anime-Songs).
- Sound-Design: jede Combo erzeugt eine Tonfolge zur Musik (Tonart-synchron).

## 7. Roadmap

| Phase | Inhalt | Ergebnis |
|---|---|---|
| 0 – Konzept (2–3 Wochen) | Dieser Plan, Prototyp-Papier-Skizzen, Engine-Entscheidung | Go/No-Go |
| 1 – Vertical Slice (2–3 Monate) | Match-3-Kern, 20 Level, Weltkarte, Placeholder-Musik, Avatar-Basis | Spielbarer APK-Prototyp, Fun-Test |
| 2 – Meta (2–3 Monate) | Universum-Baumodus, Fortschritt, Teleportation, 100+ Level, Musik | Single-Player-Beta |
| 3 – Identität & P2P (3 Monate) | Schlüssel-Identität, Tor-Transport, DHT, Lobby mit 2–10 Spielern | Test-Lobby |
| 4 – I2P, Duelle, Raids (2–3 Monate) | I2P, asynchrone Duelle, Tausch, Events | Offene Beta |
| 5 – Launch & Live-Betrieb | F-Droid/Play, Community-Knoten, Content-Updates | 1.0 |

**Empfehlung:** Zuerst **Fun beweisen (Phase 1)**, erst danach das aufwendige Netzwerk bauen. Das Netzwerk darf Spaß nie blockieren: Das Spiel muss **offline voll spielbar** sein.

## 8. Risiken

| Risiko | Gegenmaßnahme |
|---|---|
| Tor/I2P zu langsam | Nur asynchrone Mechaniken; Cache; Direktmodus wählbar |
| Wenige Spieler → leere Lobby | Bots/NPC-Avatare, Offline-Lobby-Simulation, Events zur Bündelung |
| Missbrauch/Chat | Emotes first, lokale Blocklisten, Report-Signale in Gossip |
| Store-Ablehnung | Datenschutz-Doku, F-Droid-Alternative |
| Scope zu groß | Strikte Phasen, Single-Player zuerst |
| Cheating | Deterministische Level + Replay-Verifikation |

## 9. Offene Fragen an dich

1. Spielkern: Match-3 ok oder eher Runner/Idle/Aufbau?
2. Engine: Godot (Open Source) oder Unity?
3. Zielgruppe/Alter (beeinflusst Chat & Store-Einstufung)?
4. Monetarisierung: kostenlos, einmaliger Kauf, Spenden?
5. Team: allein oder mit Grafiker/Komponist?
6. Verteilung: Google Play, F-Droid oder beides?

# Oil Imperium 2.0 — Remake

Ein Remake der klassischen Wirtschaftssimulation **Oil Imperium**, gebaut mit **Godot 4.5**.
Du übernimmst 1970 eine kleine Ölfirma und bohrst, handelst und intrigierst dich durch vier
Jahrzehnte — von der Pionier-Ära der 1970er bis ins Internet-Zeitalter der 2000er.

## Features

- **Bohr-Minispiel**: Land- und Offshore-Bohrungen mit eigenem Spielablauf
- **Regionen & Karten**: 11 Regionen (Texas, Nordsee, Saudi-Arabien, Sibirien u. v. m.) mit eigenen Ansprüchen, Förderanlagen und Lagertanks
- **Handel**: Spot-Geschäfte, Lieferverträge mit namentlichen Kunden und Futures
- **Börsensystem**: Aktien kaufen/verkaufen, KI-Mitbewerber mit eigenen Firmenlogos
- **Ära-System**: Vier Epochen mit eigenem Büro, Computer-Look, Sound und Technikbaum
- **Büro-Upgrades**: Teures Haupt-Upgrade + Module pro Ära — alle Module schalten den Ära-Wechsel frei
- **Rechtssystem**: Behörden-Verfahren, Bestechung (mit Risiko!), Anwälte, Compliance-Investitionen, Mob-Gewalt
- **Sabotage & Lobbyarbeit**: Gegner ausschalten oder Politik für sich arbeiten lassen
- **OPEC & historische Krisen**: Ölpreise reagieren auf echte historische Ereignisse
- **OilNN-Nachrichten**: Zeitung (70er/80er), TV (90er) und Web-Portal (2000er)
- **Erfolge, Statistiken, Finanzberichte, Aktivitäts-Log, Tutorial**
- **Speichern/Laden** in mehreren Slots

## Starten

1. [Godot 4.5](https://godotengine.org/download) installieren (GL Compatibility wird genutzt, funktioniert also auch auf schwächerer Hardware)
2. Projekt über den Godot-Projektmanager importieren (`project.godot` auswählen)
3. **F5** drücken — Hauptszene ist `Opening.tscn`

## Steuerung (im Büro)

| Taste | Aktion |
|-------|--------|
| N | Nächster Tag |
| M | Karte / Regionen |
| C | Computer |
| S | Speichern |
| E | Monat beenden |
| T | Tutorial an/aus |
| A | Erfolge anzeigen |
| L | Aktivitäts-Log |
| F | Finanzbericht |
| R | Recht & Anwälte |
| $ | Kredite |
| 1–9 | Region schnell auswählen |
| H | Hilfe anzeigen |

## Projektstruktur

- `GameManager.gd` — zentrale Spiellogik als Autoload, instanziiert alle Sub-Systeme (Verträge, Börse, Recht, KI-Gegner, Zeitungen …)
- `EraManager.gd` / `OfficeUpgradeManager.gd` — Ära-Fortschritt und Büro-Upgrades
- `office.gd` / `computer.gd` — die beiden Haupt-Szenen (Büro mit Objekten, Computer mit Menüs)
- `assets/` — Grafiken, Sounds und Musik nach Ären sortiert

## Lizenz / Credits

Remake-Projekt zu Lernzwecken. „Oil Imperium" ist eine Marke von reware studios —
dieses Projekt steht in keiner Verbindung zu ihnen.

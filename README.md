# Oil Imperium 2.0 — Remake

Ein Remake der klassischen Wirtschaftssimulation **Oil Imperium**, gebaut mit **Godot 4.5**.
Du übernimmst 1970 eine kleine Ölfirma und bohrst, handelst und intrigierst dich durch vier
Jahrzehnte — von der Pionier-Ära der 1970er bis ins Internet-Zeitalter der 2000er.

## Features

- **Bohr-Minispiel**: Land- und Offshore-Bohrungen mit eigenem Spielablauf — wer selbst bohrt, spart 40 % und riskiert einen Blowout (10 % an Land / 18 % Offshore)
- **Regionen & Karten**: 11 Regionen (Texas, Nordsee, Saudi-Arabien, Sibirien u. v. m.) mit eigenen Ansprüchen, Förderanlagen und Lagertanks
- **Handel**: Spot-Geschäfte (1× pro Monat und Region), Lieferverträge mit namentlichen Kunden und Futures; beim Verkauf kann die Pipeline versagen — selbst reparieren (Minispiel) oder Notfall-Team für $150.000 rufen
- **Markt-System**: Öl-Qualität pro Region (Light Sweet +15 %, Heavy Sour −15 %), saisonale Nachfrage (Winter +12 %, Sommer +6 %) und monatliche Nachfrage-Limits in Krisenzeiten (Ölkrisen 1973/79, Golfkrieg 1990, Sommerloch)
- **Raffinerie & Pipeline-Netz**: Raffinierter Verkauf mit +40 % Preis (300k bbl/Monat) und ein dreistufiges eigenes Pipeline-Netz (+2 % Preis, −15 % Leitungsrisiko pro Stufe)
- **Börsensystem**: Aktien kaufen/verkaufen, KI-Mitbewerber mit eigenen Firmenlogos
- **Faire KI-Gegner**: Die KI zahlt dieselben Claim-, Bohr- und Tankkosten, bohrt genauso lange, respektiert Verkaufslimits und skaliert mit dem Schwierigkeitsgrad
- **Ära-System**: Vier Epochen mit eigenem Büro, Computer-Look, Sound und Technikbaum
- **Büro-Upgrades**: Teures Haupt-Upgrade + Module pro Ära — alle Module schalten den Ära-Wechsel frei
- **Rechtssystem**: Behörden-Verfahren, Bestechung (mit Risiko!), Anwälte, Compliance-Investitionen, Mob-Gewalt
- **Sabotage & Lobbyarbeit**: Gegner ausschalten oder Politik für sich arbeiten lassen
- **Feuer-Minigame wie 1988**: Ted Redhair löscht brennende Ölfelder per Dynamit — WASD/Pfeiltasten laufen, Leertaste sprengen; zu nah dran und Ted stirbt (Blowouts können brennende Felder auslösen)
- **OilNN-Nachrichten**: Zeitung (70er/80er), TV (90er) und Web-Portal (2000er)
- **Erfolge, Statistiken, Finanzberichte, Aktivitäts-Log, Tutorial**
- **Endauswertung & Hall of Fame**: Nach 30 Jahren Punkteverrechnung mit lokalem Top-10-Ranking
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
- `office.gd` / `computer.gd` — die beiden Haupt-Szenen (Büro mit Aktionsleiste, Computer mit Menüs)
- `FirefighterMiniGame.gd`, `PipelineClassic.gd`, `drilling_game.gd` — die Minispiele
- `AIController.gd` — KI-Gegner mit denselben Wirtschaftsregeln wie der Spieler
- `test_economy.gd`, `test_integration.gd`, `test_panels.gd` — Headless-Tests (`godot --headless --path . --script res://test_economy.gd`)
- `assets/` — Grafiken, Sounds und Musik nach Ären sortiert

## Lizenz / Credits

Remake-Projekt zu Lernzwecken. „Oil Imperium" ist eine Marke von reware studios —
dieses Projekt steht in keiner Verbindung zu ihnen.

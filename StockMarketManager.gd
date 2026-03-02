extends Node
# StockMarketManager.gd - Aktienhandel mit KI-Gegner-Firmen
# KI-Gegner waehlen aus demselben Firmenpool wie der Spieler

signal company_goes_public(company_id: String)
signal shareholders_meeting_convened(year: int)
signal proposal_voted(proposal_id: String, passed: bool)
signal dividend_declared(amount: float)
signal shares_sold(capital_raised: float)
signal shares_bought(competitor_id: String, shares: int)
signal takeover_attempt(competitor_id: String, player_ownership: float)

# ==============================================================================
# AKTIENGESELLSCHAFT STATUS (Spieler)
# ==============================================================================

var is_stock_corporation: bool = false
var ag_conversion_year: int = 0
var ag_conversion_cost: float = 10000000.0

# Spieler-Anteile an KI-Firmen
var competitor_shareholdings: Dictionary = {}  # { "comp_id": { "shares": int } }

# Aktionaere des Spielers (wenn AG)
var shareholders: Dictionary = {}
var total_player_shares: int = 1000
var player_share_price: float = 5000.0  # $5000 pro Aktie

# ==============================================================================
# HAUPTVERSAMMLUNG
# ==============================================================================

const SHAREHOLDER_TYPES = {
        "institutional": {
                "name_pool": ["Deutsche Investment", "Global Capital", "Nordbank Vermoegen", "Alpenfonds"],
                "priorities": ["dividend", "growth"],
                "voting_style": "pragmatic"
        },
        "family_office": {
                "name_pool": ["Familie von Bergmann", "Erben Consortium", "Stiftung Hoffmann"],
                "priorities": ["stability", "dividend"],
                "voting_style": "conservative"
        },
        "pension_fund": {
                "name_pool": ["Pensionskasse Nord", "Ruhestandfonds", "Versorgungswerk"],
                "priorities": ["stability", "dividend"],
                "voting_style": "cautious"
        },
        "strategic_investor": {
                "name_pool": ["Strategic Holdings", "Industrial Partners", "Energy Ventures"],
                "priorities": ["growth", "influence"],
                "voting_style": "aggressive"
        }
}

const PROPOSAL_TYPES = {
        "dividend_high": {
                "title": "Hohe Dividendenausschuettung (60%)",
                "effect": {"dividend_payout": 0.6},
                "supporters": ["institutional", "family_office"]
        },
        "dividend_moderate": {
                "title": "Moderate Dividende (40%)",
                "effect": {"dividend_payout": 0.4},
                "supporters": ["pension_fund"]
        },
        "dividend_low": {
                "title": "Niedrige Dividende (20%)",
                "effect": {"dividend_payout": 0.2},
                "supporters": ["strategic_investor"]
        },
        "expansion_capital": {
                "title": "Expansionskapital freigeben",
                "effect": {"expansion_budget": 5000000},
                "supporters": ["strategic_investor"]
        },
        "cost_cutting": {
                "title": "Kostenreduzierung",
                "effect": {"admin_cost_modifier": 0.85},
                "supporters": ["institutional", "pension_fund"]
        },
        # Zusatzantraege von Grossaktionaeren (>25%)
        "management_change": {
                "title": "Management-Umbesetzung",
                "effect": {"admin_cost_modifier": 0.90, "production_boost": 1.05},
                "supporters": ["strategic_investor"],
                "requires_major_shareholder": true
        },
        "sell_non_core_assets": {
                "title": "Nicht-kern Assets verkaufen",
                "effect": {"immediate_cash": 2000000},
                "supporters": ["institutional", "family_office"],
                "requires_major_shareholder": true
        },
        "strategic_partnership": {
                "title": "Strategische Partnerschaft eingehen",
                "effect": {"price_bonus": 0.10, "reputation_boost": 5},
                "supporters": ["strategic_investor"],
                "requires_major_shareholder": true
        },
        "ipo_spinoff": {
                "title": "Tochtergesellschaft ausgliedern",
                "effect": {"immediate_cash": 5000000, "focus_modifier": 1.1},
                "supporters": ["institutional"],
                "requires_major_shareholder": true
        },
        "risk_reduction": {
                "title": "Risikominimierung durch Diversifikation",
                "effect": {"stability_bonus": 0.15, "insurance_cost": -50000},
                "supporters": ["pension_fund", "family_office"],
                "requires_major_shareholder": true
        }
}

# ==============================================================================
# STATE
# ==============================================================================

var game_manager = null
var pending_meeting: bool = false
var meeting_proposals: Array = []
var meeting_year: int = 0
var major_shareholder_options: Dictionary = {}
var last_dividend_amount: float = 0.0
var dividend_history: Array = []

# Boersenereignisse
var market_events_triggered: Array = []

const MARKET_EVENTS = [
        {"year": 1973, "month": 10, "severity": 0.25, "name": "Oelkrise"},
        {"year": 1979, "month": 1, "severity": 0.15, "name": "Iranische Revolution"},
        {"year": 1987, "month": 10, "severity": 0.35, "name": "Schwarzer Montag"},
        {"year": 1990, "month": 8, "severity": 0.18, "name": "Golfkrieg"},
        {"year": 1997, "month": 7, "severity": 0.20, "name": "Asienkrise"},
        {"year": 2000, "month": 3, "severity": 0.30, "name": "Dotcom-Blase"}
]

func _ready():
        await get_tree().create_timer(0.5).timeout
        if has_node("/root/GameManager"):
                game_manager = get_node("/root/GameManager")

# ==============================================================================
# AG-WERDUNG
# ==============================================================================

func can_become_ag() -> Dictionary:
        if game_manager == null:
                return {"can_convert": false, "reason": "Systemfehler"}

        if is_stock_corporation:
                return {"can_convert": false, "reason": "Bereits eine AG"}

        if game_manager.cash < ag_conversion_cost:
                return {"can_convert": false, "reason": "Nicht genug Kapital (Benötigt: $%d)" % ag_conversion_cost}

        if game_manager.date["year"] < 1975:
                return {"can_convert": false, "reason": "AG-Umwandlung erst ab 1975 moeglich"}

        return {
                "can_convert": true,
                "cost": ag_conversion_cost * game_manager.inflation_rate,
                "reason": "AG-Umwandlung moeglich!"
        }

func become_stock_corporation() -> bool:
        var check = can_become_ag()
        if not check["can_convert"]:
                return false

        var cost = check["cost"]
        game_manager.cash -= cost
        game_manager.book_transaction("Global", -cost, "AG-Umwandlung")

        is_stock_corporation = true
        ag_conversion_year = game_manager.date["year"]

        # Unternehmenswert berechnen
        _calculate_player_share_price()

        # Initiale Aktionaere
        _generate_initial_shareholders()

        company_goes_public.emit("player")

        if game_manager.newspaper_manager:
                game_manager.newspaper_manager.add_headline({
                        "title": "BOERSENGANG",
                        "text": "%s wird zur Aktiengesellschaft!" % game_manager.company_name,
                        "urgent": false
                })

        return true

func _calculate_player_share_price():
        # Basierend auf Cash, Assets und Marktposition
        var value = game_manager.cash

        # Tank-Wert
        for region in game_manager.tank_capacity:
                value += game_manager.tank_capacity[region] * 3.0

        # Bohrungen
        for region_name in game_manager.regions:
                var region = game_manager.regions[region_name]
                if region.get("unlocked", false):
                        for claim in region.get("claims", []):
                                if claim.get("owned", false) and claim.get("has_oil", false):
                                        value += claim.get("reserves_remaining", 0) * game_manager.oil_price * 0.5

        player_share_price = max(1000.0, value / total_player_shares)

func _generate_initial_shareholders():
        shareholders.clear()

        # Spieler behaelt 51%
        shareholders["player"] = {
                "name": game_manager.player_name + " (Gruender)",
                "shares": int(total_player_shares * 0.51),
                "type": "founder"
        }

        # Rest an 3 Investoren
        var remaining = total_player_shares - shareholders["player"]["shares"]
        var types = SHAREHOLDER_TYPES.keys()

        for i in range(3):
                var type = types[i % types.size()]
                var shares = int(remaining * (0.25 + randf() * 0.1))

                shareholders["investor_%d" % i] = {
                        "name": SHAREHOLDER_TYPES[type]["name_pool"].pick_random(),
                        "shares": shares,
                        "type": type
                }

# ==============================================================================
# KAPITALBESCHAFFUNG DURCH AKTIENVERKAUF
# ==============================================================================

func can_sell_player_shares(amount: int) -> Dictionary:
        if game_manager == null:
                return {"can_sell": false, "reason": "Systemfehler"}

        if not is_stock_corporation:
                return {"can_sell": false, "reason": "Nur als AG moeglich"}

        if amount <= 0:
                return {"can_sell": false, "reason": "Ungueltige Menge"}

        # Pruefen ob Spieler genug Aktien hat
        var player_shares = shareholders.get("player", {}).get("shares", 0)
        if amount > player_shares * 0.49:  # Max 49% verkaufen, Kontrolle behalten
                return {"can_sell": false, "reason": "Maximal 49% kann verkauft werden (Kontrollmehrheit)"}

        var value = amount * player_share_price * game_manager.inflation_rate

        return {
                "can_sell": true,
                "shares": amount,
                "value": value,
                "price_per_share": player_share_price * game_manager.inflation_rate,
                "dilution_percent": float(amount) / total_player_shares * 100.0
        }

func sell_player_shares(amount: int) -> Dictionary:
        var check = can_sell_player_shares(amount)
        if not check["can_sell"]:
                return check

        var value = check["value"]

        # Kapital erhalten
        game_manager.cash += value
        game_manager.book_transaction("Global", value, "Aktienemission")

        # Neue Aktien erstellen (Verduennung)
        total_player_shares += amount

        # Neuen Aktionaer hinzufuegen (anonyme Marktteilnehmer)
        var buyer_type = SHAREHOLDER_TYPES.keys().pick_random()
        shareholders["market_%d" % randi()] = {
                "name": SHAREHOLDER_TYPES[buyer_type]["name_pool"].pick_random(),
                "shares": amount,
                "type": buyer_type
        }

        # Preis neu berechnen
        _calculate_player_share_price()

        shares_sold.emit(value)

        return {
                "success": true,
                "capital_raised": value,
                "new_total_shares": total_player_shares
        }

# ==============================================================================
# AKTIENKAUF VON KI-GEGNERN
# ==============================================================================

func can_buy_competitor_shares(competitor_id: String, amount: int) -> Dictionary:
        if game_manager == null:
                return {"can_buy": false, "reason": "Systemfehler"}

        if game_manager.ai_competitor_manager == null:
                return {"can_buy": false, "reason": "Keine KI-Gegner aktiv"}

        var competitor = game_manager.ai_competitor_manager.competitors.get(competitor_id)
        if competitor == null or competitor.get("bankrupt", false):
                return {"can_buy": false, "reason": "Unternehmen nicht verfuegbar"}

        if amount > competitor.get("shares_available", 0):
                return {"can_buy": false, "reason": "Nicht genug Aktien verfuegbar"}

        var price = competitor.get("share_price", 10000) * game_manager.inflation_rate
        var cost = amount * price

        if game_manager.cash < cost:
                return {"can_buy": false, "reason": "Nicht genug Kapital ($%d)" % cost}

        return {
                "can_buy": true,
                "cost": cost,
                "price_per_share": price,
                "current_ownership": _get_player_ownership(competitor_id),
                "after_ownership": _get_player_ownership_after(competitor_id, amount)
        }

func buy_competitor_shares(competitor_id: String, amount: int) -> Dictionary:
        var check = can_buy_competitor_shares(competitor_id, amount)
        if not check["can_buy"]:
                return check

        var competitor = game_manager.ai_competitor_manager.competitors[competitor_id]
        var cost = check["cost"]

        game_manager.cash -= cost
        game_manager.book_transaction("Global", -cost, "Aktienkauf: " + competitor["company"])

        # Portfolio aktualisieren
        if not competitor_shareholdings.has(competitor_id):
                competitor_shareholdings[competitor_id] = {"shares": 0}

        competitor_shareholdings[competitor_id]["shares"] += amount
        competitor["shares_available"] -= amount

        var ownership = _get_player_ownership(competitor_id)

        shares_bought.emit(competitor_id, amount)

        # Uebernahmewarnung bei >25%
        if ownership >= 25.0:
                takeover_attempt.emit(competitor_id, ownership)

        return {
                "success": true,
                "shares_bought": amount,
                "cost": cost,
                "ownership_percent": ownership,
                "is_majority": ownership >= 25.0
        }

func _get_player_ownership(competitor_id: String) -> float:
        if not competitor_shareholdings.has(competitor_id):
                return 0.0

        var competitor = game_manager.ai_competitor_manager.competitors.get(competitor_id, {})
        var total = competitor.get("shares_total", 500)
        var owned = competitor_shareholdings[competitor_id].get("shares", 0)

        return float(owned) / float(total) * 100.0

func _get_player_ownership_after(competitor_id: String, additional: int) -> float:
        var competitor = game_manager.ai_competitor_manager.competitors.get(competitor_id, {})
        var total = competitor.get("shares_total", 500)
        var owned = competitor_shareholdings.get(competitor_id, {}).get("shares", 0) + additional

        return float(owned) / float(total) * 100.0

# ==============================================================================
# FEINDLICHE UEBERNAHME
# ==============================================================================

func can_hostile_takeover(competitor_id: String) -> Dictionary:
        var ownership = _get_player_ownership(competitor_id)

        if ownership < 25.0:
                return {"can_takeover": false, "reason": "Mind. 25% Anteil erforderlich"}

        var competitor = game_manager.ai_competitor_manager.competitors.get(competitor_id, {})
        if competitor.get("bankrupt", false):
                return {"can_takeover": false, "reason": "Unternehmen bereits bankrott"}

        # Kosten basierend auf verbleibenden Aktien
        var remaining_shares = competitor.get("shares_total", 500) - competitor_shareholdings.get(competitor_id, {}).get("shares", 0)
        var price = competitor.get("share_price", 10000) * game_manager.inflation_rate
        var premium = 1.3  # 30% Aufschlag
        var cost = remaining_shares * price * premium

        if game_manager.cash < cost:
                return {"can_takeover": false, "reason": "Nicht genug Kapital ($%d)" % cost}

        return {
                "can_takeover": true,
                "cost": cost,
                "ownership": ownership,
                "competitor_cash": competitor.get("cash", 0)
        }

func execute_hostile_takeover(competitor_id: String) -> Dictionary:
        var check = can_hostile_takeover(competitor_id)
        if not check["can_takeover"]:
                return check

        var competitor = game_manager.ai_competitor_manager.competitors[competitor_id]
        var cost = check["cost"]

        # Kapital ueberweisen
        game_manager.cash -= cost
        game_manager.book_transaction("Global", -cost, "Feindliche Uebernahme: " + competitor["company"])

        # Konkurrent uebernehmen
        var competitor_cash = competitor.get("cash", 0)
        game_manager.cash += competitor_cash
        game_manager.book_transaction("Global", competitor_cash, "Uebernahme: Cash")

        # Alle Aktien erhalten
        competitor_shareholdings[competitor_id] = {"shares": competitor["shares_total"]}
        competitor["bankrupt"] = true
        competitor["taken_over_by"] = "player"

        # KI-Manager benachrichtigen
        game_manager.ai_competitor_manager.competitor_bankrupt.emit(competitor_id)

        return {
                "success": true,
                "company": competitor["company"],
                "acquired_cash": competitor_cash,
                "total_cost": cost
        }

# ==============================================================================
# HAUPTVERSAMMLUNG
# ==============================================================================

func convene_shareholders_meeting() -> bool:
        if not is_stock_corporation or pending_meeting:
                return false

        meeting_year = game_manager.date["year"]
        pending_meeting = true

        _generate_meeting_proposals()
        _identify_major_shareholders()

        shareholders_meeting_convened.emit(meeting_year)
        return true

func _generate_meeting_proposals():
        meeting_proposals.clear()

        # Dividenden-Vorschlag basierend auf Gewinn
        var last_profit = 0.0
        if game_manager.history_profit.size() > 0:
                last_profit = game_manager.history_profit[-1]

        if last_profit > 5000000:
                meeting_proposals.append(PROPOSAL_TYPES["dividend_high"].duplicate())
        elif last_profit > 1000000:
                meeting_proposals.append(PROPOSAL_TYPES["dividend_moderate"].duplicate())
        else:
                meeting_proposals.append(PROPOSAL_TYPES["dividend_low"].duplicate())

        # Zusaetzliche Vorschlaege
        if game_manager.cash > 10000000:
                meeting_proposals.append(PROPOSAL_TYPES["expansion_capital"].duplicate())

        meeting_proposals.append(PROPOSAL_TYPES["cost_cutting"].duplicate())

func _identify_major_shareholders():
        major_shareholder_options.clear()

        for holder_id in shareholders:
                if holder_id == "player":
                        continue

                var holder = shareholders[holder_id]
                var ownership = float(holder["shares"]) / total_player_shares

                if ownership > 0.10:  # >10% ist relevant
                        major_shareholder_options[holder_id] = {
                                "holder": holder,
                                "ownership": ownership * 100.0
                        }

                        # Grossaktionaer >25% kann zusaetzliche Antraege stellen
                        if ownership > 0.25:
                                _generate_major_shareholder_proposal(holder_id, holder)

func _generate_major_shareholder_proposal(holder_id: String, holder: Dictionary):
        # Grossaktionaer schlaegt passenden Antrag vor basierend auf Typ
        var holder_type = holder.get("type", "institutional")

        # Verfuegbare Antraege fuer diesen Aktionaerstyp
        var available_proposals = []
        for proposal_key in PROPOSAL_TYPES:
                var proposal = PROPOSAL_TYPES[proposal_key]
                if proposal.get("requires_major_shareholder", false):
                        if holder_type in proposal.get("supporters", []):
                                available_proposals.append(proposal_key)

        # Zufaelligen passenden Antrag auswaehlen
        if available_proposals.size() > 0:
                var chosen_key = available_proposals.pick_random()
                var new_proposal = PROPOSAL_TYPES[chosen_key].duplicate()
                new_proposal["proposed_by"] = holder.get("name", "Unbekannt")
                new_proposal["proposer_id"] = holder_id

                # Pruefen ob Antrag schon existiert
                var already_exists = false
                for existing in meeting_proposals:
                        if existing.get("title") == new_proposal["title"]:
                                already_exists = true
                                break

                if not already_exists:
                        meeting_proposals.append(new_proposal)
                        print("[HV] Grossaktionaer %s stellt Antrag: %s" % [holder.get("name", "?"), new_proposal["title"]])

func vote_on_proposal(proposal_index: int, support: bool) -> Dictionary:
        if proposal_index < 0 or proposal_index >= meeting_proposals.size():
                return {"success": false}

        var proposal = meeting_proposals[proposal_index]
        var player_shares = shareholders.get("player", {}).get("shares", 0)

        if support:
                proposal["votes_for"] = proposal.get("votes_for", 0) + player_shares
        else:
                proposal["votes_against"] = proposal.get("votes_against", 0) + player_shares

        return {"success": true, "proposal": proposal["title"]}

func simulate_shareholder_voting():
        for holder_id in shareholders:
                if holder_id == "player":
                        continue

                var holder = shareholders[holder_id]
                var shares = holder["shares"]
                var holder_type = holder.get("type", "institutional")
                var type_data = SHAREHOLDER_TYPES.get(holder_type, SHAREHOLDER_TYPES["institutional"])

                for proposal in meeting_proposals:
                        var support_chance = 0.5

                        # Typ-abhaengige Abstimmung
                        if holder_type in proposal.get("supporters", []):
                                support_chance = 0.8

                        if randf() < support_chance:
                                proposal["votes_for"] = proposal.get("votes_for", 0) + shares
                        else:
                                proposal["votes_against"] = proposal.get("votes_against", 0) + shares

func execute_meeting_results() -> Dictionary:
        var results = {"passed": [], "rejected": []}

        for proposal in meeting_proposals:
                var total = proposal.get("votes_for", 0) + proposal.get("votes_against", 0)
                var passed = proposal.get("votes_for", 0) > total * 0.5

                if passed:
                        results["passed"].append(proposal["title"])
                        _apply_proposal_effect(proposal)
                        proposal_voted.emit(proposal.get("id", ""), true)
                else:
                        results["rejected"].append(proposal["title"])
                        proposal_voted.emit(proposal.get("id", ""), false)

        pending_meeting = false
        meeting_proposals.clear()

        return results

func _apply_proposal_effect(proposal: Dictionary):
        var effect = proposal.get("effect", {})

        if effect.has("dividend_payout"):
                _declare_dividend(effect["dividend_payout"])

        if effect.has("expansion_budget"):
                game_manager.set_meta("expansion_budget", effect["expansion_budget"])

        if effect.has("admin_cost_modifier"):
                game_manager.global_cost_multiplier *= effect["admin_cost_modifier"]

        # Neue Effekte fuer Grossaktionaer-Antraege
        if effect.has("production_boost"):
                game_manager.tech_bonus_production *= effect["production_boost"]

        if effect.has("immediate_cash"):
                var cash_amount = effect["immediate_cash"] * game_manager.inflation_rate
                game_manager.cash += cash_amount
                game_manager.book_transaction("Global", cash_amount, "Asset-Verkauf")

        if effect.has("price_bonus"):
                game_manager.price_multiplier *= (1.0 + effect["price_bonus"])

        if effect.has("reputation_boost"):
                # Reputation kann in Zusammenhang mit anderen Systemen stehen
                if game_manager.achievement_manager:
                        game_manager.achievement_manager.add_reputation(effect["reputation_boost"])

        if effect.has("stability_bonus"):
                # Stabilitaet reduziert zufaellige Ereignis-Wahrscheinlichkeit
                game_manager.set_meta("stability_bonus", effect["stability_bonus"])

        if effect.has("insurance_cost"):
                # Monatliche Ersparnis
                game_manager.set_meta("monthly_insurance_saving", effect["insurance_cost"])

        if effect.has("focus_modifier"):
                # Fokus-Verbesserung fuer Kerngeschaeft
                game_manager.tech_bonus_oil_price *= effect["focus_modifier"]

func _declare_dividend(payout_rate: float):
        if game_manager.history_profit.is_empty():
                return

        var last_profit = game_manager.history_profit[-1]
        var total_dividend = last_profit * payout_rate

        # An alle Aktionaere verteilen
        var player_shares = shareholders.get("player", {}).get("shares", 0)
        var player_dividend = total_dividend * (float(player_shares) / total_player_shares)

        if player_dividend > 0:
                game_manager.cash += player_dividend
                game_manager.book_transaction("Global", player_dividend, "Dividende")

        last_dividend_amount = player_dividend
        dividend_history.append({
                "year": game_manager.date["year"],
                "amount": player_dividend,
                "rate": payout_rate
        })

        dividend_declared.emit(player_dividend)

# ==============================================================================
# MONATLICHE VERARBEITUNG
# ==============================================================================

func process_monthly():
        if game_manager == null:
                return

        var month = game_manager.date["month"]
        var year = game_manager.date["year"]

        # Spieler-Aktienpreis aktualisieren
        if is_stock_corporation:
                _calculate_player_share_price()
                _fluctuate_share_price()

        # Dividenden von Beteiligungen (quartalsweise)
        if month in [3, 6, 9, 12]:
                _receive_portfolio_dividends()

        # Hauptversammlung vorbereiten (Dezember)
        if is_stock_corporation and month == 12:
                convene_shareholders_meeting()

        # Boersenereignisse
        _check_market_events(year, month)

func _fluctuate_share_price():
        var change = randfn(0.0, 0.02)
        player_share_price *= (1.0 + change)
        player_share_price = max(500.0, player_share_price)

func _receive_portfolio_dividends():
        var total = 0.0

        for competitor_id in competitor_shareholdings:
                var shares = competitor_shareholdings[competitor_id]["shares"]
                var competitor = game_manager.ai_competitor_manager.competitors.get(competitor_id, {})

                if competitor.get("bankrupt", false):
                        continue

                var share_price = competitor.get("share_price", 10000)
                var dividend_yield = 0.04  # 4% jaehrlich

                # Quartalsdividende
                var dividend = shares * share_price * (dividend_yield / 4.0)
                total += dividend

        if total > 0:
                game_manager.cash += total
                game_manager.book_transaction("Global", total, "Portfolio-Dividenden")

func _check_market_events(year: int, month: int):
        for event in MARKET_EVENTS:
                if event["year"] == year and event["month"] == month:
                        if event not in market_events_triggered:
                                _apply_market_crash(event["severity"])
                                market_events_triggered.append(event)

func _apply_market_crash(severity: float):
        # Alle Aktienpreise fallen
        player_share_price *= (1.0 - severity * 0.5)

        # KI-Aktien auch
        if game_manager.ai_competitor_manager:
                for comp_id in game_manager.ai_competitor_manager.competitors:
                        var comp = game_manager.ai_competitor_manager.competitors[comp_id]
                        if not comp.get("bankrupt", false):
                                comp["share_price"] *= (1.0 - randf_range(severity * 0.3, severity * 0.7))

# ==============================================================================
# GETTERS
# ==============================================================================

func get_competitor_shares_info(competitor_id: String) -> Dictionary:
        var competitor = game_manager.ai_competitor_manager.competitors.get(competitor_id, {})
        var holding = competitor_shareholdings.get(competitor_id, {"shares": 0})

        return {
                "company": competitor.get("company", "Unbekannt"),
                "logo": competitor.get("logo", ""),
                "shares_owned": holding["shares"],
                "shares_total": competitor.get("shares_total", 500),
                "ownership_percent": _get_player_ownership(competitor_id),
                "share_price": competitor.get("share_price", 10000) * game_manager.inflation_rate,
                "available_shares": competitor.get("shares_available", 0),
                "bankrupt": competitor.get("bankrupt", false)
        }

func get_all_competitor_stocks() -> Array:
        var result = []

        if game_manager == null or game_manager.ai_competitor_manager == null:
                return result

        for comp_id in game_manager.ai_competitor_manager.competitors:
                result.append(get_competitor_shares_info(comp_id))

        return result

func get_ag_status() -> Dictionary:
        return {
                "is_ag": is_stock_corporation,
                "conversion_year": ag_conversion_year,
                "total_shares": total_player_shares,
                "player_shares": shareholders.get("player", {}).get("shares", 0),
                "player_control": float(shareholders.get("player", {}).get("shares", 0)) / total_player_shares * 100.0,
                "share_price": player_share_price * game_manager.inflation_rate,
                "market_cap": player_share_price * total_player_shares
        }

func get_portfolio_value() -> float:
        var total = 0.0

        for competitor_id in competitor_shareholdings:
                var info = get_competitor_shares_info(competitor_id)
                total += info["shares_owned"] * info["share_price"]

        return total

# ==============================================================================
# SAVE/LOAD
# ==============================================================================

func get_save_data() -> Dictionary:
        return {
                "is_stock_corporation": is_stock_corporation,
                "ag_conversion_year": ag_conversion_year,
                "competitor_shareholdings": competitor_shareholdings,
                "shareholders": shareholders,
                "total_player_shares": total_player_shares,
                "player_share_price": player_share_price,
                "last_dividend": last_dividend_amount,
                "dividend_history": dividend_history,
                "market_events_triggered": market_events_triggered
        }

func load_save_data(data: Dictionary):
        is_stock_corporation = data.get("is_stock_corporation", false)
        ag_conversion_year = data.get("ag_conversion_year", 0)
        competitor_shareholdings = data.get("competitor_shareholdings", {})
        shareholders = data.get("shareholders", {})
        total_player_shares = data.get("total_player_shares", 1000)
        player_share_price = data.get("player_share_price", 5000.0)
        last_dividend_amount = data.get("last_dividend", 0.0)
        dividend_history = data.get("dividend_history", [])
        market_events_triggered = data.get("market_events_triggered", [])

extends Node
# AICompetitorManager.gd - KI-Gegner die aus dem Firmenpool waehlen

signal competitor_action(competitor_id: String, action: String, details: Dictionary)
signal cartel_formed(partners: Array)
signal cartel_discovered(partners: Array, penalty: float)
signal competitor_bankrupt(competitor_id: String)
# signal hostile_takeover_attempt(attacker: String, target: String)  # Reserved for future use

# ==============================================================================
# KI-GEGNER PERSOENLICHKEITEN (ohne fixe Firmen)
# ==============================================================================

const PERSONALITIES = {
        "aggressive": {
                "name_pool": ["Viktor Volkov", "Boris Kazakov", "Ivan Petrov"],
                "nationality": "Russian",
                "description": "Rücksichtslos. Gewinne um jeden Preis.",
                "strategy": {"expansion": 0.9, "risk_taking": 0.85, "sabotage": 0.7, "cartel": 0.8},
                "starting_cash": 8000000,
                "bonus": {"sabotage_success": 1.2},
                "weakness": {"reputation_loss": 1.5},
                "quotes": ["Wer zoegert, verliert.", "Ihr Oel... es sieht besser aus in meinen Tanks."]
        },
        "conservative": {
                "name_pool": ["Margaret Sterling", "Charles Wentworth", "Elizabeth Howard"],
                "nationality": "British",
                "description": "Altes Geld. Konservative Strategie.",
                "strategy": {"expansion": 0.4, "risk_taking": 0.2, "sabotage": 0.1, "cartel": 0.3},
                "starting_cash": 15000000,
                "bonus": {"reputation": 1.2},
                "weakness": {"adaptation_speed": 0.7},
                "quotes": ["Wir bauen nachhaltig auf.", "Geduld ist eine Tugend."]
        },
        "efficient": {
                "name_pool": ["Hans Doerfler", "Klaus Brenner", "Wolfgang Schmidt"],
                "nationality": "German",
                "description": "Effizienz-Optimierer. Jede Bohrung wird berechnet.",
                "strategy": {"expansion": 0.6, "risk_taking": 0.3, "sabotage": 0.2, "cartel": 0.5},
                "starting_cash": 10000000,
                "bonus": {"production_efficiency": 1.25},
                "weakness": {"innovation": 0.8},
                "quotes": ["Effizienz ist keine Option, sie ist eine Pflicht.", "Ich habe die Zahlen analysiert."]
        },
        "connected": {
                "name_pool": ["Ahmed Al-Rashid", "Omar Bin-Salman", "Faisal Al-Harbi"],
                "nationality": "Saudi",
                "description": "Beste OPEC-Verbindungen.",
                "strategy": {"expansion": 0.7, "risk_taking": 0.5, "sabotage": 0.3, "cartel": 0.9},
                "starting_cash": 20000000,
                "bonus": {"opec_influence": 1.5},
                "weakness": {"reputation_in_west": 0.8},
                "quotes": ["Meine Familie kennt jeden in OPEC.", "Ein Anruf, und die Preise steigen."]
        },
        "innovative": {
                "name_pool": ["Sarah Chen", "Michael Torres", "Jennifer Walsh"],
                "nationality": "American",
                "description": "Technologie-Fokus. Fracking-Pionier.",
                "strategy": {"expansion": 0.8, "risk_taking": 0.6, "sabotage": 0.15, "cartel": 0.4},
                "starting_cash": 12000000,
                "bonus": {"tech_speed": 1.4},
                "weakness": {"traditional_methods": 0.8},
                "quotes": ["Technologie ist der wahre Wettbewerbsvorteil.", "Daten sind das neue Oel."]
        }
}

# Kartell-Risiko-Faktoren
const CARTEL_RISK = {
        "detection_base": 0.05,
        "detection_per_partner": 0.02,
        "penalty_base": 10000000,
        "price_bonus": 0.15
}

# ==============================================================================
# STATE
# ==============================================================================

var game_manager = null
var competitors: Dictionary = {}
var active_cartels: Array = []
var player_relations: Dictionary = {}
var pending_offers: Array = []
var used_company_indices: Array = []  # Welche Firmen-Indices schon vergeben sind

func _ready():
        await get_tree().create_timer(0.5).timeout
        if has_node("/root/GameManager"):
                game_manager = get_node("/root/GameManager")
        _initialize_competitors()

func _initialize_competitors():
        if game_manager == null or game_manager.GameData == null:
                return

        var companies = game_manager.GameData.COMPANIES
        var personalities = PERSONALITIES.keys()

        # Spieler-Firma aus dem Pool entfernen
        var _player_company_idx = -1
        for i in range(companies.size()):
                if companies[i]["name"] == game_manager.company_name:
                        _player_company_idx = i
                        used_company_indices.append(i)
                        break

        # KI-Gegner erstellen (3-4 Gegner)
        var num_competitors = min(4, companies.size() - 1)
        var personality_idx = 0

        for i in range(num_competitors):
                # Naechste verfuegbare Firma finden
                var company_idx = -1
                for j in range(companies.size()):
                        if j not in used_company_indices:
                                company_idx = j
                                break

                if company_idx == -1:
                        break

                used_company_indices.append(company_idx)
                var company = companies[company_idx]

                # Persoenlichkeit zuweisen
                var personality_key = personalities[personality_idx % personalities.size()]
                var personality = PERSONALITIES[personality_key]
                personality_idx += 1

                # Zufaelligen Namen aus Pool waehlen
                var person_name = personality["name_pool"].pick_random()

                # Competitor erstellen
                var comp_id = "comp_%d" % i
                competitors[comp_id] = {
                        "id": comp_id,
                        "name": person_name,
                        "company": company["name"],
                        "logo": company["logo"],
                        "company_idx": company_idx,
                        "nationality": personality["nationality"],
                        "personality": personality_key,
                        "description": personality["description"],
                        "strategy": personality["strategy"],
                        "cash": personality["starting_cash"],
                        "regions": [],
                        "bankrupt": false,
                        "reputation": 50,
                        "shares_total": 500,  # Fuer Aktien-System
                        "shares_available": 500,
                        "share_price": personality["starting_cash"] / 500.0
                }

                player_relations[comp_id] = 0

                print("[KI] %s leitet %s (%s)" % [name, company["name"], personality_key])

# ==============================================================================
# MONTHLY PROCESSING
# ==============================================================================

func process_monthly():
        if game_manager == null:
                return
        
        for comp_id in competitors:
                var comp = competitors[comp_id]
                if comp["bankrupt"]:
                        continue
                _process_competitor_ai(comp)
        
        _check_cartel_risks()
        _generate_offers()

func _process_competitor_ai(comp: Dictionary):
        var personality = PERSONALITIES[comp["personality"]]
        var strategy = personality["strategy"]

        # Expansion
        if randf() < strategy["expansion"] * 0.1:
                if comp["cash"] > 500000:
                        comp["cash"] -= 300000
                        comp["regions"].append("expansion_%d" % randi())
                        competitor_action.emit(comp["id"], "expansion", {})

        # Sabotage against player
        if randf() < strategy["sabotage"] * 0.03:
                competitor_action.emit(comp["id"], "sabotage", {"target": "player"})

        # Aktienpreis aktualisieren
        _update_competitor_share_price(comp)

func _update_competitor_share_price(comp: Dictionary):
        if comp["bankrupt"]:
                return

        # Preis basierend auf Cash und Marktentwicklung
        var oil_factor = 1.0
        if game_manager:
                oil_factor = game_manager.oil_price / 20.0

        var change = randfn(0.0, 0.03)
        if comp["regions"].size() > 0:
                change += 0.01  # Positive Entwicklung bei Expansion

        # Oelpreis-Einfluss einbeziehen
        comp["share_price"] *= (1.0 + change) * (0.95 + oil_factor * 0.1)
        comp["share_price"] = max(1000, comp["share_price"])  # Mindestpreis

func _check_cartel_risks():
        for i in range(active_cartels.size() - 1, -1, -1):
                var cartel = active_cartels[i]
                cartel["detection_risk"] += 0.01

                if randf() < cartel["detection_risk"]:
                        var penalty = CARTEL_RISK["penalty_base"] * (1 + cartel["partners"].size() * 0.5)
                        game_manager.cash -= penalty
                        game_manager.book_transaction("Global", -penalty, "Kartell-Strafe")

                        cartel_discovered.emit(cartel["partners"], penalty)
                        active_cartels.remove_at(i)
                else:
                        game_manager.price_multiplier *= (1.0 + CARTEL_RISK["price_bonus"])
                        cartel["duration_left"] -= 1
                        if cartel["duration_left"] <= 0:
                                active_cartels.remove_at(i)

func _generate_offers():
        if active_cartels.size() > 0:
                return

        if randf() < 0.05:
                var available = []
                for comp_id in competitors:
                        if not competitors[comp_id]["bankrupt"] and player_relations[comp_id] > 10:
                                available.append(comp_id)

                if available.size() > 0:
                        var comp = competitors[available.pick_random()]
                        pending_offers.append({
                                "id": randi(),
                                "competitor_id": comp["id"],
                                "competitor_name": comp["name"],
                                "price_bonus": randi_range(10, 25),
                                "duration": randi_range(6, 24),
                                "quote": PERSONALITIES[comp["personality"]]["quotes"].pick_random()
                        })

# ==============================================================================
# CARTEL FUNCTIONS
# ==============================================================================

func accept_cartel(offer_id: int) -> bool:
        for i in range(pending_offers.size()):
                if pending_offers[i]["id"] == offer_id:
                        var offer = pending_offers[i]
                        active_cartels.append({
                                "partners": [offer["competitor_id"], "player"],
                                "price_bonus": offer["price_bonus"] / 100.0,
                                "duration_left": offer["duration"],
                                "detection_risk": CARTEL_RISK["detection_base"]
                        })
                        player_relations[offer["competitor_id"]] += 30
                        pending_offers.remove_at(i)
                        cartel_formed.emit([offer["competitor_name"], "Sie"])
                        return true
        return false

func reject_cartel(offer_id: int) -> bool:
        for i in range(pending_offers.size()):
                if pending_offers[i]["id"] == offer_id:
                        player_relations[pending_offers[i]["competitor_id"]] -= 10
                        pending_offers.remove_at(i)
                        return true
        return false

# ==============================================================================
# TAKEOVER FUNCTIONS
# ==============================================================================

func attempt_takeover(target_id: String) -> Dictionary:
        if not competitors.has(target_id) or competitors[target_id]["bankrupt"]:
                return {"success": false, "reason": "Ziel nicht verfuegbar"}
        
        var target = competitors[target_id]
        var cost = target["cash"] * 1.5 + target["regions"].size() * 1000000
        
        if game_manager.cash < cost:
                return {"success": false, "reason": "Nicht genug Kapital"}
        
        var success = 0.3 + player_relations[target_id] / 200.0
        
        if randf() < success:
                game_manager.cash -= cost
                target["bankrupt"] = true
                competitor_bankrupt.emit(target_id)
                return {"success": true, "cost": cost}
        else:
                game_manager.cash -= cost * 0.3
                player_relations[target_id] -= 50
                return {"success": false, "reason": "Abgewehrt!"}

# ==============================================================================
# GETTERS
# ==============================================================================

func get_competitor_list() -> Array:
        var result = []
        for comp_id in competitors:
                var comp = competitors[comp_id]
                result.append({
                        "id": comp_id,
                        "name": comp.get("name", "Unknown"),
                        "company": comp.get("company", "Unknown"),
                        "logo": comp.get("logo", ""),
                        "cash": comp.get("cash", 0),
                        "bankrupt": comp.get("bankrupt", false),
                        "relation": player_relations.get(comp_id, 0),
                        "shares_available": comp.get("shares_available", 0),
                        "share_price": comp.get("share_price", 10000)
                })
        return result

func get_pending_offers() -> Array:
        return pending_offers.duplicate()

func is_in_cartel() -> bool:
        for c in active_cartels:
                if "player" in c["partners"]:
                        return true
        return false

func get_competitor_by_id(comp_id: String) -> Dictionary:
        return competitors.get(comp_id, {})

# ==============================================================================
# SAVE/LOAD
# ==============================================================================

func get_save_data() -> Dictionary:
        return {
                "competitors": competitors,
                "active_cartels": active_cartels,
                "player_relations": player_relations,
                "pending_offers": pending_offers,
                "used_company_indices": used_company_indices
        }

func load_save_data(data: Dictionary):
        competitors = data.get("competitors", {})
        active_cartels = data.get("active_cartels", [])
        player_relations = data.get("player_relations", {})
        pending_offers = data.get("pending_offers", [])
        used_company_indices = data.get("used_company_indices", [])

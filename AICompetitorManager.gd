extends Node
# AICompetitorManager.gd - Charaktervolle KI-Gegner mit Strategien und Kartell-System

signal competitor_action(competitor_id: String, action: String, details: Dictionary)
signal cartel_formed(partners: Array)
signal cartel_discovered(partners: Array, penalty: float)
signal competitor_bankrupt(competitor_id: String)
signal hostile_takeover_attempt(attacker: String, target: String)

# ==============================================================================
# KI-GEGNER PROFILE
# ==============================================================================

const COMPETITORS = {
	"volkov": {
		"id": "volkov",
		"name": "Viktor Volkov",
		"company": "Volga Oil Corporation",
		"nationality": "Russian",
		"personality": "aggressive",
		"description": "Ehemaliger KGB-Offizier. Kennt keine Skrupel. Gewinne um jeden Preis.",
		"strategy": {"expansion": 0.9, "risk_taking": 0.85, "sabotage": 0.7, "cartel": 0.8},
		"starting_cash": 8000000,
		"bonus": {"sabotage_success": 1.2},
		"weakness": {"reputation_loss": 1.5},
		"quotes": ["In meiner Heimat haben wir ein Sprichwort: Wer zoegert, verliert.", "Ihr Erdoel... es sieht besser aus in meinen Tanks."]
	},
	"sterling": {
		"id": "sterling",
		"name": "Margaret Sterling",
		"company": "Sterling & Sons Petroleum",
		"nationality": "British",
		"personality": "conservative",
		"description": "Britische Aristokratin. Altes Geld, konservative Strategie.",
		"strategy": {"expansion": 0.4, "risk_taking": 0.2, "sabotage": 0.1, "cartel": 0.3},
		"starting_cash": 15000000,
		"bonus": {"reputation": 1.2},
		"weakness": {"adaptation_speed": 0.7},
		"quotes": ["Meine Familie ist seit Generationen im Oelgeschaeft.", "Wir bauen nachhaltig auf."]
	},
	"doerfler": {
		"id": "doerfler",
		"name": "Hans Doerfler",
		"company": "Doerfler Energie AG",
		"nationality": "German",
		"personality": "efficient",
		"description": "Deutscher Ingenieur. Effizienz-Optimierer. Jede Bohrung wird berechnet.",
		"strategy": {"expansion": 0.6, "risk_taking": 0.3, "sabotage": 0.2, "cartel": 0.5},
		"starting_cash": 10000000,
		"bonus": {"production_efficiency": 1.25},
		"weakness": {"innovation": 0.8},
		"quotes": ["Effizienz ist keine Option, sie ist eine Pflicht.", "Ich habe die Zahlen analysiert."]
	},
	"alrashid": {
		"id": "alrashid",
		"name": "Ahmed Al-Rashid",
		"company": "Al-Rashid Petroleum Holdings",
		"nationality": "Saudi",
		"personality": "connected",
		"description": "Sohn eines Scheichs. Beste OPEC-Verbindungen.",
		"strategy": {"expansion": 0.7, "risk_taking": 0.5, "sabotage": 0.3, "cartel": 0.9},
		"starting_cash": 20000000,
		"bonus": {"opec_influence": 1.5},
		"weakness": {"reputation_in_west": 0.8},
		"quotes": ["Meine Familie kennt jeden, der in OPEC wichtig ist.", "Ein kleiner Anruf, und die Preise steigen."]
	},
	"chen": {
		"id": "chen",
		"name": "Sarah Chen",
		"company": "Pacific Energy Technologies",
		"nationality": "American",
		"personality": "innovative",
		"description": "MIT-Absolventin. Technologie-Fokus. Fracking-Pionierin.",
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

func _ready():
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
	_initialize_competitors()

func _initialize_competitors():
	for comp_id in COMPETITORS:
		var template = COMPETITORS[comp_id]
		competitors[comp_id] = {
			"id": comp_id,
			"name": template["name"],
			"company": template["company"],
			"cash": template["starting_cash"],
			"regions": [],
			"bankrupt": false,
			"reputation": 50
		}
		player_relations[comp_id] = 0

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
	var template = COMPETITORS[comp["id"]]
	var strategy = template["strategy"]
	
	# Expansion
	if randf() < strategy["expansion"] * 0.1:
		if comp["cash"] > 500000:
			comp["cash"] -= 300000
			comp["regions"].append("expansion_%d" % randi())
			competitor_action.emit(comp["id"], "expansion", {})
	
	# Sabotage against player
	if randf() < strategy["sabotage"] * 0.03:
		competitor_action.emit(comp["id"], "sabotage", {"target": "player"})

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
			var template = COMPETITORS[comp["id"]]
			pending_offers.append({
				"id": randi(),
				"competitor_id": comp["id"],
				"competitor_name": comp["name"],
				"price_bonus": randi_range(10, 25),
				"duration": randi_range(6, 24),
				"quote": template["quotes"].pick_random()
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
			"name": comp["name"],
			"company": comp["company"],
			"cash": comp["cash"],
			"bankrupt": comp["bankrupt"],
			"relation": player_relations[comp_id]
		})
	return result

func get_pending_offers() -> Array:
	return pending_offers.duplicate()

func is_in_cartel() -> bool:
	for c in active_cartels:
		if "player" in c["partners"]:
			return true
	return false

# ==============================================================================
# SAVE/LOAD
# ==============================================================================

func get_save_data() -> Dictionary:
	return {
		"competitors": competitors,
		"active_cartels": active_cartels,
		"player_relations": player_relations,
		"pending_offers": pending_offers
	}

func load_save_data(data: Dictionary):
	competitors = data.get("competitors", {})
	active_cartels = data.get("active_cartels", [])
	player_relations = data.get("player_relations", {})
	pending_offers = data.get("pending_offers", [])

extends Node
# LegalManager.gd - Umfangreiches Rechtssystem
# Umweltauflagen, Gerichtsverfahren, Bestechung, Mob-Gewalt

signal legal_case_opened(case_id: String)
signal verdict_reached(case_id: String, guilty: bool, penalty: float)
signal bribe_result(success: bool, consequence: String)
signal mob_attack(region: String, damage: float)

# ==============================================================================
# UMWELTAUFLAGEN PRO AERA
# ==============================================================================

const ENVIRONMENTAL_REGULATIONS = {
	0: {  # 1970s
		"penalty_mult": 1.0,
		"spill_penalty_per_barrel": 100,
		"inspection_freq": 0.02
	},
	1: {  # 1980s
		"penalty_mult": 2.0,
		"spill_penalty_per_barrel": 500,
		"inspection_freq": 0.05
	},
	2: {  # 1990s
		"penalty_mult": 5.0,
		"spill_penalty_per_barrel": 2000,
		"inspection_freq": 0.08
	},
	3: {  # 2000s+
		"penalty_mult": 10.0,
		"spill_penalty_per_barrel": 10000,
		"inspection_freq": 0.12
	}
}

# ==============================================================================
# REGIONALE REGIERUNGEN
# ==============================================================================

const GOVERNMENT_TYPES = {
	"Texas": {"corruption": 0.3, "enforcement": 0.5, "mob_risk": 0.05, "officials": ["Sheriff Dalton", "Judge Morrison"]},
	"Alaska": {"corruption": 0.2, "enforcement": 0.7, "mob_risk": 0.08, "officials": ["Governor Hickel", "Director Stein"]},
	"Nordsee": {"corruption": 0.05, "enforcement": 1.0, "mob_risk": 0.02, "officials": ["Van Der Berg", "Mueller"]},
	"Saudi-Arabien": {"corruption": 0.6, "enforcement": 0.3, "mob_risk": 0.15, "officials": ["Sheikh Al-Rashid", "Minister Al-Faisal"]},
	"Sibirien": {"corruption": 0.7, "enforcement": 0.2, "mob_risk": 0.25, "officials": ["Director Volkov", "General Petrov"]},
	"Venezuela": {"corruption": 0.5, "enforcement": 0.4, "mob_risk": 0.35, "officials": ["Minister Chavez", "General Maduro"]},
	"Nigeria": {"corruption": 0.65, "enforcement": 0.25, "mob_risk": 0.30, "officials": ["Minister Okonkwo", "Chief Adewale"]},
	"Mexiko": {"corruption": 0.55, "enforcement": 0.35, "mob_risk": 0.40, "officials": ["Gobernador Hernandez", "General Castillo"]},
	"Indonesien": {"corruption": 0.5, "enforcement": 0.3, "mob_risk": 0.20, "officials": ["Director Suharto", "Minister Widodo"]},
	"Brasilien": {"corruption": 0.35, "enforcement": 0.6, "mob_risk": 0.15, "officials": ["Minister Silva", "Chief Da Silva"]},
	"Libyen": {"corruption": 0.6, "enforcement": 0.2, "mob_risk": 0.30, "officials": ["Colonel Gaddafi", "Minister Al-Mahdi"]}
}

# ==============================================================================
# STRAFTATBESTAENDE
# ==============================================================================

const OFFENSES = {
	"oil_spill": {"name": "Oelppest", "base_penalty": 5000000, "license_risk": 0.3},
	"illegal_dumping": {"name": "Illegale Muellentsorgung", "base_penalty": 2000000, "license_risk": 0.2},
	"safety_violation": {"name": "Sicherheitsversto", "base_penalty": 1000000, "license_risk": 0.15},
	"worker_death": {"name": "Arbeitsunfall mit Todesfolge", "base_penalty": 10000000, "license_risk": 0.5},
	"tax_evasion": {"name": "Steuerhinterziehung", "base_penalty": 0, "license_risk": 0.1},
	"bribery": {"name": "Bestechung", "base_penalty": 5000000, "license_risk": 0.3},
	"cartel": {"name": "Kartellbildung", "base_penalty": 10000000, "license_risk": 0.25}
}

# ==============================================================================
# STATE
# ==============================================================================

var game_manager = null
var active_cases: Dictionary = {}
var case_history: Array = []
var lawyer_quality: float = 0.5
var compliance_levels: Dictionary = {}
var mob_risk_levels: Dictionary = {}

func _ready():
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

# ==============================================================================
# MONTHLY PROCESSING
# ==============================================================================

func process_monthly():
	if game_manager == null:
		return
	
	var regulations = ENVIRONMENTAL_REGULATIONS.get(game_manager.current_era, ENVIRONMENTAL_REGULATIONS[0])
	
	_random_inspections(regulations)
	_process_active_cases()
	_check_mob_violence()
	_check_environmental_incidents()

func _random_inspections(regulations: Dictionary):
	for region in game_manager.regions:
		if not game_manager.regions[region].get("unlocked", false):
			continue
		
		if randf() < regulations["inspection_freq"]:
			var gov = GOVERNMENT_TYPES.get(region, GOVERNMENT_TYPES["Texas"])
			if randf() < gov["enforcement"] * 0.1:
				_open_case(region, "safety_violation")

func _process_active_cases():
	for case_id in active_cases.keys():
		var case_data = active_cases[case_id]
		case_data["months"] += 1
		
		if case_data["months"] >= 6 and case_data["status"] == "pending":
			_resolve_case(case_id)

func _check_mob_violence():
	for region in game_manager.regions:
		if not game_manager.regions[region].get("unlocked", false):
			continue
		
		var mob_risk = mob_risk_levels.get(region, 0.0)
		if mob_risk > 0 and randf() < mob_risk:
			_trigger_mob_attack(region)
		mob_risk_levels[region] = max(0, mob_risk - 0.02)

func _check_environmental_incidents():
	for region in game_manager.regions:
		if not game_manager.regions[region].get("unlocked", false):
			continue
		
		if randf() < 0.005:
			_open_case(region, "oil_spill")

# ==============================================================================
# CASE MANAGEMENT
# ==============================================================================

func _open_case(region: String, offense_id: String) -> String:
	var case_id = "case_%d_%d" % [game_manager.date["year"], randi()]
	var offense = OFFENSES.get(offense_id, OFFENSES["safety_violation"])
	var gov = GOVERNMENT_TYPES.get(region, GOVERNMENT_TYPES["Texas"])
	var regulations = ENVIRONMENTAL_REGULATIONS.get(game_manager.current_era, ENVIRONMENTAL_REGULATIONS[0])
	
	var penalty = offense["base_penalty"] * regulations["penalty_mult"]
	
	active_cases[case_id] = {
		"id": case_id,
		"region": region,
		"offense": offense["name"],
		"base_penalty": penalty,
		"official": gov["officials"].pick_random(),
		"corruption_level": gov["corruption"],
		"mob_risk": gov["mob_risk"],
		"license_risk": offense["license_risk"],
		"status": "pending",
		"months": 0
	}
	
	legal_case_opened.emit(case_id)
	return case_id

func _resolve_case(case_id: String):
	if not active_cases.has(case_id):
		return
	
	var case_data = active_cases[case_id]
	var guilty = randf() < (0.8 - lawyer_quality * 0.4)
	var penalty = 0.0
	
	if guilty:
		penalty = case_data["base_penalty"] * (1.0 - lawyer_quality * 0.3)
		game_manager.cash -= penalty
		game_manager.book_transaction("Global", -penalty, "Gerichtsurteil: " + case_data["offense"])
		
		if randf() < case_data["license_risk"]:
			game_manager.regions[case_data["region"]]["unlocked"] = false
	else:
		penalty = case_data["base_penalty"] * 0.1
		game_manager.cash -= penalty
		game_manager.book_transaction("Global", -penalty, "Anwaltskosten")
	
	verdict_reached.emit(case_id, guilty, penalty)
	case_history.append(active_cases[case_id].duplicate())
	active_cases.erase(case_id)

# ==============================================================================
# BRIBERY
# ==============================================================================

func attempt_bribe(case_id: String) -> Dictionary:
	if not active_cases.has(case_id):
		return {"success": false, "reason": "Fall nicht gefunden"}
	
	var case_data = active_cases[case_id]
	var bribe_cost = case_data["base_penalty"] * 0.3
	
	if game_manager.cash < bribe_cost:
		return {"success": false, "reason": "Nicht genug Geld"}
	
	if randf() < case_data["corruption_level"]:
		game_manager.cash -= bribe_cost
		game_manager.book_transaction(case_data["region"], -bribe_cost, "Bestechung")
		active_cases.erase(case_id)
		mob_risk_levels[case_data["region"]] = case_data["mob_risk"] * 2
		bribe_result.emit(true, "Bestechung akzeptiert")
		return {"success": true, "cost": bribe_cost, "mob_warning": true}
	else:
		var extra_penalty = case_data["base_penalty"] * 0.5
		game_manager.cash -= extra_penalty
		game_manager.book_transaction("Global", -extra_penalty, "Bestechungsversuch aufgedeckt")
		case_data["base_penalty"] *= 1.5
		bribe_result.emit(false, "Bestechung aufgedeckt!")
		return {"success": false, "penalty": extra_penalty}

# ==============================================================================
# MOB VIOLENCE
# ==============================================================================

func _trigger_mob_attack(region: String):
	var damage = randf_range(1000000, 10000000)
	game_manager.cash -= damage
	game_manager.book_transaction(region, -damage, "Mob-Angriff")
	
	# Beschädige Claims
	for claim in game_manager.regions[region].get("claims", []):
		if claim.get("owned", false) and randf() < 0.3:
			claim["damaged"] = true
			claim["damage_amount"] = randf_range(0.2, 0.5)
	
	mob_attack.emit(region, damage)
	mob_risk_levels[region] = 0

# ==============================================================================
# COMPLIANCE
# ==============================================================================

func invest_compliance(region: String, amount: float) -> bool:
	if game_manager.cash < amount:
		return false
	
	game_manager.cash -= amount
	game_manager.book_transaction(region, -amount, "Compliance-Investition")
	compliance_levels[region] = min(compliance_levels.get(region, 0.0) + amount / 1000000.0, 1.0)
	return true

# ==============================================================================
# LAWYERS
# ==============================================================================

func hire_lawyer(quality: String) -> bool:
	var costs = {"cheap": 100000, "standard": 500000, "premium": 2000000, "elite": 10000000}
	var qualities = {"cheap": 0.3, "standard": 0.6, "premium": 0.85, "elite": 0.95}
	
	if not costs.has(quality) or game_manager.cash < costs[quality]:
		return false
	
	game_manager.cash -= costs[quality]
	game_manager.book_transaction("Global", -costs[quality], "Anwalt eingestellt")
	lawyer_quality = qualities[quality]
	return true

# ==============================================================================
# GETTERS
# ==============================================================================

func get_active_cases() -> Dictionary:
	return active_cases.duplicate()

func get_case_history() -> Array:
	return case_history.duplicate()

func get_lawyer_quality() -> float:
	return lawyer_quality

func get_compliance(region: String) -> float:
	return compliance_levels.get(region, 0.0)

# ==============================================================================
# SAVE/LOAD
# ==============================================================================

func get_save_data() -> Dictionary:
	return {
		"active_cases": active_cases,
		"case_history": case_history,
		"lawyer_quality": lawyer_quality,
		"compliance_levels": compliance_levels,
		"mob_risk_levels": mob_risk_levels
	}

func load_save_data(data: Dictionary):
	active_cases = data.get("active_cases", {})
	case_history = data.get("case_history", [])
	lawyer_quality = data.get("lawyer_quality", 0.5)
	compliance_levels = data.get("compliance_levels", {})
	mob_risk_levels = data.get("mob_risk_levels", {})

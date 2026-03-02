extends Node
# EmergencyManager.gd - Telephone emergency system
# Handles actionable emergency events (fires, strikes, tank failures)

signal emergency_call_received(emergency: Dictionary)
signal emergency_resolved(emergency_id: String, outcome: String)
signal emergency_failed(emergency_id: String, penalty: Dictionary)

# --- EMERGENCY TYPES ---
enum EmergencyType {
	FIRE,
	STRIKE,
	TANK_EXPLOSION,
	PIPELINE_LEAK,
	RIG_ACCIDENT,
	SPILL,
	EQUIPMENT_FAILURE,
	SABOTAGE_REPORT,
	LEGAL_SUMMONS
}

# --- EMERGENCY DEFINITIONS ---
const EMERGENCY_TYPES = {
	"oil_field_fire": {
		"id": "oil_field_fire",
		"name": "Ölfeldbrand!",
		"description": "Fire at %s, Claim #%d! Immediate action required!",
		"icon": "🔥",
		"priority": 1,  # Higher = more urgent
		"timeout_hours": 24,  # Time to respond
		"auto_penalty": {"damage_percent": 100, "production_loss_months": 6},
		"resolvable": true,
		"resolution_methods": [
			{
				"id": "minigame",
				"name": "Firefighter Mini-Game",
				"description": "Send your team to fight the fire",
				"cost": 0,
				"success_rate": 0.7,
				"minigame": "firefighter"
			},
			{
				"id": "ted_redhair",
				"name": "Hire Ted Redhair",
				"description": "Legendary firefighter - 100%% success",
				"cost": 500000,
				"success_rate": 1.0,
				"minigame": null
			},
			{
				"id": "ignore",
				"name": "Let it burn",
				"description": "Accept total loss",
				"cost": 0,
				"success_rate": 0.0,
				"minigame": null
			}
		]
	},
	"worker_strike": {
		"id": "worker_strike",
		"name": "Arbeiterstreik!",
		"description": "Workers at %s are on strike! Production halted!",
		"icon": "✊",
		"priority": 2,
		"timeout_hours": 72,
		"auto_penalty": {"production_loss_months": 1, "reputation": -10},
		"resolvable": true,
		"resolution_methods": [
			{
				"id": "negotiate",
				"name": "Negotiate",
				"description": "Offer 20%% wage increase",
				"cost": 200000,
				"success_rate": 0.8,
				"minigame": null
			},
			{
				"id": "bribe",
				"name": "Bribe Union Leaders",
				"description": "Pay off the strike organizers",
				"cost": 500000,
				"success_rate": 0.9,
				"minigame": null,
				"risk": {"scandal_chance": 0.2}
			},
			{
				"id": "replace",
				"name": "Replace Workers",
				"description": "Fire strikers, hire replacements",
				"cost": 100000,
				"success_rate": 0.6,
				"minigame": null,
				"risk": {"reputation": -15, "future_strike_chance": 0.3}
			}
		]
	},
	"tank_explosion": {
		"id": "tank_explosion",
		"name": "Tankspeicher explodiert!",
		"description": "Storage tank explosion at %s! %d barrels lost!",
		"icon": "💥",
		"priority": 1,
		"timeout_hours": 12,
		"auto_penalty": {"oil_loss": 50000, "environmental_fine": 1000000},
		"resolvable": true,
		"resolution_methods": [
			{
				"id": "emergency_containment",
				"name": "Emergency Containment",
				"description": "Deploy containment teams",
				"cost": 200000,
				"success_rate": 0.7,
				"minigame": null,
				"benefit": {"reduce_fine": 0.5}
			},
			{
				"id": "new_tanks",
				"name": "Build New Tanks",
				"description": "Replace destroyed capacity",
				"cost": 800000,
				"success_rate": 1.0,
				"minigame": null,
				"benefit": {"new_capacity": 500000}
			}
		]
	},
	"pipeline_leak": {
		"id": "pipeline_leak",
		"name": "Pipelineleck!",
		"description": "Pipeline leak detected in %s! Environmental hazard!",
		"icon": "🛢️",
		"priority": 2,
		"timeout_hours": 48,
		"auto_penalty": {"environmental_fine": 500000, "reputation": -10},
		"resolvable": true,
		"resolution_methods": [
			{
				"id": "quick_repair",
				"name": "Quick Repair",
				"description": "Emergency pipeline repair",
				"cost": 150000,
				"success_rate": 0.8,
				"minigame": "pipeline"
			},
			{
				"id": "full_replacement",
				"name": "Replace Section",
				"description": "Replace entire damaged section",
				"cost": 500000,
				"success_rate": 1.0,
				"minigame": null
			}
		]
	},
	"rig_accident": {
		"id": "rig_accident",
		"name": "Bohrinselunfall!",
		"description": "Accident at rig in %s! Workers injured!",
		"icon": "⚠️",
		"priority": 1,
		"timeout_hours": 6,
		"auto_penalty": {"lawsuit": 2000000, "investigation": true},
		"resolvable": true,
		"resolution_methods": [
			{
				"id": "medical_response",
				"name": "Emergency Medical Response",
				"description": "Deploy medical teams",
				"cost": 100000,
				"success_rate": 0.9,
				"minigame": null,
				"benefit": {"reduce_lawsuit": 0.5}
			},
			{
				"id": "coverup",
				"name": "Cover Up",
				"description": "Try to hide the incident",
				"cost": 300000,
				"success_rate": 0.4,
				"minigame": null,
				"risk": {"scandal_chance": 0.5, "penalty_multiplier": 3}
			}
		]
	},
	"equipment_failure": {
		"id": "equipment_failure",
		"name": "Ausrüstungsversagen!",
		"description": "Critical equipment failure at %s! Production stopped!",
		"icon": "🔧",
		"priority": 3,
		"timeout_hours": 96,
		"auto_penalty": {"production_loss_days": 7},
		"resolvable": true,
		"resolution_methods": [
			{
				"id": "emergency_repair",
				"name": "Emergency Repair",
				"description": "Call repair crew",
				"cost": 75000,
				"success_rate": 0.9,
				"minigame": null
			},
			{
				"id": "new_equipment",
				"name": "Replace Equipment",
				"description": "Install new machinery",
				"cost": 250000,
				"success_rate": 1.0,
				"minigame": null,
				"benefit": {"efficiency_boost": 0.1}
			}
		]
	}
}

# --- STATE ---
var active_emergencies: Array = []
var emergency_history: Array = []
var phone_ringing: bool = false
var current_emergency: Dictionary = {}

var game_manager = null

func _ready():
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

# --- GENERATE RANDOM EMERGENCY ---
func generate_emergency() -> Dictionary:
	if game_manager == null:
		return {}
	
	# Check if emergency already pending
	if not active_emergencies.is_empty():
		return {}
	
	# Random chance for emergency (2% per day)
	if randf() > 0.02:
		return {}
	
	# Get player's active regions with rigs
	var eligible_regions = []
	for region_name in game_manager.regions:
		var region = game_manager.regions[region_name]
		if region.get("unlocked", false):
			for claim in region.get("claims", []):
				if claim.get("owned", false) and claim.get("drilled", false):
					eligible_regions.append({
						"region": region_name,
						"claim_id": claim.get("id", 0)
					})
	
	if eligible_regions.is_empty():
		return {}
	
	# Choose random region
	var location = eligible_regions.pick_random()
	
	# Choose emergency type based on probability
	var emergency_weights = {
		"oil_field_fire": 0.1,
		"worker_strike": 0.15,
		"tank_explosion": 0.08,
		"pipeline_leak": 0.12,
		"rig_accident": 0.1,
		"equipment_failure": 0.2
	}
	
	var roll = randf()
	var cumulative = 0.0
	var chosen_type = "equipment_failure"
	
	for type_id in emergency_weights:
		cumulative += emergency_weights[type_id]
		if roll <= cumulative:
			chosen_type = type_id
			break
	
	# Create emergency
	var emergency_data = EMERGENCY_TYPES[chosen_type].duplicate(true)
	emergency_data["region"] = location["region"]
	emergency_data["claim_id"] = location["claim_id"]
	emergency_data["timestamp"] = game_manager.date.duplicate()
	emergency_data["hours_remaining"] = emergency_data["timeout_hours"]
	
	# Format description
	emergency_data["formatted_description"] = emergency_data["description"] % [location["region"], location["claim_id"]]
	
	# Add to active emergencies
	active_emergencies.append(emergency_data)
	current_emergency = emergency_data
	
	# Trigger phone ring
	phone_ringing = true
	if game_manager:
		game_manager.phone_ringing = true
		game_manager.phone_ringing_changed.emit(true)
	
	emergency_call_received.emit(emergency_data)
	
	return emergency_data

# --- GET CURRENT EMERGENCY ---
func get_current_emergency() -> Dictionary:
	return current_emergency

# --- ANSWER PHONE ---
func answer_phone() -> Dictionary:
	if active_emergencies.is_empty():
		phone_ringing = false
		if game_manager:
			game_manager.phone_ringing = false
			game_manager.phone_ringing_changed.emit(false)
		return {}
	
	# Get highest priority emergency
	active_emergencies.sort_custom(func(a, b): return a["priority"] > b["priority"])
	current_emergency = active_emergencies[0]
	
	return current_emergency

# --- RESOLVE EMERGENCY ---
func resolve_emergency(emergency_id: String, method_id: String) -> Dictionary:
	var emergency_idx = active_emergencies.find_custom(func(e): return e["id"] == emergency_id)
	
	if emergency_idx == -1:
		return {"success": false, "message": "Emergency not found"}
	
	var emergency = active_emergencies[emergency_idx]
	
	# Find resolution method
	var method = null
	for m in emergency["resolution_methods"]:
		if m["id"] == method_id:
			method = m
			break
	
	if method == null:
		return {"success": false, "message": "Invalid resolution method"}
	
	# Check cost
	var cost = int(method["cost"] * game_manager.inflation_rate)
	if game_manager.cash < cost:
		return {"success": false, "message": "Not enough money. Need $%s" % game_manager.format_cash(cost)}
	
	# Deduct cost
	game_manager.cash -= cost
	game_manager.book_transaction(emergency["region"], -cost, "Emergency Response")
	
	# Determine outcome
	var success = randf() < method["success_rate"]
	
	if success:
		# Apply benefits
		if method.has("benefit"):
			_apply_benefits(method["benefit"], emergency)
		
		# Remove from active
		active_emergencies.remove_at(emergency_idx)
		emergency["resolved"] = true
		emergency["outcome"] = "success"
		emergency["method"] = method_id
		emergency_history.append(emergency)
		
		emergency_resolved.emit(emergency_id, "success")
		
		# Clear phone state
		if active_emergencies.is_empty():
			phone_ringing = false
			current_emergency = {}
			if game_manager:
				game_manager.phone_ringing = false
				game_manager.phone_ringing_changed.emit(false)
		
		return {
			"success": true,
			"message": "Emergency resolved successfully!",
			"outcome": "success"
		}
	else:
		# Apply penalties
		var penalty = emergency["auto_penalty"].duplicate()
		
		# Apply method-specific risks
		if method.has("risk"):
			for risk_type in method["risk"]:
				if risk_type == "scandal_chance" and randf() < method["risk"]["scandal_chance"]:
					penalty["scandal"] = true
				elif risk_type == "penalty_multiplier":
					for key in penalty:
						if penalty[key] is float or penalty[key] is int:
							penalty[key] *= method["risk"]["penalty_multiplier"]
		
		_apply_penalties(penalty, emergency)
		
		# Remove from active
		active_emergencies.remove_at(emergency_idx)
		emergency["resolved"] = false
		emergency["outcome"] = "failure"
		emergency["method"] = method_id
		emergency["penalty"] = penalty
		emergency_history.append(emergency)
		
		emergency_failed.emit(emergency_id, penalty)
		
		# Clear phone state
		if active_emergencies.is_empty():
			phone_ringing = false
			current_emergency = {}
			if game_manager:
				game_manager.phone_ringing = false
				game_manager.phone_ringing_changed.emit(false)
		
		return {
			"success": false,
			"message": "Resolution failed! Penalties applied.",
			"outcome": "failure",
			"penalty": penalty
		}

func _apply_benefits(benefits: Dictionary, emergency: Dictionary):
	if game_manager == null:
		return
	
	if benefits.has("new_capacity"):
		game_manager.tank_capacity[emergency["region"]] += benefits["new_capacity"]
	
	if benefits.has("reduce_fine"):
		# Would reduce any pending fine
		pass
	
	if benefits.has("efficiency_boost"):
		game_manager.tech_bonus_production *= (1.0 + benefits["efficiency_boost"])

func _apply_penalties(penalties: Dictionary, emergency: Dictionary):
	if game_manager == null:
		return
	
	if penalties.has("damage_percent"):
		# Apply to specific claim
		var region = game_manager.regions.get(emergency["region"], {})
		if region.has("claims"):
			for claim in region["claims"]:
				if claim.get("id") == emergency.get("claim_id"):
					claim["drilled"] = false  # Needs re-drilling
					claim["fire_recovery_months"] = 6
	
	if penalties.has("production_loss_months"):
		# Would halt production
		pass
	
	if penalties.has("oil_loss"):
		var loss = min(penalties["oil_loss"], game_manager.oil_stored.get(emergency["region"], 0))
		game_manager.oil_stored[emergency["region"]] -= loss
	
	if penalties.has("environmental_fine"):
		var fine = int(penalties["environmental_fine"] * game_manager.inflation_rate)
		game_manager.cash -= fine
		game_manager.book_transaction(emergency["region"], -fine, "Environmental Penalties")
	
	if penalties.has("lawsuit"):
		var lawsuit_cost = int(penalties["lawsuit"] * game_manager.inflation_rate)
		game_manager.cash -= lawsuit_cost
		game_manager.book_transaction("Global", -lawsuit_cost, "Legal Settlements")
	
	if penalties.has("reputation"):
		# Would affect reputation
		pass
	
	if penalties.get("investigation", false):
		if has_node("/root/FeedbackOverlay"):
			get_node("/root/FeedbackOverlay").show_msg(
				"GOVERNMENT INVESTIGATION LAUNCHED!\nYour operations are under scrutiny.",
				Color.ORANGE
			)

# --- PROCESS HOURLY (for timeouts) ---
func process_hourly():
	for emergency in active_emergencies:
		emergency["hours_remaining"] -= 1
		
		if emergency["hours_remaining"] <= 0:
			# Auto-fail emergency
			_apply_penalties(emergency["auto_penalty"], emergency)
			active_emergencies.erase(emergency)
			emergency["resolved"] = false
			emergency["outcome"] = "timeout"
			emergency_history.append(emergency)
			
			emergency_failed.emit(emergency["id"], emergency["auto_penalty"])
			
			if has_node("/root/FeedbackOverlay"):
				get_node("/root/FeedbackOverlay").show_msg(
					"EMERGENCY TIMEOUT!\n%s was not addressed in time!" % emergency["name"],
					Color.RED
				)

# --- GET ACTIVE EMERGENCIES ---
func get_active_emergencies() -> Array:
	return active_emergencies

# --- GET RESOLUTION OPTIONS ---
func get_resolution_options(emergency_id: String) -> Array:
	for emergency in active_emergencies:
		if emergency["id"] == emergency_id:
			return emergency["resolution_methods"]
	return []

# --- SAVE/LOAD ---
func get_save_data() -> Dictionary:
	return {
		"active": active_emergencies,
		"history": emergency_history,
		"phone_ringing": phone_ringing,
		"current": current_emergency
	}

func load_save_data(data: Dictionary):
	active_emergencies = data.get("active", [])
	emergency_history = data.get("history", [])
	phone_ringing = data.get("phone_ringing", false)
	current_emergency = data.get("current", {})

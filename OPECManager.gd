extends Node
# OPECManager.gd - OPEC dynamics and negotiations
# Handles OPEC meetings, oil crisis events, and secret deals

signal opec_meeting_scheduled()
signal opec_decision(decision: String, effect: Dictionary)
signal oil_crisis_started(severity: float)
signal secret_deal_made(deal: Dictionary)

# --- OPEC MEMBER STATES ---
const OPEC_MEMBERS = [
	{"id": "saudi_arabia", "name": "Saudi Arabia", "production_share": 0.32, "influence": 0.9, "stance": "moderate"},
	{"id": "iran", "name": "Iran", "production_share": 0.12, "influence": 0.6, "stance": "hardline"},
	{"id": "iraq", "name": "Iraq", "production_share": 0.10, "influence": 0.5, "stance": "aggressive"},
	{"id": "kuwait", "name": "Kuwait", "production_share": 0.08, "influence": 0.4, "stance": "moderate"},
	{"id": "uae", "name": "UAE", "production_share": 0.07, "influence": 0.35, "stance": "moderate"},
	{"id": "venezuela", "name": "Venezuela", "production_share": 0.10, "influence": 0.45, "stance": "hardline"},
	{"id": "nigeria", "name": "Nigeria", "production_share": 0.06, "influence": 0.3, "stance": "moderate"},
	{"id": "libya", "name": "Libya", "production_share": 0.04, "influence": 0.25, "stance": "aggressive"},
	{"id": "algeria", "name": "Algeria", "production_share": 0.05, "influence": 0.25, "stance": "moderate"},
	{"id": "qatar", "name": "Qatar", "production_share": 0.03, "influence": 0.2, "stance": "moderate"},
	{"id": "indonesia", "name": "Indonesia", "production_share": 0.03, "influence": 0.2, "stance": "moderate"},
]

# --- OPEC DECISION TYPES ---
const OPEC_DECISION_TYPES = {
	"production_cut": {
		"name": "Production Cut",
		"description": "Reduce output to raise prices",
		"effect": {"price_change": 1.2, "duration": 6},
		"member_support_range": [0.3, 0.6]  # How many members typically support
	},
	"production_increase": {
		"name": "Production Increase",
		"description": "Flood market to lower prices or hurt competitors",
		"effect": {"price_change": 0.8, "duration": 6},
		"member_support_range": [0.4, 0.7]
	},
	"price_hike": {
		"name": "Price Hike",
		"description": "Increase official selling price",
		"effect": {"price_change": 1.15, "duration": 3},
		"member_support_range": [0.5, 0.8]
	},
	"embargo": {
		"name": "Oil Embargo",
		"description": "Cut off supplies to specific countries",
		"effect": {"price_change": 2.0, "duration": 3, "supply_crisis": true},
		"member_support_range": [0.2, 0.4]
	},
	"quota_system": {
		"name": "Quota System",
		"description": "Set production quotas for members",
		"effect": {"price_stability": true, "duration": 12},
		"member_support_range": [0.6, 0.9]
	}
}

# --- SECRET DEAL TYPES ---
const SECRET_DEAL_TYPES = [
	{
		"id": "preferred_buyer",
		"name": "Preferred Buyer Status",
		"description": "Get first access to new production at preferential rates.",
		"cost": 2000000,
		"benefit": {"price_discount": 0.05, "supply_priority": true},
		"risk": 0.1,
		"requires_member": "saudi_arabia"
	},
	{
		"id": "production_intel",
		"name": "Production Intelligence",
		"description": "Get advance notice of OPEC production decisions.",
		"cost": 500000,
		"benefit": {"opec_forecast": true},
		"risk": 0.15,
		"requires_member": "any"
	},
	{
		"id": "competitor_squeeze",
		"name": "Competitor Squeeze",
		"description": "Convince OPEC to increase production and hurt competitor margins.",
		"cost": 3000000,
		"benefit": {"competitor_penalty": 0.2},
		"risk": 0.25,
		"requires_member": "saudi_arabia"
	},
	{
		"id": "arbitrage_tip",
		"name": "Arbitrage Tip",
		"description": "Insider information on upcoming price changes.",
		"cost": 750000,
		"benefit": {"price_hint": true},
		"risk": 0.2,
		"requires_member": "any"
	},
	{
		"id": "bypass_sanctions",
		"name": "Sanctions Bypass",
		"description": "Secret oil deals with sanctioned nations (high risk!).",
		"cost": 5000000,
		"benefit": {"cheap_oil_access": true, "discount": 0.3},
		"risk": 0.5,
		"requires_member": "libya"  # Or Iran, Iraq depending on era
	}
]

# --- HISTORICAL CRISIS EVENTS ---
const HISTORICAL_CRISES = [
	{
		"year": 1973,
		"month": 10,
		"id": "1973_embargo",
		"name": "1973 Oil Embargo",
		"description": "Arab members announce embargo against US for supporting Israel in Yom Kippur War.",
		"severity": 1.0,  # Maximum severity
		"duration_months": 5,
		"price_multiplier": 4.0,
		"triggered": false
	},
	{
		"year": 1979,
		"month": 1,
		"id": "iran_revolution",
		"name": "Iranian Revolution",
		"description": "Shah overthrown, Iranian oil exports halt. Panic buying ensues.",
		"severity": 0.8,
		"duration_months": 6,
		"price_multiplier": 2.5,
		"triggered": false
	},
	{
		"year": 1980,
		"month": 9,
		"id": "iran_iraq_war",
		"name": "Iran-Iraq War",
		"description": "War between two major producers threatens Gulf oil flows.",
		"severity": 0.7,
		"duration_months": 36,  # Long war
		"price_multiplier": 1.5,
		"triggered": false
	},
	{
		"year": 1986,
		"month": 1,
		"id": "1986_price_war",
		"name": "1986 Price War",
		"description": "Saudi Arabia floods market to regain market share. Prices crash.",
		"severity": 0.5,
		"duration_months": 12,
		"price_multiplier": 0.4,  # Price CRASH
		"triggered": false
	},
	{
		"year": 1990,
		"month": 8,
		"id": "gulf_war",
		"name": "Gulf War Crisis",
		"description": "Iraq invades Kuwait. Oil prices spike as war looms.",
		"severity": 0.9,
		"duration_months": 8,
		"price_multiplier": 2.0,
		"triggered": false
	}
]

# --- STATE ---
var opec_relations: Dictionary = {}  # Relations with each OPEC member
var active_deals: Array = []
var current_opec_stance: String = "moderate"  # moderate, restrictive, aggressive
var next_meeting_month: int = 0
var crisis_active: bool = false
var current_crisis: Dictionary = {}
var crisis_months_remaining: int = 0

var game_manager = null

func _ready():
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
	
	# Initialize relations with OPEC members
	for member in OPEC_MEMBERS:
		opec_relations[member["id"]] = 0.5  # Start neutral

# --- CHECK FOR HISTORICAL CRISES ---
func check_historical_crisis() -> Dictionary:
	if game_manager == null:
		return {}
	
	for crisis in HISTORICAL_CRISES:
		if not crisis["triggered"]:
			if game_manager.date["year"] == crisis["year"] and game_manager.date["month"] == crisis["month"]:
				crisis["triggered"] = true
				_trigger_crisis(crisis)
				return crisis
	
	return {}

func _trigger_crisis(crisis: Dictionary):
	crisis_active = true
	current_crisis = crisis
	crisis_months_remaining = crisis["duration_months"]
	
	# Apply immediate price effect
	if game_manager:
		game_manager.price_multiplier *= crisis["price_multiplier"]
	
	oil_crisis_started.emit(crisis["severity"])
	
	# Show notification
	if has_node("/root/FeedbackOverlay"):
		get_node("/root/FeedbackOverlay").show_msg(
			"═══ OIL CRISIS ═══\n\n%s\n\n%s\n\nOil prices affected for %d months!" % [
				crisis["name"],
				crisis["description"],
				crisis["duration_months"]
			],
			Color.RED if crisis["price_multiplier"] > 1.0 else Color.ORANGE
		)

# --- OPEC MEETING SYSTEM ---
func schedule_opec_meeting():
	# OPEC meetings happen quarterly
	if game_manager == null:
		return
	
	next_meeting_month = game_manager.date["month"] + 3
	if next_meeting_month > 12:
		next_meeting_month -= 12
	
	opec_meeting_scheduled.emit()

func conduct_opec_meeting() -> Dictionary:
	# Determine OPEC decision based on current stance and member votes
	var decision_type = _choose_decision_type()
	var decision = OPEC_DECISION_TYPES[decision_type]
	
	# Simulate member voting
	var support = _calculate_member_support(decision_type)
	
	# Apply effects if passed
	if support > 0.5:
		_apply_opec_decision(decision)
		opec_decision.emit(decision_type, decision["effect"])
		return {
			"decision": decision_type,
			"name": decision["name"],
			"passed": true,
			"support": support,
			"effect": decision["effect"]
		}
	else:
		return {
			"decision": decision_type,
			"name": decision["name"],
			"passed": false,
			"support": support,
			"effect": {}
		}

func _choose_decision_type() -> String:
	# Based on current market conditions and era
	if game_manager == null:
		return "quota_system"
	
	var year = game_manager.date["year"]
	
	# 1973-1974: Embargo era
	if year == 1973 and game_manager.date["month"] >= 10:
		return "embargo"
	if year == 1974 and game_manager.date["month"] <= 3:
		return "embargo"
	
	# 1979-1981: Crisis era
	if year >= 1979 and year <= 1981:
		return "production_cut" if randf() < 0.6 else "price_hike"
	
	# 1986: Price war
	if year == 1986:
		return "production_increase"
	
	# Default behavior based on oil price
	if game_manager.oil_price < 15:
		return "production_cut"  # Try to raise prices
	elif game_manager.oil_price > 40:
		return "production_increase"  # Take advantage of high prices
	else:
		return "quota_system"  # Maintain stability

func _calculate_member_support(decision_type: String) -> float:
	var total_support = 0.0
	var total_influence = 0.0
	
	for member in OPEC_MEMBERS:
		var member_stance = member["stance"]
		var influence = member["influence"]
		var base_support = 0.5
		
		# Modify based on stance vs decision
		match decision_type:
			"embargo":
				if member_stance == "aggressive":
					base_support = 0.8
				elif member_stance == "hardline":
					base_support = 0.6
				else:
					base_support = 0.3
			"production_cut":
				if member_stance == "hardline":
					base_support = 0.7
				else:
					base_support = 0.5
			"production_increase":
				if member_stance == "moderate":
					base_support = 0.7
				else:
					base_support = 0.4
		
		# Add relation bonus
		var relation = opec_relations.get(member["id"], 0.5)
		base_support += (relation - 0.5) * 0.2
		
		total_support += base_support * influence
		total_influence += influence
	
	return total_support / total_influence if total_influence > 0 else 0.5

func _apply_opec_decision(decision: Dictionary):
	if game_manager == null:
		return
	
	var effect = decision["effect"]
	
	if effect.has("price_change"):
		game_manager.price_multiplier *= effect["price_change"]

# --- SECRET DEALS ---
func get_available_secret_deals() -> Array:
	var available = []
	
	for deal in SECRET_DEAL_TYPES:
		var cost = int(deal["cost"] * (game_manager.inflation_rate if game_manager else 1.0))
		
		# Check if required member is available
		var member_ok = true
		if deal["requires_member"] != "any":
			# Check if we have enough relation with required member
			var relation = opec_relations.get(deal["requires_member"], 0.5)
			member_ok = relation >= 0.5
		
		if member_ok:
			available.append({
				"id": deal["id"],
				"name": deal["name"],
				"description": deal["description"],
				"cost": cost,
				"risk": deal["risk"],
				"benefit": deal["benefit"]
			})
	
	return available

func attempt_secret_deal(deal_id: String) -> Dictionary:
	if game_manager == null:
		return {"success": false, "message": "System error"}
	
	var deal = SECRET_DEAL_TYPES.find_custom(func(d): return d["id"] == deal_id)
	if deal == -1:
		return {"success": false, "message": "Deal not found"}
	deal = SECRET_DEAL_TYPES[deal]
	
	var cost = int(deal["cost"] * game_manager.inflation_rate)
	
	if game_manager.cash < cost:
		return {"success": false, "message": "Not enough funds. Need $%s" % game_manager.format_cash(cost)}
	
	# Deduct cost
	game_manager.cash -= cost
	game_manager.book_transaction("Global", -cost, "OPEC Relations")
	
	# Check for exposure
	if randf() < deal["risk"]:
		# Deal exposed!
		if has_node("/root/FeedbackOverlay"):
			get_node("/root/FeedbackOverlay").show_msg(
				"SCANDAL! Your secret deal with OPEC was exposed!\nReputation damaged.",
				Color.RED
			)
		return {"success": false, "message": "Deal exposed! Scandal!", "scandal": true}
	
	# Success
	var active_deal = {
		"id": deal["id"],
		"name": deal["name"],
		"benefit": deal["benefit"],
		"start_date": game_manager.date.duplicate()
	}
	active_deals.append(active_deal)
	
	secret_deal_made.emit(deal)
	
	return {"success": true, "message": "Secret deal secured!", "benefit": deal["benefit"]}

# --- IMPROVE RELATIONS ---
func improve_relations(member_id: String, amount: float) -> bool:
	if game_manager == null:
		return false
	
	var cost = int(100000 * game_manager.inflation_rate)
	
	if game_manager.cash < cost:
		return false
	
	game_manager.cash -= cost
	game_manager.book_transaction("Global", -cost, "Diplomacy")
	
	opec_relations[member_id] = min(1.0, opec_relations.get(member_id, 0.5) + amount)
	
	return true

# --- PROCESS MONTHLY ---
func process_monthly():
	# Process crisis
	if crisis_active:
		crisis_months_remaining -= 1
		if crisis_months_remaining <= 0:
			_end_crisis()

func _end_crisis():
	crisis_active = false
	current_crisis = {}
	
	# Gradually revert price multiplier
	if game_manager:
		game_manager.price_multiplier = 1.0
	
	if has_node("/root/FeedbackOverlay"):
		get_node("/root/FeedbackOverlay").show_msg(
			"Oil crisis resolved. Markets returning to normal.",
			Color.GREEN
		)

# --- GET OPEC STATUS ---
func get_opec_status() -> Dictionary:
	return {
		"current_stance": current_opec_stance,
		"crisis_active": crisis_active,
		"current_crisis": current_crisis,
		"active_deals": active_deals.size(),
		"relations": opec_relations
	}

# --- SAVE/LOAD ---
func get_save_data() -> Dictionary:
	return {
		"relations": opec_relations,
		"active_deals": active_deals,
		"current_stance": current_opec_stance,
		"crisis_active": crisis_active,
		"current_crisis": current_crisis,
		"crisis_months_remaining": crisis_months_remaining,
		"triggered_crises": HISTORICAL_CRISES.filter(func(c): return c["triggered"]).map(func(c): return c["id"])
	}

func load_save_data(data: Dictionary):
	opec_relations = data.get("relations", {})
	active_deals = data.get("active_deals", [])
	current_opec_stance = data.get("current_stance", "moderate")
	crisis_active = data.get("crisis_active", false)
	current_crisis = data.get("current_crisis", {})
	crisis_months_remaining = data.get("crisis_months_remaining", 0)
	
	var triggered = data.get("triggered_crises", [])
	for crisis in HISTORICAL_CRISES:
		if crisis["id"] in triggered:
			crisis["triggered"] = true

extends Node
# AchievementManager.gd - Tracks player accomplishments and milestones

signal achievement_unlocked(achievement_id: String)

# --- ACHIEVEMENT DEFINITIONS ---
const ACHIEVEMENTS = {
	# Production Milestones
	"first_oil": {
		"title": "Erstes Öl",
		"description": "Bohre deinen ersten erfolgreichen Ölförderbrunnen",
		"icon": "res://assets/icons/achievement_oil.png",
		"category": "production",
		"hidden": false
	},
	"oil_baron": {
		"title": "Ölbaron",
		"description": "Erreiche eine Tagesförderung von 10.000 BBL",
		"icon": "res://assets/icons/achievement_barrel.png",
		"category": "production",
		"hidden": false,
		"target_value": 10000
	},
	"production_king": {
		"title": "Förderkönig",
		"description": "Erreiche eine Tagesförderung von 50.000 BBL",
		"icon": "res://assets/icons/achievement_barrel.png",
		"category": "production",
		"hidden": false,
		"target_value": 50000
	},
	
	# Financial Milestones
	"millionaire": {
		"title": "Millionär",
		"description": "Erreiche $1.000.000 Bargeld",
		"icon": "res://assets/icons/achievement_money.png",
		"category": "finance",
		"hidden": false,
		"target_value": 1000000
	},
	"ten_millionaire": {
		"title": "Multimillionär",
		"description": "Erreiche $10.000.000 Bargeld",
		"icon": "res://assets/icons/achievement_money.png",
		"category": "finance",
		"hidden": false,
		"target_value": 10000000
	},
	"hundred_millionaire": {
		"title": "Öl-Tycoon",
		"description": "Erreiche $100.000.000 Bargeld",
		"icon": "res://assets/icons/achievement_tycoon.png",
		"category": "finance",
		"hidden": false,
		"target_value": 100000000
	},
	"first_million_profit": {
		"title": "Erste Million",
		"description": "Erziele einen Monatsgewinn von $1.000.000",
		"icon": "res://assets/icons/achievement_profit.png",
		"category": "finance",
		"hidden": false
	},
	
	# Expansion Milestones
	"regional_presence": {
		"title": "Regionale Präsenz",
		"description": "Besitze Förderanlagen in 3 verschiedenen Regionen",
		"icon": "res://assets/icons/achievement_region.png",
		"category": "expansion",
		"hidden": false,
		"target_value": 3
	},
	"global_empire": {
		"title": "Globales Imperium",
		"description": "Besitze Förderanlagen in 5+ Regionen",
		"icon": "res://assets/icons/achievement_global.png",
		"category": "expansion",
		"hidden": false,
		"target_value": 5
	},
	"world_domination": {
		"title": "Weltherrschaft",
		"description": "Besitze Förderanlagen in allen verfügbaren Regionen",
		"icon": "res://assets/icons/achievement_world.png",
		"category": "expansion",
		"hidden": true
	},
	"offshore_pioneer": {
		"title": "Offshore-Pionier",
		"description": "Bohre deine erste Offshore-Quelle",
		"icon": "res://assets/icons/achievement_offshore.png",
		"category": "expansion",
		"hidden": false
	},
	
	# Technology Milestones
	"tech_first": {
		"title": "Forscher",
		"description": "Schalte deine erste Technologie frei",
		"icon": "res://assets/icons/achievement_tech.png",
		"category": "technology",
		"hidden": false
	},
	"tech_half": {
		"title": "Innovator",
		"description": "Schalte 50% aller Technologien frei",
		"icon": "res://assets/icons/achievement_tech.png",
		"category": "technology",
		"hidden": false,
		"target_value": 0.5
	},
	"tech_all": {
		"title": "Technologie-Vorreiter",
		"description": "Schalte alle Technologien frei",
		"icon": "res://assets/icons/achievement_tech_master.png",
		"category": "technology",
		"hidden": true
	},
	"era_80s": {
		"title": "Computer-Zeitalter",
		"description": "Upgrade in die 1980er Ära",
		"icon": "res://assets/icons/achievement_era80.png",
		"category": "technology",
		"hidden": false
	},
	"era_90s": {
		"title": "Moderne Zeiten",
		"description": "Upgrade in die 1990er+ Ära",
		"icon": "res://assets/icons/achievement_era90.png",
		"category": "technology",
		"hidden": false
	},
	
	# Contract & Sales
	"first_contract": {
		"title": "Vertragspartner",
		"description": "Unterzeichne deinen ersten Liefervertrag",
		"icon": "res://assets/icons/achievement_contract.png",
		"category": "business",
		"hidden": false
	},
	"contract_master": {
		"title": "Vertragsmeister",
		"description": "Habe gleichzeitig 5 aktive Verträge",
		"icon": "res://assets/icons/achievement_contracts.png",
		"category": "business",
		"hidden": false,
		"target_value": 5
	},
	"first_sale": {
		"title": "Erster Verkauf",
		"description": "Verkaufe Öl am Spotmarkt",
		"icon": "res://assets/icons/achievement_sale.png",
		"category": "business",
		"hidden": false
	},
	"storage_king": {
		"title": "Lagerkönig",
		"description": "Besitze eine Gesamtlagerkapazität von 5.000.000 BBL",
		"icon": "res://assets/icons/achievement_tank.png",
		"category": "business",
		"hidden": false,
		"target_value": 5000000
	},
	
	# Sabotage & Risk
	"saboteur": {
		"title": "Saboteur",
		"description": "Führe deine erste Sabotageaktion durch",
		"icon": "res://assets/icons/achievement_sabotage.png",
		"category": "risk",
		"hidden": true
	},
	"sabotage_victim": {
		"title": "Das Opfer",
		"description": "Werde Opfer einer erfolgreichen Sabotage",
		"icon": "res://assets/icons/achievement_victim.png",
		"category": "risk",
		"hidden": true
	},
	"survivor": {
		"title": "Überlebender",
		"description": "Überlebe 10 negative Zufallsereignisse",
		"icon": "res://assets/icons/achievement_survivor.png",
		"category": "risk",
		"hidden": false,
		"target_value": 10
	},
	
	# Time Milestones
	"decade_survivor": {
		"title": "Jahrzehnt",
		"description": "Spiele 10 Jahre oder länger",
		"icon": "res://assets/icons/achievement_time.png",
		"category": "time",
		"hidden": false
	},
	"veteran": {
		"title": "Veteran",
		"description": "Spiele 20 Jahre oder länger",
		"icon": "res://assets/icons/achievement_veteran.png",
		"category": "time",
		"hidden": false
	},
	
	# Special
	"dry_hole": {
		"title": "Trockenbrunnen",
		"description": "Bohre 5 trockene Löcher hintereinander",
		"icon": "res://assets/icons/achievement_dry.png",
		"category": "special",
		"hidden": true
	},
	"lucky_streak": {
		"title": "Glückliche Serie",
		"description": "Bohre 5 erfolgreiche Quellen hintereinander",
		"icon": "res://assets/icons/achievement_lucky.png",
		"category": "special",
		"hidden": true
	}
}

# --- UNLOCKED ACHIEVEMENTS ---
var unlocked_achievements: Array = []
var achievement_progress: Dictionary = {}

# --- TRACKING VARIABLES ---
var consecutive_dry_holes: int = 0
var consecutive_successes: int = 0
var negative_events_survived: int = 0

# --- REFERENCE ---
var game_manager = null
var activity_feed = null

func _ready():
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
	if has_node("/root/ActivityFeed"):
		activity_feed = get_node("/root/ActivityFeed")
	
	# Initialize progress tracking
	for ach_id in ACHIEVEMENTS:
		achievement_progress[ach_id] = 0

# --- CHECK ACHIEVEMENTS ---
func check_all_achievements():
	if game_manager == null:
		return
	
	_check_financial_achievements()
	_check_production_achievements()
	_check_expansion_achievements()
	_check_technology_achievements()
	_check_business_achievements()
	_check_time_achievements()

func _check_financial_achievements():
	var cash = game_manager.cash
	
	# Millionaire milestones
	if cash >= 1000000:
		unlock("millionaire")
	if cash >= 10000000:
		unlock("ten_millionaire")
	if cash >= 100000000:
		unlock("hundred_millionaire")

func _check_production_achievements():
	var total_production = 0.0
	var active_regions = 0
	
	for region_name in game_manager.regions:
		var region = game_manager.regions[region_name]
		if region == null: continue
		
		var has_well = false
		for claim in region.get("claims", []):
			if claim.get("owned", false) and claim.get("drilled", false):
				if claim.get("has_oil", false):
					total_production += claim.get("yield", 0)
					has_well = true
		
		if has_well:
			active_regions += 1
	
	# Production achievements
	if total_production >= 10000:
		unlock("oil_baron")
	if total_production >= 50000:
		unlock("production_king")
	
	# Expansion achievements
	if active_regions >= 3:
		unlock("regional_presence")
	if active_regions >= 5:
		unlock("global_empire")

func _check_expansion_achievements():
	# Check for offshore well
	for region_name in game_manager.regions:
		var region = game_manager.regions[region_name]
		if region == null: continue
		
		for claim in region.get("claims", []):
			if claim.get("owned", false) and claim.get("drilled", false):
				if claim.get("is_offshore", false) and claim.get("has_oil", false):
					unlock("offshore_pioneer")
					break

func _check_technology_achievements():
	var tech_count = game_manager.unlocked_techs.size()
	var total_tech = game_manager.tech_database.size()
	
	if tech_count >= 1:
		unlock("tech_first")
	
	if total_tech > 0 and float(tech_count) / float(total_tech) >= 0.5:
		unlock("tech_half")
	
	if tech_count >= total_tech:
		unlock("tech_all")
	
	# Era achievements
	if game_manager.current_era >= 1:
		unlock("era_80s")
	if game_manager.current_era >= 2:
		unlock("era_90s")

func _check_business_achievements():
	# Contracts
	var active_contracts = game_manager.active_supply_contracts.size()
	if active_contracts >= 1:
		unlock("first_contract")
	if active_contracts >= 5:
		unlock("contract_master")
	
	# Tank capacity
	var total_tank = 0
	for region_name in game_manager.tank_capacity:
		total_tank += game_manager.tank_capacity[region_name]
	
	if total_tank >= 5000000:
		unlock("storage_king")

func _check_time_achievements():
	var years_played = game_manager.date["year"] - 1970
	if years_played >= 10:
		unlock("decade_survivor")
	if years_played >= 20:
		unlock("veteran")

# --- EVENT HANDLERS ---
func on_drilling_complete(success: bool, is_offshore: bool):
	if success:
		unlock("first_oil")
		consecutive_successes += 1
		consecutive_dry_holes = 0
		
		if consecutive_successes >= 5:
			unlock("lucky_streak")
		
		if is_offshore:
			unlock("offshore_pioneer")
	else:
		consecutive_dry_holes += 1
		consecutive_successes = 0
		
		if consecutive_dry_holes >= 5:
			unlock("dry_hole")

func on_sabotage_performed(is_player: bool):
	if is_player:
		unlock("saboteur")
	else:
		unlock("sabotage_victim")

func on_negative_event():
	negative_events_survived += 1
	if negative_events_survived >= 10:
		unlock("survivor")

func on_oil_sale():
	unlock("first_sale")

func on_month_end():
	# Check for profit milestone
	if game_manager and game_manager.history_profit.size() > 0:
		var last_profit = game_manager.history_profit[-1]
		if last_profit >= 1000000:
			unlock("first_million_profit")
	
	# Check all achievements
	check_all_achievements()

# --- UNLOCK FUNCTION ---
func unlock(achievement_id: String):
	if not ACHIEVEMENTS.has(achievement_id):
		return
	
	if achievement_id in unlocked_achievements:
		return
	
	unlocked_achievements.append(achievement_id)
	achievement_unlocked.emit(achievement_id)
	
	var ach = ACHIEVEMENTS[achievement_id]
	var msg = "=== ERFOLG FREIGESCHALTET ===\n\n"
	msg += ach["title"] + "\n"
	msg += ach["description"]
	
	if has_node("/root/FeedbackOverlay"):
		get_node("/root/FeedbackOverlay").show_msg(msg, Color.GOLD)
	
	# Log to activity feed
	if activity_feed:
		activity_feed.log_activity(activity_feed.ACTIVITY_TYPE.PLAYER_ACHIEVEMENT, {
			"title": ach["title"],
			"description": ach["description"]
		})
	
	print("[ACHIEVEMENT] Unlocked: " + ach["title"])

# --- PROGRESS TRACKING ---
func update_progress(achievement_id: String, current_value: float):
	if achievement_id in unlocked_achievements:
		return
	
	achievement_progress[achievement_id] = current_value
	
	var ach = ACHIEVEMENTS.get(achievement_id, {})
	if ach.has("target_value"):
		if current_value >= ach["target_value"]:
			unlock(achievement_id)

func get_progress(achievement_id: String) -> Dictionary:
	var ach = ACHIEVEMENTS.get(achievement_id, {})
	var current = achievement_progress.get(achievement_id, 0)
	var target = ach.get("target_value", 0)
	
	return {
		"current": current,
		"target": target,
		"percentage": (current / target * 100) if target > 0 else 100
	}

# --- GET ACHIEVEMENTS BY CATEGORY ---
func get_achievements_by_category(category: String) -> Array:
	var result = []
	for ach_id in ACHIEVEMENTS:
		if ACHIEVEMENTS[ach_id]["category"] == category:
			result.append({
				"id": ach_id,
				"unlocked": ach_id in unlocked_achievements,
				"data": ACHIEVEMENTS[ach_id]
			})
	return result

func get_all_categories() -> Array:
	return ["production", "finance", "expansion", "technology", "business", "risk", "time", "special"]

func get_unlocked_count() -> int:
	return unlocked_achievements.size()

func get_total_count() -> int:
	return ACHIEVEMENTS.size()

# --- SAVE/LOAD ---
func get_save_data() -> Dictionary:
	return {
		"unlocked": unlocked_achievements,
		"progress": achievement_progress,
		"consecutive_dry": consecutive_dry_holes,
		"consecutive_success": consecutive_successes,
		"negative_events": negative_events_survived
	}

func load_save_data(data: Dictionary):
	unlocked_achievements = data.get("unlocked", [])
	achievement_progress = data.get("progress", {})
	consecutive_dry_holes = data.get("consecutive_dry", 0)
	consecutive_successes = data.get("consecutive_success", 0)
	negative_events_survived = data.get("negative_events", 0)

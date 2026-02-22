extends Node
# EraManager.gd - Handles decade-based technology and visual evolution
# The game evolves from 1970s text-based interfaces to modern graphical systems

signal era_upgraded(new_era: int)

# --- ERA DEFINITIONS ---
# Era 0: 1970s - Text-only, limited tech, monochrome displays
# Era 1: 1980s - Basic graphics, color displays, more tech options
# Era 2: 1990s+ - Modern GUI, advanced graphics, full tech tree

const ERA_DATA = {
	0: {
		"name": "1970s - Pionier-Ära",
		"description": "Textbasierte Systeme, begrenzte Technologie",
		"year_start": 1970,
		"year_end": 1981,
		"tech_tree_style": "text",  # Text-only display
		"computer_style": "terminal",  # Monochrome terminal
		"office_style": "vintage",
		"available_display_cols": 1,  # Single column tech list
		"tech_cost_multiplier": 1.0,
		"survey_base_accuracy": 0.3,  # 30% base inaccuracy
		"max_tank_size": 1000000,  # Limited tank capacity
		"offshore_available": false,  # No offshore in early game
		"graphics": {
			"terminal_color": Color(0.2, 1.0, 0.2),  # Phosphor green
			"background_color": Color(0, 0, 0),
			"show_icons": false,
			"show_animations": false
		}
	},
	1: {
		"name": "1980s - Computer-Revolution",
		"description": "Einfache Grafiken, Farbbildschirme, erweiterte Optionen",
		"year_start": 1982,
		"year_end": 1994,
		"tech_tree_style": "basic_graphical",  # Simple icons and borders
		"computer_style": "crt_color",  # Color CRT
		"office_style": "modern",
		"available_display_cols": 2,  # Two column tech display
		"tech_cost_multiplier": 2.5,  # More expensive tech
		"survey_base_accuracy": 0.2,  # Better surveys
		"max_tank_size": 2500000,
		"offshore_available": true,  # Offshore now available
		"graphics": {
			"terminal_color": Color(0.4, 0.8, 1.0),  # Blue-ish
			"background_color": Color(0.05, 0.05, 0.2),
			"show_icons": true,
			"show_animations": false
		}
	},
	2: {
		"name": "1990s+ - Moderne Ära",
		"description": "Moderne GUI, fortschrittliche Grafiken, volle Technologie",
		"year_start": 1995,
		"year_end": 9999,
		"tech_tree_style": "modern_graphical",  # Full GUI with icons
		"computer_style": "lcd_modern",  # Modern flat panel
		"office_style": "hightech",
		"available_display_cols": 3,  # Full grid display
		"tech_cost_multiplier": 5.0,  # Much more expensive
		"survey_base_accuracy": 0.15,  # Best surveys (still not perfect!)
		"max_tank_size": 5000000,
		"offshore_available": true,
		"graphics": {
			"terminal_color": Color(1, 1, 1),  # White
			"background_color": Color(0.1, 0.1, 0.15),
			"show_icons": true,
			"show_animations": true
		}
	}
}

# --- ERA UPGRADE COSTS (Very expensive - player must save!) ---
const ERA_UPGRADE_COSTS = {
	# Era 0->1: 1970s to 1980s upgrade
	0: {
		"cash": 7500000,  # $7.5 million
		"description": "Computer-System Upgrade\nTerminal -> Farb-CRT\nKosten: $7.500.000"
	},
	# Era 1->2: 1980s to 1990s upgrade  
	1: {
		"cash": 25000000,  # $25 million - very expensive!
		"description": "High-Tech Upgrade\nCRT -> LCD-Display\nKosten: $25.000.000"
	}
}

# --- REFERENCE TO GAME MANAGER ---
var game_manager = null

func _ready():
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

# --- ERA HELPER FUNCTIONS ---
func get_current_era_data() -> Dictionary:
	if game_manager == null:
		return ERA_DATA[0]
	return ERA_DATA.get(game_manager.current_era, ERA_DATA[0])

func get_era_for_year(year: int) -> int:
	for era_id in ERA_DATA:
		var era = ERA_DATA[era_id]
		if year >= era["year_start"] and year <= era["year_end"]:
			return era_id
	return 2  # Default to modern era

func can_upgrade_era() -> Dictionary:
	if game_manager == null:
		return {"can_upgrade": false, "reason": "No game manager"}
	
	var current_era = game_manager.current_era
	var year = game_manager.date["year"]
	
	# Check if there's a next era
	if not ERA_UPGRADE_COSTS.has(current_era):
		return {"can_upgrade": false, "reason": "Maximale Ära erreicht"}
	
	var next_era = current_era + 1
	if not ERA_DATA.has(next_era):
		return {"can_upgrade": false, "reason": "Keine weitere Ära verfügbar"}
	
	# Check year requirement
	var era_info = ERA_DATA[next_era]
	if year < era_info["year_start"]:
		return {"can_upgrade": false, "reason": "Jahr noch nicht erreicht (ab %d)" % era_info["year_start"]}
	
	# Check cost
	var cost = ERA_UPGRADE_COSTS[current_era]["cash"]
	if game_manager.cash < cost:
		return {"can_upgrade": false, "reason": "Nicht genug Geld ($%d benötigt)" % cost}
	
	return {
		"can_upgrade": true, 
		"reason": "Upgrade verfügbar!",
		"cost": cost,
		"next_era": next_era
	}

func perform_era_upgrade() -> bool:
	var upgrade_check = can_upgrade_era()
	if not upgrade_check["can_upgrade"]:
		return false
	
	var cost = upgrade_check["cost"]
	var next_era = upgrade_check["next_era"]
	
	# Deduct cost
	game_manager.cash -= cost
	game_manager.current_era = next_era
	
	# Book transaction
	game_manager.book_transaction("Global", -cost, "Technology Upgrade")
	
	# Emit signal
	era_upgraded.emit(next_era)
	
	return true

# --- TECH TREE STYLING ---
func get_tech_tree_style() -> String:
	return get_current_era_data()["tech_tree_style"]

func should_show_tech_icons() -> bool:
	return get_current_era_data()["graphics"]["show_icons"]

func should_show_animations() -> bool:
	return get_current_era_data()["graphics"]["show_animations"]

func get_tech_display_columns() -> int:
	return get_current_era_data()["available_display_cols"]

# --- ERA-SPECIFIC COSTS ---
func get_adjusted_tech_cost(base_cost: float) -> float:
	var multiplier = get_current_era_data()["tech_cost_multiplier"]
	# Later eras have more expensive tech
	return base_cost * multiplier

func get_adjusted_survey_accuracy() -> float:
	return get_current_era_data()["survey_base_accuracy"]

func get_max_tank_size() -> int:
	return get_current_era_data()["max_tank_size"]

func is_offshore_available() -> bool:
	return get_current_era_data()["offshore_available"]

# --- GRAPHICS HELPERS ---
func get_terminal_color() -> Color:
	return get_current_era_data()["graphics"]["terminal_color"]

func get_background_color() -> Color:
	return get_current_era_data()["graphics"]["background_color"]

func get_era_name() -> String:
	return get_current_era_data()["name"]

# --- SAVE/LOAD ---
func get_save_data() -> Dictionary:
	return {
		"current_era": game_manager.current_era if game_manager else 0
	}

func load_save_data(data: Dictionary):
	if game_manager and data.has("current_era"):
		game_manager.current_era = data["current_era"]

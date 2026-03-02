extends Node
# EraManager.gd - Handles decade-based technology and visual evolution
# The game evolves from 1970s text-based interfaces to modern graphical systems

signal era_upgraded(new_era: int)

# --- ERA DEFINITIONS ---
# Era 0: 1970s - Text-only, limited tech, monochrome displays
# Era 1: 1980s - Basic graphics, color displays, more tech options
# Era 2: 1990s+ - Modern GUI, advanced graphics, full tech tree

# --- NEWS MEDIA TYPES ---
enum NewsMedia {
	NEWSPAPER_1970S,        # Classic black & white newspaper
	NEWSPAPER_1980S,        # Color newspaper with photos
	TV_NEWS_1990S,          # OilNN TV news channel
	ONLINE_PORTAL_2000S     # OilNN.com website
}

# --- COMPUTER UI STYLES ---
enum ComputerUI {
	PHOSPHOR_TERMINAL,      # 1970s: Black/Green terminal
	AMIGA_WORKBENCH,        # 1980s: Amiga-style desktop
	WINDOWS_95,             # 1990s: Windows 95 style
	MODERN_WEB                      # 2000s+: Modern web-style
}

const ERA_DATA = {
	0: {
		"name": "1970s - Pionier-Aera",
		"description": "Textbasierte Systeme, begrenzte Technologie",
		"year_start": 1970,
		"year_end": 1981,
		"tech_tree_style": "text",
		"computer_style": "terminal",
		"computer_ui": ComputerUI.PHOSPHOR_TERMINAL,
		"news_media": NewsMedia.NEWSPAPER_1970S,
		"news_media_name": "THE DAILY BARREL",
		"office_style": "vintage",
		"office_bg": "res://assets/office/office_1970s.png",
		"computer_bg": "res://assets/computer/computer_1970s.png",
		"available_display_cols": 1,
		"tech_cost_multiplier": 1.0,
		"survey_base_accuracy": 0.3,
		"max_tank_size": 1000000,
		"offshore_available": false,
		"graphics": {
			"terminal_color": Color(0.2, 1.0, 0.2),
			"background_color": Color(0, 0, 0),
			"accent_color": Color(0.2, 1.0, 0.2),
			"text_color": Color(0.2, 1.0, 0.2),
			"show_icons": false,
			"show_animations": false
		}
	},
	1: {
		"name": "1980s - Computer-Revolution",
		"description": "Einfache Grafiken, Farbbildschirme, erweiterte Optionen",
		"year_start": 1982,
		"year_end": 1994,
		"tech_tree_style": "basic_graphical",
		"computer_style": "crt_color",
		"computer_ui": ComputerUI.AMIGA_WORKBENCH,
		"news_media": NewsMedia.NEWSPAPER_1980S,
		"news_media_name": "THE DAILY BARREL",
		"office_style": "modern",
		"office_bg": "res://assets/office/office_1980s.png",
		"computer_bg": "res://assets/computer/computer_1980s.png",
		"available_display_cols": 2,
		"tech_cost_multiplier": 2.5,
		"survey_base_accuracy": 0.2,
		"max_tank_size": 2500000,
		"offshore_available": true,
		"graphics": {
			"terminal_color": Color(0.4, 0.8, 1.0),
			"background_color": Color(0.05, 0.05, 0.2),
			"accent_color": Color(1.0, 0.5, 0.0),
			"text_color": Color(0.9, 0.9, 0.9),
			"show_icons": true,
			"show_animations": false
		}
	},
	2: {
		"name": "1990s - Multimedia-Zeitalter",
		"description": "Moderne GUI, fortschrittliche Grafiken, volle Technologie",
		"year_start": 1995,
		"year_end": 1999,
		"tech_tree_style": "modern_graphical",
		"computer_style": "lcd_modern",
		"computer_ui": ComputerUI.WINDOWS_95,
		"news_media": NewsMedia.TV_NEWS_1990S,
		"news_media_name": "OilNN",
		"office_style": "hightech",
		"office_bg": "res://assets/office/office_1990s.png",
		"computer_bg": "res://assets/computer/computer_1990s.png",
		"available_display_cols": 3,
		"tech_cost_multiplier": 5.0,
		"survey_base_accuracy": 0.15,
		"max_tank_size": 5000000,
		"offshore_available": true,
		"graphics": {
			"terminal_color": Color(1, 1, 1),
			"background_color": Color(0.0, 0.5, 0.8),
			"accent_color": Color(0.0, 0.8, 0.0),
			"text_color": Color(0, 0, 0),
			"show_icons": true,
			"show_animations": true
		}
	},
	3: {
		"name": "2000s - Internet-Aera",
		"description": "Online-Portale, globale Vernetzung, High-Tech",
		"year_start": 2000,
		"year_end": 9999,
		"tech_tree_style": "modern_graphical",
		"computer_style": "web_portal",
		"computer_ui": ComputerUI.MODERN_WEB,
		"news_media": NewsMedia.ONLINE_PORTAL_2000S,
		"news_media_name": "OilNN.com",
		"office_style": "futuristic",
		"office_bg": "res://assets/office/office_2000s.png",
		"computer_bg": "res://assets/computer/computer_2000s.png",
		"available_display_cols": 4,
		"tech_cost_multiplier": 8.0,
		"survey_base_accuracy": 0.1,
		"max_tank_size": 10000000,
		"offshore_available": true,
		"graphics": {
			"terminal_color": Color(0.1, 0.3, 0.8),
			"background_color": Color(0.95, 0.95, 1.0),
			"accent_color": Color(0.0, 0.5, 0.9),
			"text_color": Color(0.1, 0.1, 0.2),
			"show_icons": true,
			"show_animations": true
		}
	}
}

# --- ERA UPGRADE COSTS ---
const ERA_UPGRADE_COSTS = {
	0: {
		"cash": 7500000,
		"description": "Computer-System Upgrade\nTerminal -> Farb-CRT (Amiga Workbench)\nNachrichtensystem: Farbige Zeitung\nKosten: $7.500.000"
	},
	1: {
		"cash": 25000000,
		"description": "High-Tech Upgrade\nCRT -> LCD-Display (Windows 95)\nNachrichtensystem: OilNN TV-Nachrichten\nKosten: $25.000.000"
	},
	2: {
		"cash": 50000000,
		"description": "Internet-Zeitalter Upgrade\nLCD -> Web-Portal\nNachrichtensystem: OilNN.com Online-Portal\nKosten: $50.000.000"
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

# --- NEWS MEDIA HELPERS ---
func get_news_media_type() -> int:
	return get_current_era_data()["news_media"]

func get_news_media_name() -> String:
	return get_current_era_data()["news_media_name"]

func is_newspaper_era() -> bool:
	var media = get_news_media_type()
	return media == NewsMedia.NEWSPAPER_1970S or media == NewsMedia.NEWSPAPER_1980S

func is_tv_news_era() -> bool:
	return get_news_media_type() == NewsMedia.TV_NEWS_1990S

func is_online_portal_era() -> bool:
	return get_news_media_type() == NewsMedia.ONLINE_PORTAL_2000S

# --- COMPUTER UI HELPERS ---
func get_computer_ui_type() -> int:
	return get_current_era_data()["computer_ui"]

func get_office_background_path() -> String:
	return get_current_era_data()["office_bg"]

func get_computer_background_path() -> String:
	return get_current_era_data()["computer_bg"]

func get_accent_color() -> Color:
	return get_current_era_data()["graphics"]["accent_color"]

func get_text_color() -> Color:
	return get_current_era_data()["graphics"]["text_color"]

# --- ERA INFO ---
func get_era_description() -> String:
	return get_current_era_data()["description"]

func get_upgrade_description() -> String:
	var current = game_manager.current_era if game_manager else 0
	if ERA_UPGRADE_COSTS.has(current):
		return ERA_UPGRADE_COSTS[current]["description"]
	return "Kein weiteres Upgrade verfuegbar"

# --- SAVE/LOAD ---
func get_save_data() -> Dictionary:
	return {
		"current_era": game_manager.current_era if game_manager else 0
	}

func load_save_data(data: Dictionary):
	if game_manager and data.has("current_era"):
		game_manager.current_era = data["current_era"]

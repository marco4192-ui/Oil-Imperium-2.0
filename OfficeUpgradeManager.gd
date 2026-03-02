extends Node
# OfficeUpgradeManager.gd - Detailliertes Büro-Upgrade-System
# Jede Ära hat ein teures Haupt-Upgrade + optionale Module
# Alle Module müssen für Ära-Wechsel abgeschlossen sein

signal office_upgraded(upgrade_id: String)
signal module_purchased(module_id: String)
signal all_modules_complete(era: int)

# ==============================================================================
# BÜRO-UPGRADE DEFINITIONEN
# ==============================================================================

# Haupt-Upgrades pro Ära (extrem teuer, Freischaltung der Module)
const MAIN_UPGRADES = {
	0: {  # 1970s → 1980s
		"id": "mainframe_computer",
		"name": "Mainframe-Computer System",
		"description": "Installation eines zentralen Mainframe-Computers. Ermöglicht digitale Datenverarbeitung und erweiterte Analyse-Tools.",
		"cost": 5000000,
		"required_year": 1978,
		"unlock_modules": ["terminal_upgrade", "digital_storage", "automated_reports", "network_connection"]
	},
	1: {  # 1980s → 1990s
		"id": "multimedia_center",
		"name": "Multimedia-Kommunikationszentrum",
		"description": "Staatliches Multimedia-Center mit Satellitenverbindung, Echtzeit-Daten und globaler Vernetzung.",
		"cost": 25000000,
		"required_year": 1992,
		"unlock_modules": ["satellite_link", "realtime_data", "video_conference", "digital_archives"]
	},
	2: {  # 1990s → 2000s
		"id": "internet_infrastructure",
		"name": "Internet-Infrastruktur",
		"description": "Vollständige Internet-Anbindung mit Web-Portal, E-Commerce und Cloud-Systemen.",
		"cost": 75000000,
		"required_year": 1998,
		"unlock_modules": ["web_portal", "e_commerce", "cloud_storage", "mobile_access"]
	},
	3: {  # 2000s → Future
		"id": "ai_integration",
		"name": "KI-Integrationszentrum",
		"description": "Künstliche Intelligenz für prädiktive Analysen, automatisierte Entscheidungen und globale Optimierung.",
		"cost": 200000000,
		"required_year": 2005,
		"unlock_modules": ["predictive_ai", "automation_hub", "quantum_analysis", "global_network"]
	}
}

# Optionale Module pro Ära (müssen alle gekauft werden für Ära-Wechsel)
const UPGRADE_MODULES = {
	# 1970s → 1980s Module
	"terminal_upgrade": {
		"name": "Terminal-Erweiterung",
		"description": "Zusätzliche Terminals für Mitarbeiter. Schnellere Informationsverteilung.",
		"cost": 500000,
		"effect": {"employee_efficiency": 1.1},
		"visual_change": "more_terminals"
	},
	"digital_storage": {
		"name": "Digitale Datenspeicherung",
		"description": "Magnetband-Archive für historische Daten. Schnellerer Zugriff auf Berichte.",
		"cost": 750000,
		"effect": {"data_access_speed": 1.2, "save_slots": 10},
		"visual_change": "tape_drives"
	},
	"automated_reports": {
		"name": "Automatisierte Berichte",
		"description": "Computer-generierte Monatsberichte. Weniger manuelle Arbeit.",
		"cost": 300000,
		"effect": {"report_accuracy": 1.15, "admin_cost_reduction": 0.9},
		"visual_change": "report_printer"
	},
	"network_connection": {
		"name": "Netzwerk-Anbindung",
		"description": "Verbindung zu Boersen-Datenbanken. Echtzeit-Informationen.",
		"cost": 1200000,
		"effect": {"market_info_speed": 2.0},
		"visual_change": "network_cables"
	},
	
	# 1980s → 1990s Module
	"satellite_link": {
		"name": "Satelliten-Verbindung",
		"description": "Direkte Verbindung zu globalen Nachrichtensatelliten. OilNN-Empfang.",
		"cost": 3000000,
		"effect": {"news_speed": 3.0, "oilnn_access": true},
		"visual_change": "satellite_dish"
	},
	"realtime_data": {
		"name": "Echtzeit-Daten-Feed",
		"description": "Live-Oelpreise und Marktdaten ohne Verzoegerung.",
		"cost": 2500000,
		"effect": {"price_update_speed": 5.0, "market_advantage": 1.1},
		"visual_change": "data_screens"
	},
	"video_conference": {
		"name": "Video-Konferenz-System",
		"description": "Bildtelefonie mit Geschaftspartnern weltweit.",
		"cost": 1500000,
		"effect": {"contract_negotiation_bonus": 1.15},
		"visual_change": "video_screen"
	},
	"digital_archives": {
		"name": "Digitale Archive",
		"description": "Alle historischen Daten digital durchsuchbar.",
		"cost": 2000000,
		"effect": {"research_speed": 1.25, "historical_accuracy": 1.2},
		"visual_change": "server_rack"
	},
	
	# 1990s → 2000s Module
	"web_portal": {
		"name": "Web-Portal",
		"description": "Eigene Firmen-Website fuer Kunden und Investoren.",
		"cost": 8000000,
		"effect": {"reputation": 10, "customer_reach": 2.0},
		"visual_change": "web_display"
	},
	"e_commerce": {
		"name": "E-Commerce-Plattform",
		"description": "Online-Oelhandel direkt ueber das Internet.",
		"cost": 12000000,
		"effect": {"sales_bonus": 1.1, "new_markets": true},
		"visual_change": "ecommerce_terminal"
	},
	"cloud_storage": {
		"name": "Cloud-Datenspeicherung",
		"description": "Backup aller Daten in der Cloud. Sicherheit bei Katastrophen.",
		"cost": 5000000,
		"effect": {"data_security": 1.5, "disaster_recovery": true},
		"visual_change": "cloud_icon"
	},
	"mobile_access": {
		"name": "Mobiles Büro",
		"description": "Zugriff von überall via Laptop und Handy.",
		"cost": 6000000,
		"effect": {"flexibility": 2.0, "response_time": 0.5},
		"visual_change": "mobile_devices"
	},
	
	# 2000s → Future Module
	"predictive_ai": {
		"name": "Praediktive KI",
		"description": "Kuenstliche Intelligenz fuer Markt-Vorhersagen.",
		"cost": 50000000,
		"effect": {"price_prediction": 0.85, "risk_assessment": 1.3},
		"visual_change": "ai_hologram"
	},
	"automation_hub": {
		"name": "Automatisierungs-Zentrale",
		"description": "KI-gesteuerte Bohrungen und Logistik.",
		"cost": 40000000,
		"effect": {"production_efficiency": 1.2, "cost_reduction": 0.85},
		"visual_change": "automation_screens"
	},
	"quantum_analysis": {
		"name": "Quanten-Analyse",
		"description": "Quantencomputer fuer komplexe Simulationen.",
		"cost": 75000000,
		"effect": {"survey_accuracy": 0.95, "discovery_chance": 1.5},
		"visual_change": "quantum_core"
	},
	"global_network": {
		"name": "Globales Netzwerk",
		"description": "Vernetzung aller Foerderanlagen weltweit.",
		"cost": 35000000,
		"effect": {"global_synergy": 1.25, "crisis_response": 2.0},
		"visual_change": "global_map"
	}
}

# ==============================================================================
# STATE
# ==============================================================================

var game_manager = null
var purchased_main_upgrades: Dictionary = {}  # era -> bool
var purchased_modules: Dictionary = {}  # module_id -> bool
var current_era_modules: Array = []  # Aktive Module der aktuellen Ära

func _ready():
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

# ==============================================================================
# HAUPT-UPGRADE LOGIC
# ==============================================================================

func can_purchase_main_upgrade() -> Dictionary:
	if game_manager == null:
		return {"can_purchase": false, "reason": "No game manager"}
	
	var current_era = game_manager.current_era
	var year = game_manager.date["year"]
	
	if purchased_main_upgrades.get(current_era, false):
		return {"can_purchase": false, "reason": "Haupt-Upgrade bereits durchgefuehrt"}
	
	if not MAIN_UPGRADES.has(current_era):
		return {"can_purchase": false, "reason": "Kein weiteres Upgrade verfuegbar"}
	
	var upgrade = MAIN_UPGRADES[current_era]
	
	if year < upgrade["required_year"]:
		return {"can_purchase": false, "reason": "Benötigt Jahr %d oder spaeter" % upgrade["required_year"]}
	
	if game_manager.cash < upgrade["cost"]:
		return {"can_purchase": false, "reason": "Nicht genug Geld ($%d benoetigt)" % upgrade["cost"]}
	
	return {
		"can_purchase": true,
		"reason": "Upgrade verfuegbar!",
		"upgrade": upgrade,
		"cost": upgrade["cost"]
	}

func purchase_main_upgrade() -> bool:
	var check = can_purchase_main_upgrade()
	if not check["can_purchase"]:
		return false
	
	var current_era = game_manager.current_era
	var upgrade = MAIN_UPGRADES[current_era]
	
	game_manager.cash -= upgrade["cost"]
	game_manager.book_transaction("Global", -upgrade["cost"], "Buro-Hauptupgrade")
	
	purchased_main_upgrades[current_era] = true
	office_upgraded.emit(upgrade["id"])
	
	return true

# ==============================================================================
# MODULE LOGIC
# ==============================================================================

func can_purchase_module(module_id: String) -> Dictionary:
	if game_manager == null:
		return {"can_purchase": false, "reason": "No game manager"}
	
	if not UPGRADE_MODULES.has(module_id):
		return {"can_purchase": false, "reason": "Unbekanntes Modul"}
	
	if purchased_modules.get(module_id, false):
		return {"can_purchase": false, "reason": "Modul bereits gekauft"}
	
	var current_era = game_manager.current_era
	if not purchased_main_upgrades.get(current_era, false):
		return {"can_purchase": false, "reason": "Zuerst Haupt-Upgrade durchfuehren"}
	
	var main_upgrade = MAIN_UPGRADES.get(current_era, {})
	var unlocked_modules = main_upgrade.get("unlock_modules", [])
	if module_id not in unlocked_modules:
		return {"can_purchase": false, "reason": "Modul nicht fuer diese Aera verfuegbar"}
	
	var module = UPGRADE_MODULES[module_id]
	if game_manager.cash < module["cost"]:
		return {"can_purchase": false, "reason": "Nicht genug Geld ($%d benoetigt)" % module["cost"]}
	
	return {
		"can_purchase": true,
		"reason": "Modul verfuegbar!",
		"module": module,
		"cost": module["cost"]
	}

func purchase_module(module_id: String) -> bool:
	var check = can_purchase_module(module_id)
	if not check["can_purchase"]:
		return false
	
	var module = UPGRADE_MODULES[module_id]
	
	game_manager.cash -= module["cost"]
	game_manager.book_transaction("Global", -module["cost"], "Buro-Modul: " + module["name"])
	
	purchased_modules[module_id] = true
	current_era_modules.append(module_id)
	
	_apply_module_effects(module["effect"])
	module_purchased.emit(module_id)
	_check_all_modules_complete()
	
	return true

func _apply_module_effects(effects: Dictionary):
	for effect_key in effects:
		var value = effects[effect_key]
		match effect_key:
			"employee_efficiency":
				game_manager.set_meta("employee_efficiency", game_manager.get_meta("employee_efficiency", 1.0) * value)
			"production_efficiency":
				game_manager.tech_bonus_production *= value
			"cost_reduction":
				game_manager.global_cost_multiplier *= value
			"reputation":
				game_manager.set_meta("reputation_bonus", game_manager.get_meta("reputation_bonus", 0) + value)

func _check_all_modules_complete():
	var current_era = game_manager.current_era
	var main_upgrade = MAIN_UPGRADES.get(current_era, {})
	var required_modules = main_upgrade.get("unlock_modules", [])
	
	var all_complete = true
	for module_id in required_modules:
		if not purchased_modules.get(module_id, false):
			all_complete = false
			break
	
	if all_complete and purchased_main_upgrades.get(current_era, false):
		all_modules_complete.emit(current_era)

# ==============================================================================
# ERA ADVANCEMENT CHECK
# ==============================================================================

func can_advance_era() -> Dictionary:
	if game_manager == null:
		return {"can_advance": false, "reason": "No game manager"}
	
	var current_era = game_manager.current_era
	
	if not MAIN_UPGRADES.has(current_era):
		return {"can_advance": false, "reason": "Maximale Aera erreicht"}
	
	if not purchased_main_upgrades.get(current_era, false):
		return {"can_advance": false, "reason": "Haupt-Upgrade noch nicht durchgefuehrt"}
	
	var main_upgrade = MAIN_UPGRADES[current_era]
	var required_modules = main_upgrade["unlock_modules"]
	var missing_modules = []
	
	for module_id in required_modules:
		if not purchased_modules.get(module_id, false):
			missing_modules.append(UPGRADE_MODULES[module_id]["name"])
	
	if missing_modules.size() > 0:
		return {"can_advance": false, "reason": "Fehlende Module: " + ", ".join(missing_modules)}
	
	var year = game_manager.date["year"]
	if year < main_upgrade["required_year"]:
		return {"can_advance": false, "reason": "Jahr %d erforderlich" % main_upgrade["required_year"]}
	
	return {"can_advance": true, "reason": "Aera-Wechsel moeglich!", "next_era": current_era + 1}

# ==============================================================================
# GETTERS
# ==============================================================================

func get_available_modules() -> Array:
	if game_manager == null:
		return []
	
	var current_era = game_manager.current_era
	if not purchased_main_upgrades.get(current_era, false):
		return []
	
	var main_upgrade = MAIN_UPGRADES.get(current_era, {})
	var all_modules = main_upgrade.get("unlock_modules", [])
	var available = []
	
	for module_id in all_modules:
		if not purchased_modules.get(module_id, false):
			available.append({"id": module_id, "data": UPGRADE_MODULES[module_id]})
	
	return available

func get_module_progress() -> Dictionary:
	if game_manager == null:
		return {"purchased": 0, "total": 0, "percent": 0}
	
	var current_era = game_manager.current_era
	var main_upgrade = MAIN_UPGRADES.get(current_era, {})
	var required_modules = main_upgrade.get("unlock_modules", [])
	
	var purchased = 0
	for module_id in required_modules:
		if purchased_modules.get(module_id, false):
			purchased += 1
	
	return {
		"purchased": purchased,
		"total": required_modules.size(),
		"percent": float(purchased) / float(required_modules.size()) * 100.0 if required_modules.size() > 0 else 0
	}

# ==============================================================================
# SAVE/LOAD
# ==============================================================================

func get_save_data() -> Dictionary:
	return {
		"purchased_main_upgrades": purchased_main_upgrades,
		"purchased_modules": purchased_modules,
		"current_era_modules": current_era_modules
	}

func load_save_data(data: Dictionary):
	purchased_main_upgrades = data.get("purchased_main_upgrades", {})
	purchased_modules = data.get("purchased_modules", {})
	current_era_modules = data.get("current_era_modules", [])

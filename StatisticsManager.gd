extends Node
# StatisticsManager.gd - Era-appropriate statistics dashboard
# Provides historical analysis, charts, and era-themed visualization

signal statistics_updated()
signal dashboard_opened()

# ==============================================================================
# ERA-SPECIFIC STYLING
# ==============================================================================

const ERA_STYLES = {
	0: {  # 1970s - Paper/Typewriter
		"name": "Paper Reports",
		"bg_color": Color(0.95, 0.92, 0.85),
		"text_color": Color(0.1, 0.1, 0.1),
		"chart_color": Color(0.2, 0.2, 0.6),
		"grid_color": Color(0.7, 0.7, 0.7),
		"font_style": "typewriter",
		"description": "Gedruckte Berichte auf Papier"
	},
	1: {  # 1980s - Green Phosphor Terminal
		"name": "Terminal Display",
		"bg_color": Color(0.0, 0.1, 0.0),
		"text_color": Color(0.2, 1.0, 0.2),
		"chart_color": Color(0.3, 1.0, 0.3),
		"grid_color": Color(0.1, 0.3, 0.1),
		"font_style": "monospace",
		"description": "CRT-Terminal mit gruenem Phosphor"
	},
	2: {  # 1990s - Windows 95 Style
		"name": "Desktop GUI",
		"bg_color": Color(0.75, 0.75, 0.85),
		"text_color": Color(0.0, 0.0, 0.0),
		"chart_color": Color(0.0, 0.0, 0.8),
		"grid_color": Color(0.5, 0.5, 0.5),
		"font_style": "sans_serif",
		"description": "Windows-95-Desktop-Anwendung"
	},
	3: {  # 2000s+ - Modern Web Dashboard
		"name": "Web Dashboard",
		"bg_color": Color(0.15, 0.15, 0.2),
		"text_color": Color(1.0, 1.0, 1.0),
		"chart_color": Color(0.2, 0.6, 1.0),
		"grid_color": Color(0.3, 0.3, 0.35),
		"font_style": "modern",
		"description": "Modernes Web-Dashboard"
	}
}

# ==============================================================================
# CHART TYPES
# ==============================================================================

enum ChartType {
	LINE,
	BAR,
	PIE,
	AREA
}

# ==============================================================================
# STATISTICS CATEGORIES
# ==============================================================================

const STAT_CATEGORIES = {
	"financial": {
		"title": "Finanzen",
		"metrics": ["cash", "revenue", "expenses", "profit"],
		"icon": "res://assets/icons/stat_money.png"
	},
	"production": {
		"title": "Produktion",
		"metrics": ["oil_produced", "oil_sold", "storage"],
		"icon": "res://assets/icons/stat_oil.png"
	},
	"market": {
		"title": "Markt",
		"metrics": ["oil_price", "market_share", "competitor_position"],
		"icon": "res://assets/icons/stat_market.png"
	},
	"operations": {
		"title": "Operationen",
		"metrics": ["wells_active", "wells_dry", "rigs_efficiency"],
		"icon": "res://assets/icons/stat_ops.png"
	}
}

# ==============================================================================
# STATE
# ==============================================================================

var game_manager = null
var current_view: String = "financial"
var selected_time_range: int = 12  # months
var comparison_mode: bool = false

# Cached statistics
var cached_stats: Dictionary = {}

func _ready():
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

# ==============================================================================
# MAIN STATISTICS CALCULATION
# ==============================================================================

func calculate_all_statistics() -> Dictionary:
	if game_manager == null:
		return {}

	var stats = {
		"financial": _calculate_financial_stats(),
		"production": _calculate_production_stats(),
		"market": _calculate_market_stats(),
		"operations": _calculate_operations_stats(),
		"summary": _calculate_summary()
	}

	cached_stats = stats
	statistics_updated.emit()
	return stats

func _calculate_financial_stats() -> Dictionary:
	var history_len = game_manager.history_cash.size()
	var months = min(selected_time_range, history_len)

	if months < 2:
		return {"error": "Nicht genug Daten"}

	var cash_history = game_manager.history_cash.slice(-months)
	var revenue_history = game_manager.history_revenue.slice(-months)
	var expense_history = game_manager.history_expenses.slice(-months)
	var profit_history = game_manager.history_profit.slice(-months)

	return {
		"current_cash": game_manager.cash,
		"cash_trend": _calculate_trend(cash_history),
		"total_revenue": _sum_array(revenue_history),
		"total_expenses": _sum_array(expense_history),
		"total_profit": _sum_array(profit_history),
		"avg_monthly_profit": _average_array(profit_history),
		"profit_margin": _calculate_margin(revenue_history, expense_history),
		"cash_history": cash_history,
		"revenue_history": revenue_history,
		"expense_history": expense_history,
		"profit_history": profit_history,
		"best_month": _find_max_index(profit_history),
		"worst_month": _find_min_index(profit_history)
	}

func _calculate_production_stats() -> Dictionary:
	var total_production = 0.0
	var total_storage = 0.0
	var total_capacity = 0.0
	var active_wells = 0
	var dry_wells = 0

	for region_name in game_manager.regions:
		var region = game_manager.regions[region_name]
		if region == null: continue

		total_storage += game_manager.oil_stored.get(region_name, 0.0)
		total_capacity += game_manager.tank_capacity.get(region_name, 0.0)

		for claim in region.get("claims", []):
			if claim.get("owned", false):
				if claim.get("drilled", false):
					if claim.get("has_oil", false):
						active_wells += 1
						total_production += claim.get("yield", 0.0)
					else:
						dry_wells += 1

	return {
		"total_production_daily": total_production,
		"total_storage": total_storage,
		"total_capacity": total_capacity,
		"storage_percent": (total_storage / total_capacity * 100.0) if total_capacity > 0 else 0.0,
		"active_wells": active_wells,
		"dry_wells": dry_wells,
		"success_rate": (float(active_wells) / float(active_wells + dry_wells) * 100.0) if (active_wells + dry_wells) > 0 else 0.0,
		"production_per_well": total_production / active_wells if active_wells > 0 else 0.0
	}

func _calculate_market_stats() -> Dictionary:
	var oil_price_history = game_manager.history_oil_price.slice(-selected_time_range)

	return {
		"current_price": game_manager.oil_price,
		"price_trend": _calculate_trend(oil_price_history),
		"price_high": _max_array(oil_price_history) if oil_price_history.size() > 0 else game_manager.oil_price,
		"price_low": _min_array(oil_price_history) if oil_price_history.size() > 0 else game_manager.oil_price,
		"price_volatility": _calculate_volatility(oil_price_history),
		"price_history": oil_price_history,
		"inflation_rate": game_manager.inflation_rate
	}

func _calculate_operations_stats() -> Dictionary:
	var total_regions = 0
	var unlocked_regions = 0
	var total_claims = 0
	var owned_claims = 0

	for region_name in game_manager.regions:
		var region = game_manager.regions[region_name]
		if region == null: continue

		total_regions += 1
		if region.get("unlocked", false):
			unlocked_regions += 1

		for claim in region.get("claims", []):
			total_claims += 1
			if claim.get("owned", false):
				owned_claims += 1

	return {
		"total_regions": total_regions,
		"unlocked_regions": unlocked_regions,
		"region_progress": (float(unlocked_regions) / float(total_regions) * 100.0) if total_regions > 0 else 0.0,
		"total_claims": total_claims,
		"owned_claims": owned_claims,
		"claim_acquisition_rate": (float(owned_claims) / float(total_claims) * 100.0) if total_claims > 0 else 0.0,
		"research_progress": game_manager.researched_techs.size(),
		"tech_unlocked": game_manager.unlocked_techs.size()
	}

func _calculate_summary() -> Dictionary:
	var financial = _calculate_financial_stats()
	var production = _calculate_production_stats()

	return {
		"company_value": _estimate_company_value(),
		"performance_rating": _calculate_performance_rating(),
		"health_status": _determine_health_status(),
		"recommendation": _generate_recommendation()
	}

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

func _sum_array(arr: Array) -> float:
	var total = 0.0
	for val in arr:
		total += val
	return total

func _average_array(arr: Array) -> float:
	if arr.size() == 0:
		return 0.0
	return _sum_array(arr) / arr.size()

func _max_array(arr: Array) -> float:
	if arr.size() == 0:
		return 0.0
	var max_val = arr[0]
	for val in arr:
		if val > max_val:
			max_val = val
	return max_val

func _min_array(arr: Array) -> float:
	if arr.size() == 0:
		return 0.0
	var min_val = arr[0]
	for val in arr:
		if val < min_val:
			min_val = val
	return min_val

func _calculate_trend(arr: Array) -> float:
	if arr.size() < 2:
		return 0.0

	var first_half = arr.slice(0, arr.size() / 2)
	var second_half = arr.slice(arr.size() / 2)

	var first_avg = _average_array(first_half)
	var second_avg = _average_array(second_half)

	if first_avg == 0:
		return 0.0

	return ((second_avg - first_avg) / abs(first_avg)) * 100.0

func _calculate_margin(revenue: Array, expenses: Array) -> float:
	var total_rev = _sum_array(revenue)
	var total_exp = _sum_array(expenses)

	if total_rev == 0:
		return 0.0

	return ((total_rev - total_exp) / total_rev) * 100.0

func _calculate_volatility(arr: Array) -> float:
	if arr.size() < 2:
		return 0.0

	var mean = _average_array(arr)
	var variance = 0.0

	for val in arr:
		variance += pow(val - mean, 2)

	variance /= arr.size()
	return sqrt(variance) / mean * 100.0 if mean != 0 else 0.0

func _find_max_index(arr: Array) -> int:
	if arr.size() == 0:
		return -1

	var max_idx = 0
	for i in range(arr.size()):
		if arr[i] > arr[max_idx]:
			max_idx = i
	return max_idx

func _find_min_index(arr: Array) -> int:
	if arr.size() == 0:
		return -1

	var min_idx = 0
	for i in range(arr.size()):
		if arr[i] < arr[min_idx]:
			min_idx = i
	return min_idx

func _estimate_company_value() -> float:
	if game_manager == null:
		return 0.0

	var value = game_manager.cash

	# Add asset values
	for region_name in game_manager.regions:
		if game_manager.regions[region_name].get("unlocked", false):
			value += game_manager.tank_capacity.get(region_name, 0) * 3.0  # Tank value

			for claim in game_manager.regions[region_name].get("claims", []):
				if claim.get("owned", false):
					value += 50000  # Base claim value
					if claim.get("has_oil", false):
						value += claim.get("reserves_remaining", 0) * game_manager.oil_price

	return value

func _calculate_performance_rating() -> String:
	if game_manager == null:
		return "N/A"

	var score = 0

	# Financial health
	if game_manager.cash > 10000000:
		score += 30
	elif game_manager.cash > 5000000:
		score += 20
	elif game_manager.cash > 1000000:
		score += 10

	# Production
	var production = _calculate_production_stats()
	if production.get("active_wells", 0) >= 10:
		score += 25
	elif production.get("active_wells", 0) >= 5:
		score += 15
	elif production.get("active_wells", 0) >= 1:
		score += 5

	# Expansion
	var ops = _calculate_operations_stats()
	if ops.get("unlocked_regions", 0) >= 5:
		score += 25
	elif ops.get("unlocked_regions", 0) >= 3:
		score += 15
	elif ops.get("unlocked_regions", 0) >= 1:
		score += 5

	# Technology
	if game_manager.unlocked_techs.size() >= 5:
		score += 20
	elif game_manager.unlocked_techs.size() >= 3:
		score += 10
	elif game_manager.unlocked_techs.size() >= 1:
		score += 5

	if score >= 80:
		return "Exzellent"
	elif score >= 60:
		return "Sehr gut"
	elif score >= 40:
		return "Gut"
	elif score >= 20:
		return "Befriedigend"
	else:
		return "Ausbaufaehig"

func _determine_health_status() -> String:
	if game_manager == null:
		return "Unbekannt"

	if game_manager.cash < 0:
		return "KRITISCH - Bankrott-Gefahr!"
	elif game_manager.cash < 500000:
		return "Warnung - Niedrige Liquiditaet"
	elif _calculate_trend(game_manager.history_profit.slice(-6)) < -20:
		return "Warnung - Sinkende Gewinne"
	else:
		return "Gesund"

func _generate_recommendation() -> String:
	if game_manager == null:
		return ""

	var financial = _calculate_financial_stats()
	var production = _calculate_production_stats()

	if financial.get("profit_margin", 0) < 10:
		return "Empfehlung: Kosten senken oder Preise erhoehen"
	elif production.get("storage_percent", 0) > 80:
		return "Empfehlung: Lager erweitern oder Verkauf steigern"
	elif production.get("active_wells", 0) < 3:
		return "Empfehlung: Weitere Bohrungen durchfuehren"
	else:
		return "Empfehlung: Expansion in neue Regionen"

# ==============================================================================
# ERA-STYLED OUTPUT
# ==============================================================================

func get_era_style() -> Dictionary:
	if game_manager == null:
		return ERA_STYLES[0]
	return ERA_STYLES.get(game_manager.current_era, ERA_STYLES[0])

func format_stat_for_era(value: float, stat_type: String) -> String:
	var style = get_era_style()
	var formatted = ""

	match stat_type:
		"currency":
			formatted = "$" + _format_number(value)
		"percentage":
			formatted = "%.1f%%" % value
		"barrels":
			formatted = _format_number(value) + " BBL"
		_:
			formatted = _format_number(value)

	# Era-specific formatting
	match style["font_style"]:
		"typewriter":
			return formatted.to_upper()
		"monospace":
			return ">" + formatted + "<"
		_:
			return formatted

func _format_number(value: float) -> String:
	if value >= 1000000000:
		return "%.1f Mrd" % (value / 1000000000.0)
	elif value >= 1000000:
		return "%.1f Mio" % (value / 1000000.0)
	elif value >= 1000:
		return "%.1f Tsd" % (value / 1000.0)
	else:
		return "%.0f" % value

# ==============================================================================
# GETTERS
# ==============================================================================

func get_category_stats(category: String) -> Dictionary:
	if cached_stats.is_empty():
		calculate_all_statistics()
	return cached_stats.get(category, {})

func get_all_stats() -> Dictionary:
	if cached_stats.is_empty():
		calculate_all_statistics()
	return cached_stats

func set_time_range(months: int):
	selected_time_range = clamp(months, 6, 60)
	calculate_all_statistics()

# ==============================================================================
# SAVE/LOAD
# ==============================================================================

func get_save_data() -> Dictionary:
	return {
		"current_view": current_view,
		"selected_time_range": selected_time_range,
		"comparison_mode": comparison_mode
	}

func load_save_data(data: Dictionary):
	current_view = data.get("current_view", "financial")
	selected_time_range = data.get("selected_time_range", 12)
	comparison_mode = data.get("comparison_mode", false)

extends Node
# ActivityFeed.gd - Tracks and displays AI competitor activities and game events
# Provides a dynamic "news ticker" feel to the game

signal new_activity(activity: Dictionary)

# --- ACTIVITY LOG ---
var activity_log: Array = []
var max_log_size: int = 50

# --- ACTIVITY TYPES ---
enum ACTIVITY_TYPE {
	AI_PURCHASE,
	AI_SABOTAGE,
	AI_LICENSE,
	AI_EXPANSION,
	PLAYER_ACHIEVEMENT,
	RANDOM_EVENT,
	HISTORICAL_EVENT,
	FINANCIAL_MILESTONE,
	REGION_UNLOCK
}

# --- REFERENCE ---
var game_manager = null

func _ready():
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

# --- LOG ACTIVITY ---
func log_activity(type: int, data: Dictionary):
	var activity = {
		"type": type,
		"data": data,
		"timestamp": _get_timestamp() if game_manager else "??",
		"year": game_manager.date["year"] if game_manager else 1970,
		"month": game_manager.date["month"] if game_manager else 1,
		"day": game_manager.date["day"] if game_manager else 1
	}
	
	activity_log.append(activity)
	
	# Trim old entries
	if activity_log.size() > max_log_size:
		activity_log.pop_front()
	
	# Emit signal for UI updates
	new_activity.emit(activity)
	
	print("[ACTIVITY] " + _format_activity(activity))

func _get_timestamp() -> String:
	if game_manager == null:
		return "??"
	return "%02d/%02d/%d" % [game_manager.date["day"], game_manager.date["month"], game_manager.date["year"]]

# --- ACTIVITY FORMATTING ---
func _format_activity(activity: Dictionary) -> String:
	var type = activity["type"]
	var data = activity["data"]
	
	match type:
		ACTIVITY_TYPE.AI_PURCHASE:
			return "%s kaufte Land in %s ($%s)" % [data.get("company", "???"), data.get("region", "???"), _fmt(data.get("price", 0))]
		ACTIVITY_TYPE.AI_SABOTAGE:
			return "%s führte Sabotage in %s durch" % [data.get("company", "???"), data.get("region", "???")]
		ACTIVITY_TYPE.AI_LICENSE:
			return "%s erwarb Lizenz für %s" % [data.get("company", "???"), data.get("region", "???")]
		ACTIVITY_TYPE.AI_EXPANSION:
			return "%s expandiert nach %s" % [data.get("company", "???"), data.get("region", "???")]
		ACTIVITY_TYPE.PLAYER_ACHIEVEMENT:
			return "ERFOLG: %s" % data.get("title", "???")
		ACTIVITY_TYPE.RANDOM_EVENT:
			return "EREIGNIS: %s" % data.get("title", "???")
		ACTIVITY_TYPE.HISTORICAL_EVENT:
			return "HISTORISCH: %s" % data.get("title", "???")
		ACTIVITY_TYPE.FINANCIAL_MILESTONE:
			return "MEILENSTEIN: %s" % data.get("title", "???")
		ACTIVITY_TYPE.REGION_UNLOCK:
			return "FREISCHALTUNG: %s ist nun verfügbar" % data.get("region", "???")
		_:
			return "Unbekannte Aktivität"

func _fmt(value) -> String:
	var s = str(int(value))
	var res = ""
	var counter = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		counter += 1
		if counter % 3 == 0 and i > 0:
			res = "." + res
	return res

# --- GET RECENT ACTIVITIES ---
func get_recent_activities(count: int = 10) -> Array:
	var start_idx = max(0, activity_log.size() - count)
	return activity_log.slice(start_idx)

func get_activities_by_type(type: int) -> Array:
	var result = []
	for activity in activity_log:
		if activity["type"] == type:
			result.append(activity)
	return result

func get_activities_by_year(year: int) -> Array:
	var result = []
	for activity in activity_log:
		if activity["year"] == year:
			result.append(activity)
	return result

# --- CLEAR LOG ---
func clear_log():
	activity_log.clear()

# --- SAVE/LOAD ---
func get_save_data() -> Dictionary:
	return {
		"activity_log": activity_log
	}

func load_save_data(data: Dictionary):
	if data.has("activity_log"):
		activity_log = data["activity_log"]

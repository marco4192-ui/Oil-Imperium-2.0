extends Node
# StoryEventManager.gd - Dynamic story events
# Handles corporate espionage, whistleblowers, hostile takeovers, and other narrative events

signal story_event_started(event: Dictionary)
signal story_event_resolved(event_id: String, outcome: String)
signal hostile_takeover_attempt(attacker: String, defender: String)
signal whistleblower_exposed(company: String, secrets: Array)

# --- STORY EVENT TYPES ---
enum EventType {
	ESPIONAGE,
	WHISTLEBLOWER,
	HOSTILE_TAKEOVER,
	SABOTAGE_DISCOVERY,
	INSIDER_TRADING,
	FRAUD_INVESTIGATION,
	CORPORATE_SCANDAL,
	COMPETITOR_ALLIANCE,
	MARKET_MANIPULATION
}

# --- ESPIONAGE EVENTS ---
const ESPIONAGE_EVENTS = [
	{
		"id": "spy_hired",
		"title": "Corporate Spy Approaches You",
		"description": "A disgruntled employee from a competitor offers to sell you trade secrets.",
		"choices": [
			{"text": "Buy the secrets ($500k)", "cost": 500000, "outcome_success": {"intel": true}, "outcome_fail": {"scandal": true}},
			{"text": "Report to authorities", "outcome_success": {"reputation": 10}, "outcome_fail": {"nothing": true}},
			{"text": "Decline politely", "outcome_success": {"nothing": true}}
		],
		"risk": 0.3
	},
	{
		"id": "your_spy_caught",
		"title": "Your Spy Has Been Caught!",
		"description": "An operative you hired to spy on competitors has been arrested. They're talking to the press!",
		"choices": [
			{"text": "Deny everything", "outcome_success": {"nothing": true}, "outcome_fail": {"reputation": -20, "fine": 1000000}},
			{"text": "Bribe the spy ($2M)", "cost": 2000000, "outcome_success": {"silence": true}},
			{"text": "Lawyer up ($500k)", "cost": 500000, "outcome_success": {"reduced_penalty": true}, "outcome_fail": {"reputation": -10}}
		],
		"risk": 0.4
	},
	{
		"id": "competitor_espionage",
		"title": "Caught a Competitor's Spy!",
		"description": "You've discovered a spy from %s trying to steal your geological survey data.",
		"choices": [
			{"text": "Expose publicly", "outcome_success": {"competitor_scandal": true, "reputation": 5}},
			{"text": "Feed false information", "outcome_success": {"misinformation": true}},
			{"text": "Blackmail for cash", "outcome_success": {"cash": 1000000}, "outcome_fail": {"reputation": -15}},
			{"text": "Turn them double agent", "outcome_success": {"double_agent": true}, "outcome_fail": {"exposed": true}}
		],
		"risk": 0.2,
		"requires_competitor": true
	}
]

# --- WHISTLEBLOWER EVENTS ---
const WHISTLEBLOWER_EVENTS = [
	{
		"id": "internal_whistleblower",
		"title": "Whistleblower Within Your Ranks",
		"description": "An employee threatens to expose unsafe practices at your rigs to the media.",
		"choices": [
			{"text": "Fix the issues ($1M)", "cost": 1000000, "outcome_success": {"safety_improved": true, "reputation": 5}},
			{"text": "Pay them off ($500k)", "cost": 500000, "outcome_success": {"silence": true}, "outcome_fail": {"exposed": true, "reputation": -30}},
			{"text": "Fire them", "outcome_success": {"silence": true}, "outcome_fail": {"lawsuit": true, "reputation": -20}},
			{"text": "Let them talk", "outcome_success": {"reputation": -15, "investigation": true}}
		],
		"risk": 0.3
	},
	{
		"id": "competitor_whistleblower",
		"title": "Insider Offers Competitor Secrets",
		"description": "A whistleblower from %s offers documents proving their safety violations.",
		"choices": [
			{"text": "Report to regulators", "outcome_success": {"competitor_fined": true}},
			{"text": "Leak to media", "outcome_success": {"competitor_scandal": true}},
			{"text": "Blackmail the competitor", "outcome_success": {"cash": 2000000}, "outcome_fail": {"scandal": true}},
			{"text": "Ignore", "outcome_success": {"nothing": true}}
		],
		"risk": 0.2,
		"requires_competitor": true
	},
	{
		"id": "financial_fraud_exposed",
		"title": "Accounting Irregularities Discovered",
		"description": "Your CFO discovers potential fraud in last quarter's reports. Going public could tank your stock.",
		"choices": [
			{"text": "Come clean", "outcome_success": {"reputation": -10, "fine": 500000}},
			{"text": "Quietly fix it", "outcome_success": {"nothing": true}, "outcome_fail": {"investigation": true, "reputation": -25}},
			{"text": "Blame a scapegoat", "outcome_success": {"nothing": true}, "outcome_fail": {"lawsuit": true}}
		],
		"risk": 0.4
	}
]

# --- HOSTILE TAKEOVER EVENTS ---
const TAKEOVER_EVENTS = [
	{
		"id": "takeover_attempt",
		"title": "Hostile Takeover Bid!",
		"description": "%s has launched a hostile takeover attempt! They're offering shareholders a 40%% premium.",
		"choices": [
			{"text": "Poison pill defense ($5M)", "cost": 5000000, "outcome_success": {"takeover_blocked": true}},
			{"text": "Find white knight", "outcome_success": {"white_knight": true}, "outcome_fail": {"takeover_progress": true}},
			{"text": "Negotiate merger", "outcome_success": {"merger": true}, "outcome_fail": {"takeover_progress": true}},
			{"text": "Appeal to shareholders", "outcome_success": {"takeover_blocked": true}, "outcome_fail": {"takeover_progress": true}}
		],
		"risk": 0.4,
		"requires_competitor": true
	},
	{
		"id": "your_takeover_opportunity",
		"title": "Acquisition Opportunity",
		"description": "%s is financially weakened. You could attempt a hostile takeover.",
		"choices": [
			{"text": "Launch takeover bid ($10M)", "cost": 10000000, "outcome_success": {"acquisition": true}, "outcome_fail": {"reputation": -10}},
			{"text": "Buy just key assets ($5M)", "cost": 5000000, "outcome_success": {"assets_acquired": true}},
			{"text": "Wait for better price", "outcome_success": {"nothing": true}}
		],
		"risk": 0.3,
		"requires_competitor": true
	}
]

# --- MARKET MANIPULATION EVENTS ---
const MARKET_EVENTS = [
	{
		"id": "insider_trading_tip",
		"title": "Insider Trading Tip",
		"description": "A contact gives you advance word about a major OPEC decision next week.",
		"choices": [
			{"text": "Act on the information", "outcome_success": {"profit": 2000000}, "outcome_fail": {"investigation": true, "fine": 5000000}},
			{"text": "Report the tip", "outcome_success": {"reputation": 10}},
			{"text": "Ignore it", "outcome_success": {"nothing": true}}
		],
		"risk": 0.35
	},
	{
		"id": "price_manipulation_scheme",
		"title": "Market Manipulation Offer",
		"description": "A consortium of traders offers to coordinate buying to manipulate oil prices.",
		"choices": [
			{"text": "Join the scheme", "outcome_success": {"profit": 3000000}, "outcome_fail": {"investigation": true, "fine": 10000000}},
			{"text": "Report to SEC", "outcome_success": {"reputation": 15}},
			{"text": "Decline quietly", "outcome_success": {"nothing": true}}
		],
		"risk": 0.5
	}
]

# --- STATE ---
var active_events: Array = []
var resolved_events: Array = []
var event_cooldown: int = 0
var pending_event: Dictionary = {}

var game_manager = null

func _ready():
	await get_tree().create_timer(0.5).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")

# --- CHECK FOR NEW EVENTS ---
func check_for_events() -> Dictionary:
	if game_manager == null:
		return {}
	
	# Cooldown check
	if event_cooldown > 0:
		event_cooldown -= 1
		return {}
	
	# Random chance for event (5% per month)
	if randf() > 0.05:
		return {}
	
	# Choose event category
	var all_events = []
	all_events.append_array(ESPIONAGE_EVENTS)
	all_events.append_array(WHISTLEBLOWER_EVENTS)
	all_events.append_array(TAKEOVER_EVENTS)
	all_events.append_array(MARKET_EVENTS)
	
	# Filter events that need competitors
	var valid_events = []
	for event in all_events:
		if event.get("requires_competitor", false):
			if _has_active_competitors():
				valid_events.append(event)
		else:
			valid_events.append(event)
	
	if valid_events.is_empty():
		return {}
	
	# Pick random event
	var chosen = valid_events.pick_random().duplicate(true)
	
	# Fill in competitor name if needed
	if chosen.get("requires_competitor", false):
		var competitor = _get_random_competitor()
		chosen["description"] = chosen["description"] % competitor
		chosen["competitor"] = competitor
	
	# Set up event
	chosen["start_date"] = game_manager.date.duplicate()
	pending_event = chosen
	
	story_event_started.emit(chosen)
	
	# Set cooldown
	event_cooldown = 3  # No events for 3 months after one starts
	
	return chosen

func _has_active_competitors() -> bool:
	if game_manager == null or game_manager.ai_controller == null:
		return false
	return game_manager.ai_controller.competitors.size() > 0

func _get_random_competitor() -> String:
	if game_manager == null or game_manager.ai_controller == null:
		return "a competitor"
	
	var competitors = game_manager.ai_controller.competitors
	if competitors.is_empty():
		return "a competitor"
	
	return competitors.pick_random().get("name", "a competitor")

# --- PROCESS EVENT CHOICE ---
func process_choice(event_id: String, choice_index: int) -> Dictionary:
	var event = pending_event
	
	if event.is_empty():
		return {"success": false, "message": "No pending event"}
	
	var choices = event.get("choices", [])
	if choice_index < 0 or choice_index >= choices.size():
		return {"success": false, "message": "Invalid choice"}
	
	var choice = choices[choice_index]
	
	# Check cost
	if choice.has("cost"):
		var cost = int(choice["cost"] * game_manager.inflation_rate)
		if game_manager.cash < cost:
			return {"success": false, "message": "Not enough money. Need $%s" % game_manager.format_cash(cost)}
		game_manager.cash -= cost
		game_manager.book_transaction("Global", -cost, "Legal Affairs")
	
	# Determine outcome
	var success = randf() > event.get("risk", 0.3)
	
	var outcome_key = "outcome_success" if success else "outcome_fail"
	var outcomes = choice.get(outcome_key, {})
	
	# Apply outcomes
	_apply_outcomes(outcomes)
	
	# Store resolved event
	event["resolved"] = true
	event["outcome"] = "success" if success else "failure"
	event["choice"] = choice["text"]
	resolved_events.append(event)
	
	story_event_resolved.emit(event_id, event["outcome"])
	
	# Clear pending
	pending_event = {}
	
	return {
		"success": true,
		"outcome": "success" if success else "failure",
		"effects": outcomes
	}

func _apply_outcomes(outcomes: Dictionary):
	if game_manager == null:
		return
	
	if outcomes.has("cash"):
		game_manager.cash += outcomes["cash"]
	
	if outcomes.has("fine"):
		var fine = int(outcomes["fine"] * game_manager.inflation_rate)
		game_manager.cash -= fine
		game_manager.book_transaction("Global", -fine, "Legal Penalties")
	
	if outcomes.has("profit"):
		game_manager.cash += outcomes["profit"]
		game_manager.book_transaction("Global", outcomes["profit"], "Investment Gains")
	
	if outcomes.has("competitor_fined"):
		# Would affect AI competitor
		pass
	
	if outcomes.has("investigation"):
		if has_node("/root/FeedbackOverlay"):
			get_node("/root/FeedbackOverlay").show_msg(
				"GOVERNMENT INVESTIGATION LAUNCHED!\nYour company is under investigation.",
				Color.RED
			)

# --- GET PENDING EVENT ---
func get_pending_event() -> Dictionary:
	return pending_event

# --- TRIGGER SPECIFIC EVENT ---
func trigger_event(event_type: String) -> Dictionary:
	var event_pool = []
	
	match event_type:
		"espionage":
			event_pool = ESPIONAGE_EVENTS
		"whistleblower":
			event_pool = WHISTLEBLOWER_EVENTS
		"takeover":
			event_pool = TAKEOVER_EVENTS
		"market":
			event_pool = MARKET_EVENTS
		_:
			event_pool = ESPIONAGE_EVENTS + WHISTLEBLOWER_EVENTS + TAKEOVER_EVENTS + MARKET_EVENTS
	
	if event_pool.is_empty():
		return {}
	
	var chosen = event_pool.pick_random().duplicate(true)
	
	if chosen.get("requires_competitor", false):
		var competitor = _get_random_competitor()
		chosen["description"] = chosen["description"] % competitor
		chosen["competitor"] = competitor
	
	chosen["start_date"] = game_manager.date.duplicate()
	pending_event = chosen
	
	story_event_started.emit(chosen)
	
	return chosen

# --- SAVE/LOAD ---
func get_save_data() -> Dictionary:
	return {
		"active": active_events,
		"resolved": resolved_events,
		"cooldown": event_cooldown,
		"pending": pending_event
	}

func load_save_data(data: Dictionary):
	active_events = data.get("active", [])
	resolved_events = data.get("resolved", [])
	event_cooldown = data.get("cooldown", 0)
	pending_event = data.get("pending", {})

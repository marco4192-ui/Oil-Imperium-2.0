extends Node
# LobbyingManager.gd - Political lobbying and bribery system
# Influence regulations, bribe politicians, risk Watergate-style scandals

signal lobbying_success(effect: String)
signal lobbying_scandal(scandal_type: String, penalty: Dictionary)

# --- POLITICAL FIGURES ---
const POLITICIANS = [
        {
                "id": "senator_texas",
                "name": "Sen. 'Big Oil' Bob Thornton",
                "state": "Texas",
                "influence": 0.8,
                "base_cost": 500000,
                "specialties": ["tax_breaks", "deregulation"],
                "risk": 0.15,  # 15% base scandal risk
                "description": "Longtime friend of the oil industry. Can push through tax legislation."
        },
        {
                "id": "governor_alaska",
                "name": "Gov. Sarah Icefield",
                "state": "Alaska",
                "influence": 0.6,
                "base_cost": 300000,
                "specialties": ["drilling_rights", "environmental_exceptions"],
                "risk": 0.25,
                "description": "Pro-drilling governor. Can expedite permits for Arctic operations."
        },
        {
                "id": "congressman_budget",
                "name": "Rep. William Spendwell",
                "state": "Washington D.C.",
                "influence": 0.5,
                "base_cost": 200000,
                "specialties": ["subsidies", "government_contracts"],
                "risk": 0.30,
                "description": "Sits on budget committee. Can secure federal subsidies."
        },
        {
                "id": "senator_environment",
                "name": "Sen. Rachel Greener",
                "state": "California",
                "influence": 0.4,
                "base_cost": 750000,
                "specialties": ["environmental_exemptions", "regulation_delays"],
                "risk": 0.45,  # High risk - environmental senator is harder to bribe
                "description": "Usually votes against oil interests. Expensive to influence, risky."
        },
        {
                "id": "lobbyist_energy",
                "name": "Energy Lobbyist Jack Powers",
                "state": "Washington D.C.",
                "influence": 0.7,
                "base_cost": 400000,
                "specialties": ["industry_favorable_laws", "competitor_investigations"],
                "risk": 0.20,
                "description": "Well-connected lobbyist. Can arrange meetings and push legislation."
        }
]

# --- LOBBYING ACTIONS ---
const LOBBYING_ACTIONS = [
        {
                "id": "tax_break",
                "name": "Tax Reduction Bill",
                "description": "Push for lower corporate taxes on oil profits.",
                "effect": {"tax_reduction": 0.1},  # 10% tax reduction
                "cost_multiplier": 1.0,
                "required_influence": 0.5,
                "duration_months": 12
        },
        {
                "id": "deregulation",
                "name": "Environmental Deregulation",
                "description": "Reduce safety and environmental inspection frequency.",
                "effect": {"safety_cost_reduction": 0.2},
                "cost_multiplier": 1.5,
                "required_influence": 0.6,
                "duration_months": 6
        },
        {
                "id": "drilling_permit",
                "name": "Expedited Drilling Permits",
                "description": "Fast-track approval for new drilling operations.",
                "effect": {"permit_time_reduction": 0.5},
                "cost_multiplier": 0.8,
                "required_influence": 0.4,
                "duration_months": 3
        },
        {
                "id": "subsidy",
                "name": "Federal Oil Subsidy",
                "description": "Secure government subsidy for domestic production.",
                "effect": {"production_subsidy": 0.5},  # $0.50 per barrel
                "cost_multiplier": 2.0,
                "required_influence": 0.7,
                "duration_months": 24
        },
        {
                "id": "competitor_audit",
                "name": "Competitor Investigation",
                "description": "Trigger federal investigation of a competitor.",
                "effect": {"competitor_penalty": true},
                "cost_multiplier": 2.5,
                "required_influence": 0.65,
                "duration_months": 1
        },
        {
                "id": "embargo_relaxation",
                "name": "Trade Agreement",
                "description": "Relax trade restrictions with oil-producing nations.",
                "effect": {"import_cost_reduction": 0.15},
                "cost_multiplier": 3.0,
                "required_influence": 0.8,
                "duration_months": 18
        }
]

# --- SCANDAL TYPES ---
const SCANDAL_TYPES = [
        {
                "id": "bribe_exposed",
                "name": "BRIBERY SCANDAL EXPOSED!",
                "headline": "CASH FOR FAVORS: %s CAUGHT IN LOBBYING SCANDAL",
                "effects": {"reputation": -30, "fine": 5000000, "investigation_months": 6}
        },
        {
                "id": "whistleblower",
                "name": "WHISTLEBLOWER REVEALS CORRUPTION",
                "headline": "INSIDER BLOWS LID OFF %s SECRET DEALS",
                "effects": {"reputation": -25, "fine": 3000000, "investigation_months": 4}
        },
        {
                "id": "watergate_style",
                "name": "WATERGATE-STYLE BREAK-IN",
                "headline": "BREAK-IN AT COMPETITOR OFFICES LINKED TO %s",
                "effects": {"reputation": -40, "fine": 10000000, "investigation_months": 12, "criminal_charges": true}
        },
        {
                "id": "leaked_documents",
                "name": "DOCUMENTS LEAKED TO PRESS",
                "headline": "SECRET MEMOS REVEAL %s POLITICAL MANEUVERING",
                "effects": {"reputation": -20, "fine": 1000000, "investigation_months": 3}
        }
]

# --- STATE ---
var active_lobbying: Array = []  # Currently active lobbying efforts
var lobbying_history: Array = []
var scandal_cooldown: int = 0  # Months until another scandal can occur
var investigation_active: bool = false
var investigation_months_left: int = 0

var game_manager = null

func _ready():
        await get_tree().create_timer(0.5).timeout
        if has_node("/root/GameManager"):
                game_manager = get_node("/root/GameManager")

# --- GET AVAILABLE POLITICIANS ---
func get_available_politicians() -> Array:
        var available = []
        for politician in POLITICIANS:
                var adjusted_cost = int(politician["base_cost"] * game_manager.inflation_rate if game_manager else politician["base_cost"])
                available.append({
                        "id": politician["id"],
                        "name": politician["name"],
                        "state": politician["state"],
                        "influence": politician["influence"],
                        "cost": adjusted_cost,
                        "risk": politician["risk"],
                        "specialties": politician["specialties"],
                        "description": politician["description"]
                })
        return available

# --- GET AVAILABLE ACTIONS ---
func get_available_actions() -> Array:
        var actions = []
        for action in LOBBYING_ACTIONS:
                actions.append({
                        "id": action["id"],
                        "name": action["name"],
                        "description": action["description"],
                        "effect": action["effect"],
                        "required_influence": action["required_influence"],
                        "duration_months": action["duration_months"]
                })
        return actions

# --- ATTEMPT LOBBYING ---
func attempt_lobbying(politician_id: String, action_id: String) -> Dictionary:
        if game_manager == null:
                return {"success": false, "message": "System error"}
        
        # Find politician and action
        var politician = POLITICIANS.find_custom(func(p): return p["id"] == politician_id)
        if politician == -1:
                return {"success": false, "message": "Politician not found"}
        politician = POLITICIANS[politician]
        
        var action = LOBBYING_ACTIONS.find_custom(func(a): return a["id"] == action_id)
        if action == -1:
                return {"success": false, "message": "Action not found"}
        action = LOBBYING_ACTIONS[action]
        
        # Calculate cost
        var base_cost = politician["base_cost"] * action["cost_multiplier"]
        var cost = int(base_cost * game_manager.inflation_rate)
        
        # Check if player can afford
        if game_manager.cash < cost:
                return {"success": false, "message": "Not enough funds. Need $%s" % game_manager.format_cash(cost)}
        
        # Check if politician has enough influence
        if politician["influence"] < action["required_influence"]:
                return {
                        "success": false, 
                        "message": "%s lacks sufficient influence for this action. Need %.0f%% influence, have %.0f%%" % [
                                politician["name"], 
                                action["required_influence"] * 100,
                                politician["influence"] * 100
                        ]
                }
        
        # Deduct cost
        game_manager.cash -= cost
        game_manager.book_transaction("Global", -cost, "Lobbying")
        
        # Calculate success chance
        var success_chance = politician["influence"] + 0.2  # Base success
        var scandal_chance = politician["risk"]
        
        # Specialty bonus
        if action["id"] in politician["specialties"]:
                success_chance += 0.15
                scandal_chance -= 0.05
        
        # Random roll
        var roll = randf()
        
        if roll < scandal_chance:
                # Scandal!
                _trigger_scandal(politician)
                return {"success": false, "message": "SCANDAL! Your lobbying attempt was exposed!", "scandal": true}
        
        if roll < scandal_chance + (1 - success_chance):
                # Failure (no scandal, but no success either)
                return {"success": false, "message": "Lobbying attempt failed. Money wasted."}
        
        # Success!
        var lobbying_entry = {
                "politician": politician["name"],
                "action": action["name"],
                "effect": action["effect"],
                "months_remaining": action["duration_months"],
                "start_date": game_manager.date.duplicate()
        }
        
        active_lobbying.append(lobbying_entry)
        _apply_lobbying_effect(action["effect"], true)
        
        lobbying_success.emit(action["name"])
        
        return {
                "success": true, 
                "message": "SUCCESS! %s has been secured for %d months!" % [action["name"], action["duration_months"]],
                "effect": action["effect"]
        }

func _trigger_scandal(_politician: Dictionary):
        var scandal = SCANDAL_TYPES.pick_random()
        
        # Apply scandal effects
        var effects = scandal["effects"]
        
        var headline = scandal["headline"] % game_manager.company_name
        
        # Fine
        if effects.has("fine"):
                var fine = int(effects["fine"] * game_manager.inflation_rate)
                game_manager.cash -= fine
                game_manager.book_transaction("Global", -fine, "Legal Penalties")
        
        # Investigation
        if effects.has("investigation_months"):
                investigation_active = true
                investigation_months_left = effects["investigation_months"]
        
        # Reputation would be handled by reputation system
        # For now, just store the scandal
        
        lobbying_history.append({
                "type": "scandal",
                "headline": headline,
                "date": game_manager.date.duplicate(),
                "effects": effects
        })
        
        lobbying_scandal.emit(scandal["id"], effects)
        
        # Show message
        if has_node("/root/FeedbackOverlay"):
                get_node("/root/FeedbackOverlay").show_msg(
                        "═══ SCANDAL ═══\n\n%s\n\nPenalties applied!" % headline,
                        Color.RED
                )

func _apply_lobbying_effect(effect: Dictionary, apply: bool):
        if game_manager == null:
                return
        
        var multiplier = 1.0 if apply else -1.0
        
        if effect.has("tax_reduction"):
                # Would need a tax system
                pass
        
        if effect.has("safety_cost_reduction"):
                game_manager.global_cost_multiplier *= (1.0 - effect["safety_cost_reduction"] * multiplier)
        
        if effect.has("production_subsidy"):
                # Would affect per-barrel revenue
                pass

# --- PROCESS MONTHLY ---
func process_monthly():
        # Reduce cooldowns
        if scandal_cooldown > 0:
                scandal_cooldown -= 1
        
        if investigation_months_left > 0:
                investigation_months_left -= 1
                if investigation_months_left <= 0:
                        investigation_active = false
                        if has_node("/root/FeedbackOverlay"):
                                get_node("/root/FeedbackOverlay").show_msg("Investigation concluded. You're in the clear... for now.", Color.YELLOW)
        
        # Process active lobbying effects
        var expired = []
        for i in range(active_lobbying.size()):
                active_lobbying[i]["months_remaining"] -= 1
                if active_lobbying[i]["months_remaining"] <= 0:
                        expired.append(i)
        
        # Remove expired lobbying (reverse order to preserve indices)
        for i in expired:
                var entry = active_lobbying[i]
                _apply_lobbying_effect(entry["effect"], false)  # Remove effect
                active_lobbying.remove_at(i)

# --- GET ACTIVE LOBBYING ---
func get_active_lobbying() -> Array:
        return active_lobbying

# --- SAVE/LOAD ---
func get_save_data() -> Dictionary:
        return {
                "active": active_lobbying,
                "history": lobbying_history,
                "scandal_cooldown": scandal_cooldown,
                "investigation_active": investigation_active,
                "investigation_months_left": investigation_months_left
        }

func load_save_data(data: Dictionary):
        active_lobbying = data.get("active", [])
        lobbying_history = data.get("history", [])
        scandal_cooldown = data.get("scandal_cooldown", 0)
        investigation_active = data.get("investigation_active", false)
        investigation_months_left = data.get("investigation_months_left", 0)

extends Node

const GameData = preload("res://GameData.gd")

var game_manager = null 

# --- KI KONFIGURATION ---
var competitors = [
        {
                "name": "KI_1", 
                "color": Color.RED, 
                "cash": 25000000.0,
                "aggressiveness": 0.9,
                "sabotage_tendency": 0.4, 
                "risk_tolerance": 0.7,  # NEW: How risky are their investments
                "expansion_priority": 0.8,  # NEW: How much they prioritize expansion
                "focus_regions": ["Texas", "Mexiko", "Venezuela"],
                "inventory": [],
                "owned_regions": {},  # NEW: Track claims by region
                "monthly_budget": 0  # NEW: Track monthly spending budget
        },
        {
                "name": "KI_2", 
                "color": Color.YELLOW, 
                "cash": 30000000.0,
                "aggressiveness": 0.7,
                "sabotage_tendency": 0.2, 
                "risk_tolerance": 0.4,  # More conservative
                "expansion_priority": 0.6,
                "focus_regions": ["Nordsee", "Nigeria", "Indonesien"],
                "inventory": [],
                "owned_regions": {},
                "monthly_budget": 0
        },
        {
                "name": "KI_3", 
                "color": Color.GREEN, 
                "cash": 20000000.0, 
                "aggressiveness": 0.8,
                "sabotage_tendency": 0.3,
                "risk_tolerance": 0.5,
                "expansion_priority": 0.7,
                "focus_regions": ["Saudi-Arabien", "Libyen", "Alaska"],
                "inventory": [],
                "owned_regions": {},
                "monthly_budget": 0
        }
]

# --- STRATEGIC CONSTANTS ---
const MIN_RESERVE_CASH = 2000000  # AI always keeps this amount as reserve
const MAX_CLAIMS_PER_REGION = 4   # AI won't over-invest in one region
const OFFSHORE_PREFERENCE_BONUS = 0.2  # AI slightly prefers offshore (higher yield potential)

func _ready():
        await get_tree().create_timer(0.5).timeout
        
        if is_instance_valid(game_manager):
                var company_names = []
                for c in GameData.COMPANIES:
                        company_names.append(c["name"])
                
                company_names.shuffle()
                
                for i in range(competitors.size()):
                        if i < company_names.size():
                                competitors[i]["name"] = company_names[i]
                                print("KI Spieler initialisiert: " + competitors[i]["name"] + " (Cash: $" + str(competitors[i]["cash"]) + ")")

func process_ai_turn():
        if game_manager == null: return
        
        print("\n--- KI ZUG BEGINNT ---")
        
        for bot in competitors:
                # 0. Calculate monthly budget
                _calculate_budget(bot)
                
                # 1. Einkommen simulieren
                _process_bot_income(bot)
                
                # 2. Strategic expansion (improved)
                if randf() < bot["aggressiveness"] * bot["expansion_priority"]:
                        _smart_expansion(bot)
                
                # 3. Try additional expansion if budget allows
                if bot["monthly_budget"] > 500000:
                        _smart_expansion(bot)
                        
                # 4. Sabotage against player (strategic)
                if randf() < bot["sabotage_tendency"]:
                        _strategic_sabotage(bot)

func _calculate_budget(bot):
        # AI sets aside reserve and calculates spending budget
        var available = bot["cash"] - MIN_RESERVE_CASH
        bot["monthly_budget"] = max(0, available * bot["aggressiveness"] * 0.3)

func _process_bot_income(bot):
        var daily_income = 0
        
        # Income per claim based on region's offshore ratio (offshore = more potential)
        for claim in bot["inventory"]:
                if claim == null: continue
                var base_income = randi_range(2000, 6000)
                if claim.get("is_offshore", false):
                        base_income = int(base_income * 1.5)  # Offshore pays better
                daily_income += base_income
        
        # Passive investor income (scales with portfolio size)
        var portfolio_bonus = bot["inventory"].size() * 500
        daily_income += 5000 + portfolio_bonus
        
        bot["cash"] += daily_income * 30

func _smart_expansion(bot):
        if bot["monthly_budget"] < 100000:
                return  # Not enough budget
        
        # Step 1: Find best region to expand
        var best_region = _evaluate_best_region(bot)
        if best_region == "":
                return
        
        # Step 2: Find best claim in that region
        var best_claim = _find_best_claim(bot, best_region)
        if best_claim == null:
                return
        
        # Step 3: Make the purchase decision
        var price = best_claim.get("price", 999999999)
        
        # Can afford after reserve?
        if bot["cash"] - price < MIN_RESERVE_CASH:
                return
        
        # Is it within budget?
        if price > bot["monthly_budget"] * 1.5:  # Allow slight overbudget
                return
        
        # Execute purchase
        bot["cash"] -= price
        best_claim["ai_owner"] = bot["name"]
        bot["inventory"].append(best_claim)
        
        # Track region ownership
        if not bot["owned_regions"].has(best_region):
                bot["owned_regions"][best_region] = 0
        bot["owned_regions"][best_region] += 1
        bot["monthly_budget"] -= price
        
        print(">>> " + bot["name"] + " KAUFT LAND in " + best_region + " für $" + str(price))

func _evaluate_best_region(bot) -> String:
        var scored_regions = []
        
        for region_name in game_manager.regions:
                var region = game_manager.regions[region_name]
                if region == null: continue
                if not region.get("visible", false): continue
                
                var score = 0.0
                
                # Base score for focus regions
                if region_name in bot["focus_regions"]:
                        score += 50.0
                
                # Offshore bonus
                var offshore_ratio = region.get("offshore_ratio", 0.0)
                score += offshore_ratio * 30.0 * bot["risk_tolerance"]
                
                # Availability score - how many free claims?
                var free_claims = 0
                var claims = region.get("claims", [])
                for claim in claims:
                        if claim == null or typeof(claim) != TYPE_DICTIONARY: continue
                        if claim.get("is_empty", false): continue
                        if not claim.get("owned", false) and not claim.has("ai_owner"):
                                free_claims += 1
                
                score += free_claims * 5.0
                
                # Don't over-invest in one region
                var owned_in_region = bot["owned_regions"].get(region_name, 0)
                if owned_in_region >= MAX_CLAIMS_PER_REGION:
                        score -= 100.0  # Heavy penalty
                
                # License cost consideration
                var license_fee = region.get("license_fee", 0)
                if not region.get("unlocked", false):
                        score -= license_fee / 100000.0  # Penalty for locked regions
                
                scored_regions.append({"name": region_name, "score": score})
        
        # Sort by score and pick best
        scored_regions.sort_custom(func(a, b): return a["score"] > b["score"])
        
        if scored_regions.is_empty():
                return ""
        
        # Add some randomness - pick from top 3
        var pick_range = min(3, scored_regions.size())
        return scored_regions[randi() % pick_range]["name"]

func _find_best_claim(bot, region_name: String) -> Dictionary:
        var region = game_manager.regions.get(region_name)
        if region == null: return {}
        
        var claims = region.get("claims", [])
        var scored_claims = []
        
        for claim in claims:
                if claim == null or typeof(claim) != TYPE_DICTIONARY: continue
                if claim.get("is_empty", false): continue
                if claim.get("owned", false) or claim.has("ai_owner"): continue
                
                var score = 0.0
                var price = claim.get("price", 999999999)
                
                # Price score (cheaper is better, but not always)
                if price < 200000:
                        score += 30.0
                elif price < 500000:
                        score += 20.0
                elif price < 1000000:
                        score += 10.0
                
                # Offshore bonus (higher risk, higher reward)
                if claim.get("is_offshore", false):
                        score += 20.0 * bot["risk_tolerance"]
                
                # Affordability
                if bot["monthly_budget"] >= price:
                        score += 15.0
                
                # Random factor for unpredictability
                score += randf_range(-10.0, 10.0)
                
                scored_claims.append({"claim": claim, "score": score})
        
        if scored_claims.is_empty():
                return {}
        
        # Sort and pick best
        scored_claims.sort_custom(func(a, b): return a["score"] > b["score"])
        return scored_claims[0]["claim"]

func _strategic_sabotage(bot):
        # Find regions where player is most active
        var player_regions = []
        
        for region_name in game_manager.regions:
                var stored = game_manager.oil_stored.get(region_name, 0)
                var capacity = game_manager.tank_capacity.get(region_name, 0)
                
                if stored > 0 or capacity > 0:
                        player_regions.append({
                                "name": region_name,
                                "activity": stored + capacity * 0.5
                        })
        
        if player_regions.is_empty():
                return
        
        # Sort by activity - target most profitable regions
        player_regions.sort_custom(func(a, b): return a["activity"] > b["activity"])
        
        var target_region = player_regions[0]["name"]
        
        # Choose sabotage type based on situation
        var sabotage_types = GameData.SABOTAGE_OPTIONS.keys()
        if sabotage_types.is_empty(): return
        
        # Prefer theft if player has lots of oil stored
        var stored = game_manager.oil_stored.get(target_region, 0)
        var chosen_type = "theft"
        
        if stored > 50000:
                chosen_type = "theft"  # Steal from rich targets
        elif game_manager.tank_capacity.get(target_region, 0) > 1000000:
                chosen_type = "destroy_tank"  # Destroy capacity
        else:
                chosen_type = sabotage_types[randi() % sabotage_types.size()]
        
        print(">>> " + bot["name"] + " versucht SABOTAGE (" + chosen_type + ") in " + target_region)
        game_manager.ai_perform_sabotage(chosen_type, target_region)

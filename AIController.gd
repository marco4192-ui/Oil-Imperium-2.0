extends Node

const GameData = preload("res://GameData.gd")

var game_manager = null

# --- KI KONFIGURATION ---
# Die KI spielt nach denselben Regeln wie der Spieler: Claims kosten genauso,
# Bohrungen dauern 3 Monate und kosten echtes Geld, Öl braucht Tankkapazität
# und kann nur 1x pro Monat und Region verkauft werden.
var competitors = [
        {
                "name": "KI_1",
                "color": Color.RED,
                "cash": 8000000.0,
                "aggressiveness": 0.9,
                "sabotage_tendency": 0.15,
                "risk_tolerance": 0.7,
                "expansion_priority": 0.8,
                "focus_regions": ["Texas", "Mexiko", "Venezuela"],
                "inventory": [],
                "owned_regions": {},
                "monthly_budget": 0,
                "projects": [],          # laufende Bohrungen {claim, region, months_left}
                "storage": {},           # region -> bbl im Tank
                "tanks": {},             # region -> Tankkapazität
                "licensed_regions": []   # eigene Lizenzen in gesperrten Regionen
        },
        {
                "name": "KI_2",
                "color": Color.YELLOW,
                "cash": 9000000.0,
                "aggressiveness": 0.7,
                "sabotage_tendency": 0.10,
                "risk_tolerance": 0.4,
                "expansion_priority": 0.6,
                "focus_regions": ["Nordsee", "Nigeria", "Indonesien"],
                "inventory": [],
                "owned_regions": {},
                "monthly_budget": 0,
                "projects": [],
                "storage": {},
                "tanks": {},
                "licensed_regions": []
        },
        {
                "name": "KI_3",
                "color": Color.GREEN,
                "cash": 7000000.0,
                "aggressiveness": 0.8,
                "sabotage_tendency": 0.12,
                "risk_tolerance": 0.5,
                "expansion_priority": 0.7,
                "focus_regions": ["Saudi-Arabien", "Libyen", "Alaska"],
                "inventory": [],
                "owned_regions": {},
                "monthly_budget": 0,
                "projects": [],
                "storage": {},
                "tanks": {},
                "licensed_regions": []
        }
]

# --- STRATEGISCHE KONSTANTEN ---
const MIN_RESERVE_CASH = 2000000       # Notreserve, ähnlich wie ein Spieler haushalten würde
const MAX_CLAIMS_PER_REGION = 2        # keine Regionen-Monopolisierung
const MAX_WELLS_PER_BOT = 10           # Kapazitätsgrenze der KI-Firma
const EXPANSION_COOLDOWN_MONTHS = 2    # max. 1 Feldkauf alle 2 Monate
const DRILL_MONTHS = 3                 # gleiche Bohrdauer wie beim Spieler (90 Tage)
const AI_SALE_PRICE_FACTOR = 0.85      # KI verkauft ohne Minigame, mit Abschlag + Betriebsrisiko
const AI_EFFICIENCY = 0.75             # Förderwirkungsgrad der KI-Crews
const AI_DRILL_COST_FACTOR = 1.1       # Profi-Crews: teurer als Selbstbau, ohne Premium-Aufschlag

# Schwierigkeitsabhängige Skalierung (0=Easy, 1=Normal, 2=Hard, 3=Brutal)
const DIFFICULTY_CASH_MULT = {0: 0.7, 1: 1.0, 2: 1.25, 3: 1.6}
const DIFFICULTY_COST_MULT = {0: 1.2, 1: 1.0, 2: 0.9, 3: 0.8}

func _ready():
        await get_tree().create_timer(0.5).timeout

        if is_instance_valid(game_manager):
                var company_names = []
                for c in GameData.COMPANIES:
                        company_names.append(c["name"])

                company_names.shuffle()

                var cash_mult = 1.0
                if game_manager:
                        cash_mult = DIFFICULTY_CASH_MULT.get(game_manager.difficulty_level, 1.0)

                for i in range(competitors.size()):
                        if i < company_names.size():
                                competitors[i]["name"] = company_names[i]
                        competitors[i]["cash"] *= cash_mult
                        print("KI Spieler initialisiert: " + competitors[i]["name"] + " (Cash: $" + str(int(competitors[i]["cash"])) + ")")

func _cost_mult() -> float:
        if game_manager == null:
                return 1.0
        return DIFFICULTY_COST_MULT.get(game_manager.difficulty_level, 1.0)

var ai_monthly_sold_total := 0.0   # KI-Anteil am monatlichen Marktlimit

func process_ai_turn():
        if game_manager == null: return

        print("\n--- KI ZUG BEGINNT ---")
        ai_monthly_sold_total = 0.0

        for bot in competitors:
                bot["expansion_cooldown"] = max(0, bot.get("expansion_cooldown", 0) - 1)
                _process_bot_economy(bot)
                _process_projects(bot)
                _calculate_budget(bot)

                # Strategische Expansion (max. 2 Versuche pro Monat, Budget entscheidet)
                if randf() < bot["aggressiveness"] * bot["expansion_priority"]:
                        _smart_expansion(bot)
                if bot["monthly_budget"] > 500000:
                        _smart_expansion(bot)

                # Sabotage gegen den Spieler (strategisch)
                if randf() < bot["sabotage_tendency"]:
                        _strategic_sabotage(bot)

# ==============================================================================
# WIRTSCHAFT (gleiche Regeln wie beim Spieler)
# ==============================================================================

func _process_bot_economy(bot):
        var mult = _cost_mult()

        # 1) Laufende Kosten: Verwaltung + Rig-Wartung für gebohrte Felder
        var rig_cost = 0.0
        for claim in bot["inventory"]:
                if claim == null or typeof(claim) != TYPE_DICTIONARY: continue
                if claim.get("drilled", false):
                        if claim.get("is_offshore", false):
                                rig_cost += game_manager.RIG_MAINTENANCE_OFFSHORE
                        else:
                                rig_cost += game_manager.RIG_MAINTENANCE_ONSHORE
        var admin = 5000.0 * game_manager.inflation_rate
        bot["cash"] -= (admin + rig_cost) * game_manager.inflation_rate * mult

        # 2) Tankkosten (gleiche Formel wie beim Spieler)
        for region_name in bot["tanks"].keys():
                var cap = bot["tanks"][region_name]
                if cap > 0:
                        var land = game_manager.TANK_LAND_LEASE_MONTHLY
                        var staff = (cap / 100000.0) * game_manager.TANK_STAFF_PER_100K
                        var maint = (cap * game_manager.TANK_BUILD_COST_PER_BBL) * game_manager.TANK_MAINTENANCE_RATE
                        bot["cash"] -= (land + staff + maint) * game_manager.inflation_rate * mult

        # 3) Tank nachrüsten (max. 1 pro Monat), wenn Förderung den Speicher sprengt
        if bot["cash"] > MIN_RESERVE_CASH + game_manager.get_tank_cost(250000) * mult:
                for claim in bot["inventory"]:
                        if claim == null or typeof(claim) != TYPE_DICTIONARY: continue
                        if not (claim.get("drilled", false) and claim.get("has_oil", false)): continue
                        var region_name = claim.get("region", "")
                        if region_name == "": continue
                        if bot["tanks"].get(region_name, 0) >= 500000: continue
                        bot["tanks"][region_name] = bot["tanks"].get(region_name, 0) + 250000
                        bot["cash"] -= game_manager.get_tank_cost(250000) * mult
                        break

        # 4) Produktion in Tanks (gleiche Mengen wie beim Spieler, Tank ist Limit)
        for claim in bot["inventory"]:
                if claim == null or typeof(claim) != TYPE_DICTIONARY: continue
                if not (claim.get("drilled", false) and claim.get("has_oil", false)): continue
                if claim.get("reserves_remaining", 0) <= 0: continue
                var region_name = claim.get("region", "")
                if region_name == "": continue
                var cap = bot["tanks"].get(region_name, 0)
                if cap <= 0: continue
                var stored = bot["storage"].get(region_name, 0.0)
                var monthly = claim.get("yield", 0.0) * 30.0 * AI_EFFICIENCY
                monthly = min(monthly, cap - stored, claim.get("reserves_remaining", 0.0))
                if monthly > 0:
                        bot["storage"][region_name] = stored + monthly
                        claim["reserves_remaining"] -= monthly

        # 5) Verkauf: 1x pro Monat und Region, mit Qualitaet/Saison wie beim Spieler
        #    plus kleinem Abschlag (die KI umgeht kein Minigame, hat aber kein Netz/Raffinerie-Bonus)
        for region_name in bot["storage"].keys():
                var stored = bot["storage"].get(region_name, 0.0)
                if stored < 1000.0: continue
                var sale = stored
                var cap = game_manager.get_current_sale_cap() * 0.6
                if cap > 0.0:
                        sale = min(sale, max(0.0, cap - ai_monthly_sold_total))
                if sale < 1000.0: continue
                var per_bbl = game_manager.get_region_quality_factor(region_name) \
                        * game_manager.get_seasonal_price_factor() * game_manager.oil_price
                var value = sale * per_bbl * AI_SALE_PRICE_FACTOR
                bot["cash"] += value
                bot["storage"][region_name] = max(0.0, stored - sale)
                ai_monthly_sold_total += sale
                # Betriebsrisiko: Unfaelle/Wartung fressen 10% des Verkaufserloeses
                bot["cash"] -= value * 0.10
                if value > 500000.0:
                        _log_ai(bot, game_manager.activity_feed.ACTIVITY_TYPE.AI_EXPANSION,
                                {"region": region_name, "info": "Öl-Verkauf: $%s" % game_manager.format_cash(value)})

func _process_projects(bot):
        var finished = []
        for project in bot["projects"]:
                project["months_left"] -= 1
                var claim = project["claim"]
                if claim != null and typeof(claim) == TYPE_DICTIONARY:
                        claim["ai_drill_progress"] = clampf(1.0 - float(project["months_left"]) / DRILL_MONTHS, 0.0, 1.0)
                if project["months_left"] <= 0:
                        finished.append(project)
        for project in finished:
                bot["projects"].erase(project)
                var claim = project["claim"]
                if claim != null and typeof(claim) == TYPE_DICTIONARY:
                        claim["drilled"] = true
                        claim.erase("ai_drill_progress")
                _log_ai(bot, game_manager.activity_feed.ACTIVITY_TYPE.AI_EXPANSION,
                        {"region": project.get("region", "?"), "info": "Ölfeld erschlossen"})

func _calculate_budget(bot):
        # Budget = verfügbares Geld nach Reserve und laufenden Bohrprojekten
        var committed = 0.0
        for project in bot["projects"]:
                committed += project.get("remaining_cost", 0.0)
        var available = bot["cash"] - MIN_RESERVE_CASH - committed
        bot["monthly_budget"] = max(0, available * bot["aggressiveness"] * 0.3)

# ==============================================================================
# EXPANSION
# ==============================================================================

func _smart_expansion(bot):
        if bot["monthly_budget"] < 100000:
                return  # Not enough budget
        if bot.get("expansion_cooldown", 0) > 0:
                return  # max. 1 Feldkauf alle 2 Monate
        if bot["inventory"].size() >= MAX_WELLS_PER_BOT:
                return  # Firmen-Kapazität erreicht

        # Step 1: Find best region to expand
        var best_region = _evaluate_best_region(bot)
        if best_region == "":
                return

        # Step 2: Find best claim in that region
        var best_claim = _find_best_claim(bot, best_region)
        if best_claim == null or best_claim.is_empty():
                return

        # Step 3: Gesamtkosten = Claim + Bohrung (echtes Geld, wie beim Spieler)
        var price = best_claim.get("price", 999999999)
        var offshore = best_claim.get("is_offshore", false)
        var drill_cost = _estimate_drill_cost(offshore) * _cost_mult()

        # License für gesperrte Regionen zahlen (eigene Lizenz, wie beim Spieler)
        var region = game_manager.regions.get(best_region, {})
        var license_fee = 0.0
        if not region.get("unlocked", false) and not bot["licensed_regions"].has(best_region):
                license_fee = region.get("license_fee", 0) * 1.2 * game_manager.inflation_rate

        if bot["cash"] - price - drill_cost - license_fee < MIN_RESERVE_CASH:
                return

        if price + drill_cost + license_fee > bot["monthly_budget"] * 1.5:
                return

        # Execute purchase + Bohrprojekt starten
        bot["cash"] -= price
        if license_fee > 0:
                bot["cash"] -= license_fee
                bot["licensed_regions"].append(best_region)
                _log_ai(bot, game_manager.activity_feed.ACTIVITY_TYPE.AI_LICENSE,
                        {"region": best_region, "info": "Lizenz erworben"})
        best_claim["ai_owner"] = bot["name"]
        best_claim["region"] = best_region
        best_claim["ai_drill_progress"] = 0.0
        bot["inventory"].append(best_claim)
        bot["cash"] -= drill_cost
        bot["projects"].append({"claim": best_claim, "region": best_region, "months_left": DRILL_MONTHS})

        # Track region ownership
        if not bot["owned_regions"].has(best_region):
                bot["owned_regions"][best_region] = 0
        bot["owned_regions"][best_region] += 1
        bot["monthly_budget"] -= price + drill_cost
        bot["expansion_cooldown"] = EXPANSION_COOLDOWN_MONTHS

        print(">>> " + bot["name"] + " KAUFT UND BOHRT in " + best_region + " (Feld: $" + str(int(price)) + ", Bohrung: $" + str(int(drill_cost)) + ", " + str(DRILL_MONTHS) + " Monate)")

        _log_ai(bot, game_manager.activity_feed.ACTIVITY_TYPE.AI_PURCHASE,
                {"region": best_region, "price": int(price)})

func _estimate_drill_cost(offshore: bool) -> float:
        # Spiegelt die Selbst-Bohrkosten des Spielers wider (calculate_drilling_costs_internal)
        var crew = 40.0 if offshore else 12.0
        var days = 90.0
        var flights = crew * game_manager.COST_FLIGHT_TICKET
        var hotel = crew * days * game_manager.COST_HOTEL_NIGHT
        var wages = crew * days * game_manager.COST_WAGE_DAILY
        var pump = game_manager.COST_OFFSHORE_PLATFORM if offshore else game_manager.COST_PUMP_JACK
        var bits = (2.0 * game_manager.BITS_NEEDED_PER_KM) * game_manager.COST_DRILL_BIT
        var pipe = game_manager.AVG_PIPELINE_DIST_KM * game_manager.COST_PIPELINE_KM
        var rate = game_manager.RIG_RATE_OFFSHORE if offshore else game_manager.RIG_RATE_ONSHORE
        var rig = rate * days * 0.3
        var total = (flights + hotel + pipe + game_manager.LOGISTICS_SETUP_FEE + pump + rig + bits + wages) * 0.6
        return total * AI_DRILL_COST_FACTOR

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

                # Kein weiteres Investment, wenn das Regions-Limit erreicht ist (harter Filter)
                var owned_in_region = bot["owned_regions"].get(region_name, 0)
                if owned_in_region >= MAX_CLAIMS_PER_REGION:
                        continue

                # Lizenzkosten einpreisen
                if not region.get("unlocked", false) and not bot["licensed_regions"].has(region_name):
                        score -= region.get("license_fee", 0) / 100000.0

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

# ==============================================================================
# SABOTAGE
# ==============================================================================

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
        var region_stored = game_manager.oil_stored.get(target_region, 0)
        var chosen_type = "theft"

        if region_stored > 50000:
                chosen_type = "theft"  # Steal from rich targets
        elif game_manager.tank_capacity.get(target_region, 0) > 1000000:
                chosen_type = "destroy_tank"  # Destroy capacity
        else:
                chosen_type = sabotage_types[randi() % sabotage_types.size()]

        print(">>> " + bot["name"] + " versucht SABOTAGE (" + chosen_type + ") in " + target_region)

        _log_ai(bot, game_manager.activity_feed.ACTIVITY_TYPE.AI_SABOTAGE,
                {"region": target_region, "type": chosen_type})

        game_manager.ai_perform_sabotage(chosen_type, target_region)

func _log_ai(bot, type: int, data: Dictionary):
        if game_manager and game_manager.activity_feed:
                var payload = {"company": bot["name"]}
                for key in data.keys():
                        payload[key] = data[key]
                game_manager.activity_feed.log_activity(type, payload)

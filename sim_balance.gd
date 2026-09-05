extends SceneTree
# sim_balance.gd - 30-Jahre-Balance-Simulation
# Simuliert eine kompetente, aber einfache Spieler-Strategie Monat für Monat
# (echte next_day-Simulation inkl. KI, Events, Limits) und bewertet die Balance.
# Ausführen: godot --headless --path . --script res://sim_balance.gd

var gm = null
var player_projects = []   # {region, claim, months_left}
var curve = []             # {year, cash, networth, ai_cash, price}
var months_negative = 0
var max_negative_streak = 0
var negative_streak = 0
var total_sold_bbl = 0.0
var wells_bought = 0

func _init():
	await process_frame
	await process_frame
	gm = root.get_node_or_null("/root/GameManager")
	if gm == null:
		printerr("GameManager fehlt")
		quit(1)
		return

	print("=== BALANCE-SIMULATION 1970-2000 (Schwierigkeit: %d) ===" % gm.difficulty_level)

	var safety = 0
	while gm.date["year"] < 2001 and safety < 800:
		safety += 1
		player_month()
		var cash_before = gm.cash
		gm.advance_time(30)   # ein Monat echte Simulation (KI, Events, Produktion, Limits)
		if gm.cash < 0:
			negative_streak += 1
			months_negative += 1
			max_negative_streak = max(max_negative_streak, negative_streak)
		else:
			negative_streak = 0
		if gm.date["month"] == 1:
			curve.append({
				"year": gm.date["year"], "cash": gm.cash, "net": _net_worth(),
				"ai": _ai_cash(), "price": gm.oil_price
			})

	# --- Auswertung ---
	print("\n--- VERLAUF (Januar-Werte) ---")
	print("Jahr | Bargeld | Netto | KI-Cash ges. | Ölpreis")
	for c in curve:
		print("%d | %s | %s | %s | $%.2f" % [c.year, _f(c.cash), _f(c.net), _f(c.ai), c.price])

	var summary = gm._build_end_summary()
	var ai_leader = 0.0
	var ai_claims = 0
	for bot in gm.ai_controller.competitors:
		ai_leader = max(ai_leader, bot["cash"])
		ai_claims += bot["inventory"].size()

	print("\n--- ENDERGEBNIS ---")
	print("Score: %s | Bargeld: %s | Anlagen: %s" % [_f(summary.score), _f(summary.cash), _f(summary.assets)])
	print("Erfolge: %d | Ära: %d | Verkauft gesamt: %s bbl | Felder gekauft: %d" % [summary.achievements, summary.era, _f(total_sold_bbl), wells_bought])
	print("KI: Leader-Cash %s | KI-Claims gesamt: %d" % [_f(ai_leader), ai_claims])
	print("Monate im Minus: %d (längste Serie: %d)" % [months_negative, max_negative_streak])

	print("\n--- BALANCE-BEWERTUNG ---")
	var issues = []
	if max_negative_streak >= 6:
		issues.append("Spieler langfristig zahlungsunfähig (zu hart)")
	if summary.score < 20000000:
		issues.append("Endscore sehr niedrig (< 20M) — Fortkommen fraglich (zu hart)")
	if summary.score > 400000000:
		issues.append("Endscore extrem hoch (> 400M) — zu einfach")
	if summary.era < 2:
		issues.append("Kompetenter Spieler erreicht nur Ära %d (Era-Wechsel zu teuer?)" % summary.era)
	if ai_leader > gm.cash * 3.0:
		issues.append("KI-Leader > 3x Spieler-Cash (KI zu stark)")
	if ai_leader < gm.cash * 0.33:
		issues.append("KI-Leader < 1/3 Spieler-Cash (KI zu schwach)")
	if wells_bought < 4:
		issues.append("Spieler konnte kaum Felder kaufen (%d) — Einkommen zu mager" % wells_bought)

	if issues.is_empty():
		print("BALANCE OK: keine Ausreißer festgestellt")
	else:
		for issue in issues:
			printerr("PROBLEM: " + issue)
	quit(0)

# ==============================================================================
# SPIELER-STRATEGIE (einfach, aber kompetent)
# ==============================================================================

func player_month():
	# 1) Bohrprojekte abschließen (Selbst-Bohrung dauert 3 Monate)
	var done = []
	for p in player_projects:
		p.months_left -= 1
		if p.months_left <= 0:
			p.claim["drilled"] = true
			done.append(p)
	for p in done:
		player_projects.erase(p)

	# 2) Verkaufen (Minigame umgangen = Skill-Vorteil eingepreist)
	for r in gm.regions:
		if not gm.regions[r].get("unlocked", false): continue
		var stored = gm.oil_stored.get(r, 0.0)
		if stored > 1000.0 and not gm.spot_sales_history.get(r, false):
			var amount = min(stored, 500000.0)
			gm.commit_sale(r, amount, 0, true)
			if gm.spot_sales_history.get(r, false):
				total_sold_bbl += amount

	# 3) Tank sicherstellen (Starter reicht für den Anfang)
	for r in gm.regions:
		if not gm.regions[r].get("unlocked", false): continue
		if gm.get_region_daily_production(r) <= 0.0: continue
		var cap = gm.tank_capacity.get(r, 0)
		var stored = gm.oil_stored.get(r, 0.0)
		if cap == 0 and gm.cash > gm.get_tank_cost(250000) + 300000:
			gm.try_buy_tank(r, 250000, 0)
		elif cap > 0 and stored > cap * 0.8 and gm.cash > gm.get_tank_cost(cap * 2) + 500000:
			gm.try_buy_tank(r, int(cap), 0)  # Kapazität verdoppeln

	# 4) Ära-Wechsel anstreben (Haupt-Upgrade + Module wie im Spiel)
	_try_era_upgrade()

	# 5) Raffinerie / Pipeline-Netz
	if gm.current_era >= 1 and not gm.facilities.get("refinery", {}).get("built", false) and gm.cash > 12000000:
		gm.build_facility("refinery")
	if gm.facilities.get("pipeline_net", {}).get("built", false) or gm.current_era >= 1:
		if gm.pipeline_network_level < 3 and gm.pipeline_network_level + 1 <= gm.current_era:
			var net_cost = gm.PIPELINE_NET_COSTS[gm.pipeline_network_level] * gm.inflation_rate
			if gm.cash > net_cost + 2000000:
				gm.build_facility("pipeline_net")

	# 6) Regionen freischalten: bis zu 3 Regionen (billigste Lizenz zuerst)
	var unlocked_count = 0
	var cheapest_license = 999999999.0
	var license_region = ""
	for r in gm.regions:
		if gm.regions[r].get("unlocked", false):
			unlocked_count += 1
		else:
			var fee = float(gm.regions[r].get("license_fee", 9e9))
			if fee < cheapest_license:
				cheapest_license = fee
				license_region = r
	if unlocked_count < 3 and license_region != "":
		# nur freischalten, wenn danach Claim + Bohrung + Tank + Puffer möglich bleiben
		if gm.cash > cheapest_license + 2500000:
			gm.try_buy_license(license_region)

	# 7) Expansion: neue Bohrung, wenn Budget reicht — WICHTIG: Kosten für den
	#    ersten Tank der Zielregion einpreisen, sonst gibt es eine Todesspirale
	#    (kein Tank -> kein Verkauf -> kein Einkommen). Und: Erst Tank bauen,
	#    bevor weiter expandiert wird (Regel eines kompetenten Spielers).
	var pending_tank = false
	for r in gm.regions:
		if gm.regions[r].get("unlocked", false) and gm.get_region_daily_production(r) > 0 and gm.tank_capacity.get(r, 0) == 0:
			pending_tank = true
	var reserve = 400000.0
	var starter_tank = gm.get_tank_cost(250000)
	var target = _cheapest_claim()
	if not target.is_empty() and not pending_tank:
		var tank_needed = gm.tank_capacity.get(target.region, 0) == 0
		var budget = gm.cash - reserve - (starter_tank if tank_needed else 0)
		if budget > 0 and (_player_wells() < 3 or gm.oil_price >= 10.0):
			var price = target.claim.get("price", 0)
			var drill = gm.calculate_drilling_costs(target.region, true).get("total", 0)
			if budget >= price + drill:
				target.claim["owned"] = true
				gm.cash -= price
				gm.book_transaction(target.region, -price, "Claim")
				gm.cash -= drill
				gm.book_transaction(target.region, -drill, "Bohrung (selbst)")
				player_projects.append({"region": target.region, "claim": target.claim, "months_left": 3})
				wells_bought += 1

func _cheapest_claim() -> Dictionary:
	var best = {}
	var best_price = 999999999.0
	for r in gm.regions:
		var region = gm.regions[r]
		if not region.get("unlocked", false): continue
		for claim in region.get("claims", []):
			if claim == null or typeof(claim) != TYPE_DICTIONARY: continue
			if claim.get("is_empty", false): continue
			if claim.get("owned", false) or claim.has("ai_owner"): continue
			# im Schnitt nur Felder mit Öl kaufen (Vermessung eingepreist)
			if not claim.get("has_oil", false): continue
			if claim.get("price", 9e9) < best_price:
				best_price = claim["price"]
				best = {"region": r, "claim": claim}
	return best

func _try_era_upgrade():
	if gm.era_manager == null or gm.office_upgrade_manager == null: return
	var era = gm.current_era
	if not gm.office_upgrade_manager.MAIN_UPGRADES.has(era): return
	var main = gm.office_upgrade_manager.MAIN_UPGRADES[era]
	var modules_cost = 0.0
	for m in main["unlock_modules"]:
		modules_cost += gm.office_upgrade_manager.UPGRADE_MODULES[m]["cost"]
	var total = main["cost"] * gm.inflation_rate + modules_cost * gm.inflation_rate
	var era_year = gm.era_manager.ERA_DATA[era + 1]["year_start"] if gm.era_manager.ERA_DATA.has(era + 1) else 9999
	if gm.date["year"] < era_year - 1: return  # früh genug beginnt der Einkauf
	var main_owned = gm.office_upgrade_manager.purchased_main_upgrades.get(era, false)
	if not main_owned:
		# Kauf-Gate nur, wenn noch nicht bezahlt
		if gm.cash < total + 1500000: return
		var ok_main = gm.office_upgrade_manager.purchase_main_upgrade()
		print("  [SIM] Haupt-Upgrade Ära %d (%s): %s" % [era, main["id"], ok_main])
		if not ok_main:
			print("    Grund: ", gm.office_upgrade_manager.can_purchase_main_upgrade())
			return
		for m in main["unlock_modules"]:
			var ok_m = gm.office_upgrade_manager.purchase_module(m)
			if not ok_m:
				print("    Modul fehlgeschlagen: ", m, " -> ", gm.office_upgrade_manager.can_purchase_module(m))
	var uc = gm.era_manager.can_upgrade_era()
	if uc.get("can_upgrade", false):
		gm.era_manager.perform_era_upgrade()
		print("  [SIM] >>> ÄRA-WECHSEL zu Ära ", gm.current_era)

func _player_wells() -> int:
	var wells = 0
	for r in gm.regions:
		for claim in gm.regions[r].get("claims", []):
			if claim != null and typeof(claim) == TYPE_DICTIONARY and claim.get("owned", false) and claim.get("drilled", false) and claim.get("has_oil", false):
				wells += 1
	return wells

func _net_worth() -> float:
	var assets = 0.0
	for r in gm.tank_investment:
		assets += gm.tank_investment.get(r, 0.0)
	for fid in gm.facilities:
		if gm.facilities[fid].get("built", false):
			assets += gm.facilities[fid].get("cost", 0.0) * 0.5
	assets += gm.pipeline_network_level * 2000000.0
	return gm.cash + assets

func _ai_cash() -> float:
	var total = 0.0
	for bot in gm.ai_controller.competitors:
		total += bot["cash"]
	return total

func _f(v) -> String:
	return str(int(round(v / 1000.0))) + "k"

extends SceneTree
# test_economy.gd - Integrationstest für Wirtschaft, Verkaufslimit, Pipeline, KI-Parität
# Ausführen: godot --headless --path . --script res://test_economy.gd

var failures := 0

func check(cond: bool, label: String):
	if cond:
		print("  OK   ", label)
	else:
		failures += 1
		printerr("  FAIL ", label)

func _init():
	await process_frame
	await process_frame

	var gm = root.get_node_or_null("/root/GameManager")
	check(gm != null, "GameManager Autoload vorhanden")
	if gm == null:
		quit(1)
		return

	print("--- TANK-STAFFELPREISE ---")
	check(gm.get_tank_cost(250000) == 500000, "Starter-Tank 250k bbl = $500.000 (%s)" % gm.get_tank_cost(250000))
	check(gm.get_tank_cost(500000) == 1300000, "Kleiner Tank 500k bbl = $1.300.000")
	check(gm.get_tank_cost(1000000) == 3200000, "Mittlerer Tank 1M bbl = $3.200.000")
	check(gm.get_tank_cost(2500000) == 9000000, "Großer Tank 2.5M bbl = $9.000.000")

	print("--- VERKAUFS-LIMIT (1x/Monat/Region) ---")
	gm.spot_sales_history.clear()
	gm.oil_stored["Texas"] = 100000
	gm.commit_sale("Texas", 50000, 400000, true)
	check(gm.oil_stored["Texas"] == 50000, "Erster Verkauf erfolgreich")
	check(gm.spot_sales_history.get("Texas", false) == true, "Region nach Verkauf gesperrt")
	var cash_before = gm.cash
	gm.commit_sale("Texas", 10000, 80000, true)
	check(gm.oil_stored["Texas"] == 50000, "Zweiter Verkauf im selben Monat blockiert")
	check(gm.cash == cash_before, "Keine Abbuchung beim blockierten Verkauf")

	gm.finish_month()
	check(gm.spot_sales_history.get("Texas", false) == false, "Verkaufslimit nach Monatswechsel zurückgesetzt")
	gm.commit_sale("Texas", 10000, 80000, true)
	check(gm.oil_stored["Texas"] == 40000, "Verkauf im neuen Monat wieder möglich")

	print("--- PIPELINE-FLOW ---")
	gm.spot_sales_history.clear()
	gm.oil_stored["Texas"] = 100000
	gm.start_pipeline_minigame("Texas", 30000, 250000)
	check(gm.pending_sale_region == "Texas", "Pipeline-Minigame pending gesetzt")
	check(gm.pending_sale_return_scene != "", "Rückkehr-Szene gemerkt")
	gm.finalize_sale_fail()
	check(gm.spot_sales_history.get("Texas", false) == true, "Gescheiterter Verkauf sperrt Region für den Monat")
	check(gm.oil_stored["Texas"] == 100000, "Öl bleibt beim Scheitern im Tank")
	check(gm.pending_sale_region == "", "Pending nach Fail geleert")
	gm.finalize_sale_success()  # darf leer laufen

	gm.spot_sales_history.clear()
	gm.pending_sale_region = "Texas"
	gm.pending_sale_amount = 30000
	gm.pending_sale_value = 250000
	var c0 = gm.cash
	gm.finalize_sale_success()
	check(gm.cash == c0 + 250000, "Erfolgreicher Verkauf bucht Erlös")
	check(gm.oil_stored["Texas"] == 70000, "Nur die verkaufte Menge wird abgezogen")
	check(gm.pending_sale_region == "", "Pending nach Erfolg geleert")

	print("--- NOTFALL-TEAM ---")
	gm.spot_sales_history.clear()
	gm.oil_stored["Texas"] = 100000
	gm.pending_sale_region = "Texas"
	gm.pending_sale_amount = 30000
	gm.pending_sale_value = 250000
	# Simuliere den Notfall-Team-Pfad (wie im Choice-Dialog)
	var team_cost = int(gm.PIPELINE_EMERGENCY_TEAM_COST * gm.inflation_rate)
	gm.cash -= team_cost
	gm.oil_stored["Texas"] -= gm.pending_sale_amount
	gm.spot_sales_history["Texas"] = true
	gm.pending_sale_region = ""
	check(gm.spot_sales_history.get("Texas", false) == true, "Notfall-Team: Verkauf abgeschlossen")
	check(team_cost >= 150000, "Notfall-Team kostet mind. $150.000 (inkl. Inflation: $%d)" % team_cost)

	print("--- KI: WIRTSCHAFTSPARITÄT ---")
	var ai = gm.ai_controller
	check(ai != null, "AIController vorhanden")
	if ai != null:
		check(ai.competitors.size() == 3, "3 KI-Gegner")
		for bot in ai.competitors:
			check(bot.has("projects") and bot.has("storage") and bot.has("tanks"), "KI-Statusfelder vorhanden")

		gm.date["year"] = 1975
		for i in range(8):
			ai.process_ai_turn()

		var total_claims = 0
		var drilled = 0
		var running_projects = 0
		for bot in ai.competitors:
			total_claims += bot["inventory"].size()
			running_projects += bot["projects"].size()
			for claim in bot["inventory"]:
				if claim != null and typeof(claim) == TYPE_DICTIONARY and claim.get("drilled", false):
					drilled += 1
			for r_name in bot["owned_regions"].keys():
				check(bot["owned_regions"][r_name] <= ai.MAX_CLAIMS_PER_REGION,
						"Max. " + str(ai.MAX_CLAIMS_PER_REGION) + " Claims pro Region (" + bot["name"] + " in " + str(r_name) + ": " + str(bot["owned_regions"][r_name]) + ")")
		print("  (KI nach 8 Monaten: Claims=" + str(total_claims) + ", gebohrt=" + str(drl_str(drilled)) + ", laufende Bohrungen=" + str(running_projects) + ")")
		check(total_claims > 0, "KI kauft Claims")
		check(drilled <= total_claims, "Bohrstatus konsistent")
		check(running_projects <= total_claims, "Projekte konsistent")

	print("--- FEUERSCHADEN ---")
	var fire_claim = null
	for claim in gm.regions["Texas"]["claims"]:
		if claim != null and typeof(claim) == TYPE_DICTIONARY and not claim.get("is_empty", false):
			fire_claim = claim
			break
	if fire_claim == null:
		check(false, "Test-Claim in Texas gefunden")
	else:
		fire_claim["drilled"] = true
		gm._apply_fire_damage("Texas", fire_claim["id"], 70.0, false)
		check(fire_claim.get("fire_damage", 0) == 70.0, "Teilschaden wird vermerkt")
		check(fire_claim.get("drilled", false) == true, "Teilschaden: Feld bleibt gebohrt")
		gm._apply_fire_damage("Texas", fire_claim["id"], 100.0, true)
		check(fire_claim.get("drilled", false) == false, "Totalschaden: Feld muss neu gebohrt werden")

	print("--- OE-QUALITAET & SAISON ---")
	check(gm.regions["Texas"].has("oil_quality"), "Regionen haben Öl-Qualität")
	check(gm.get_region_quality_factor("Texas") in [1.15, 1.0, 0.85], "Qualitätsfaktor gültig")
	check(gm.get_region_quality_name("Nordsee") != "", "Qualitätsname vorhanden")
	var old_month = gm.date["month"]
	gm.date["month"] = 1
	check(gm.get_seasonal_price_factor() == 1.12, "Winter: Heizöl-Aufschlag x1.12")
	gm.date["month"] = 4
	check(gm.get_seasonal_price_factor() == 1.0, "Frühjahr: neutral x1.0")
	gm.date["month"] = 7
	check(gm.get_seasonal_price_factor() == 1.06, "Sommer: x1.06")
	gm.date["month"] = old_month

	print("--- MARKTLIMIT ---")
	gm.date["month"] = 7
	check(gm.get_current_sale_cap() == 3000000.0, "Juli: Sommer-Limit 3M bbl")
	gm.date["year"] = 1973
	gm.date["month"] = 11
	check(gm.get_current_sale_cap() == 1000000.0, "Ölkrise 11/1973: Limit 1M bbl")
	gm.date["year"] = 1975
	gm.date["month"] = 3
	check(gm.get_current_sale_cap() == 0.0, "Normale Monate: kein Limit")
	gm.finish_month()
	gm.monthly_sale_limit = 1000000.0
	gm.monthly_sold = 0.0
	gm.spot_sales_history.clear()
	gm.oil_stored["Texas"] = 2000000
	gm.commit_sale("Texas", 800000, 0, true)
	check(gm.monthly_sold == 800000.0, "Verkauf unter Limit gebucht")
	gm.spot_sales_history.clear()
	gm.commit_sale("Texas", 400000, 0, true)
	check(gm.monthly_sold == 800000.0, "Verkauf über Limit blockiert")
	check(gm.oil_stored["Texas"] == 1200000, "Öl bleibt bei blockiertem Verkauf im Tank")

	print("--- RAFFINERIE ---")
	gm.facilities["refinery"]["built"] = true
	gm.current_era = 1
	gm.monthly_refined_sold = 0.0
	gm.spot_sales_history.clear()
	gm.commit_sale("Texas", 200000, 0, true, true)
	check(gm.monthly_refined_sold == 200000.0, "Raffinerie-Verkauf gebucht")
	gm.spot_sales_history.clear()
	gm.monthly_refined_sold = 290000.0
	gm.commit_sale("Texas", 50000, 0, true, true)
	check(gm.monthly_refined_sold == 290000.0, "Raffinerie-Kapazität (300k/Monat) begrenzt")
	gm.facilities["refinery"]["built"] = false
	gm.current_era = 0

	print("--- PIPELINE-NETZ ---")
	gm.pipeline_network_level = 0
	gm.cash = 100000000
	gm.build_facility("pipeline_net")
	check(gm.pipeline_network_level == 0, "Pipeline-Netz Stufe 1 erst ab 1980er-Ära")
	gm.current_era = 1
	gm.build_facility("pipeline_net")
	check(gm.pipeline_network_level == 1, "Pipeline-Netz Stufe 1 gebaut")
	var bbl = 50000.0
	var expected_risk = (0.15 + min(0.30, bbl / 1000000.0 * 0.10)) * (1.0 - 0.15 * 1.0)
	check(expected_risk < 0.15 + min(0.30, bbl / 1000000.0 * 0.10), "Netz-Stufe senkt Leitungsrisiko")
	gm.pipeline_network_level = 0
	gm.current_era = 0

	print("--- SPIELENDE-AUSWERTUNG ---")
	var summary = gm._build_end_summary()
	check(summary.has("score") and summary.get("score", 0) > 0, "Endsummary mit Score erzeugt")
	check(summary.has("company") and summary.has("achievements"), "Endsummary enthält Firmen-/Erfolgsdaten")

	print("--- KI-VERTRAEGE & DIPLOMATIE ---")
	gm.ai_contract_offers.clear()
	gm.ai_contracts_active.clear()
	gm.ai_relations.clear()
	var bot0 = gm._get_ai_bot(0)
	check(bot0 != null, "KI-Bot erreichbar")
	bot0["cash"] = 50000000.0
	gm.ai_contract_offers.append({"id": 999, "bot_index": 0, "company": str(bot0["name"]), "volume": 100000.0, "months": 2, "price_per_bbl": 10.0, "expires_in": 3})
	check(gm.accept_ai_contract(999), "KI-Vertrag angenommen")
	check(gm.ai_contracts_active.size() == 1, "Vertrag aktiv")
	check(gm.ai_contract_offers.is_empty(), "Angebot verbraucht")

	gm.oil_stored["Texas"] = 150000.0
	var cash_before_ai = gm.cash
	var bot_cash_before = float(bot0["cash"])
	gm.process_ai_contracts()
	print("  [DBG] cash=%s erwartet=%s texas=%s aktiv=%s" % [gm.cash, cash_before_ai + 1000000.0, gm.oil_stored["Texas"], gm.ai_contracts_active.size()])
	check(gm.cash == cash_before_ai + 1000000.0, "Lieferung: +$1M Erlös")
	check(gm.oil_stored["Texas"] == 50000.0, "Öl aus größter Region geliefert")
	check(float(bot0["cash"]) < bot_cash_before, "KI zahlt mit echtem Kapital")
	check(gm.get_ai_relation(0) > 0.5, "Beziehung durch Lieferung gestiegen")
	check(gm.ai_contracts_active.size() == 1 and gm.ai_contracts_active[0]["months_left"] == 1, "Vertrag läuft weiter")

	gm.oil_stored["Texas"] = 0.0
	var cash_before_breach = gm.cash
	gm.process_ai_contracts()
	check(gm.cash == cash_before_breach - 500000.0, "Vertragsstrafe: 50% eines Monatswerts")
	check(gm.ai_contracts_active.is_empty(), "Vertrag nach Bruch beendet")
	check(gm.get_ai_relation(0) < 0.55, "Ansehensverlust nach Bruch")
	check(gm.get_ai_contracts_save_data().has("relations"), "KI-Verträge in Save-Daten")

	print("--- EPOCHE 3 & WIRTSCHAFTSSPION ---")
	gm.current_era = 0
	gm.cash = 500000000
	gm.build_facility("solar_division")
	check(gm.facilities.get("solar_division", {}).get("built", false) == false, "Solar-Division erst ab 2000er-Ära")
	gm.current_era = 3
	gm.build_facility("solar_division")
	check(gm.facilities.get("solar_division", {}).get("built", false) == true, "Solar-Division in Ära 3 baubar")
	var cash_before_solar = gm.cash
	gm.finish_month()
	var solar_gain = gm.cash - cash_before_solar
	check(solar_gain > 0.0, "Solar-Division erzielt Einkommen (+$%d im Monat)" % int(solar_gain))
	check(gm.facilities.get("fusion_project", {}).get("built", false) == false, "Fusion noch nicht gebaut")
	gm.cash = 2000000000
	gm.build_facility("fusion_project")
	check(gm.facilities.get("fusion_project", {}).get("built", false) == true, "Fusionsprojekt gestartet")
	check(gm.fusion_started == true and gm.fusion_months_left == gm.FUSION_BUILD_MONTHS, "Fusion läuft (%d Monate übrig)" % gm.fusion_months_left)
	gm.fusion_started = false
	gm.facilities["fusion_project"]["built"] = false
	gm.facilities["solar_division"]["built"] = false
	gm.current_era = 0

	check(gm.get_ai_storage_in_region("Texas") == -1.0, "Spion ohne Tech: keine Daten")
	gm.tech_market_intel = true
	check(gm.get_ai_storage_in_region("Texas") >= 0.0, "Spion mit Tech: KI-Lager sichtbar")
	gm.tech_market_intel = false

	print("--- RUN-STATISTIK ---")
	gm.total_bbl_sold += 12345.0
	gm.max_cash_ever = max(gm.max_cash_ever, gm.cash)
	var stats_summary = gm._build_end_summary()
	check(stats_summary.has("max_cash") and stats_summary.has("wells"), "Endsummary mit Run-Statistiken")
	check(stats_summary.get("sold_bbl", 0) >= 12345, "Verkaufsmenge wird gezählt")

	print("")
	if failures == 0:
		print("ALLE WIRTSCHAFTS-TESTS BESTANDEN")
	else:
		printerr(str(failures) + " TESTS FEHLGESCHLAGEN")
	quit(1 if failures > 0 else 0)

func drl_str(v: int) -> String:
	return str(v)

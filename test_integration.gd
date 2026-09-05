extends SceneTree
# test_integration.gd - Headless-Integrationstest für LegalManager + OfficeUpgradeManager
# Ausführen: godot --headless --path . --script res://test_integration.gd

var failures := 0

func check(cond: bool, label: String):
	if cond:
		print("  OK   ", label)
	else:
		failures += 1
		printerr("  FAIL ", label)

func _init():
	# Autoloads initialisieren lassen
	await process_frame
	await process_frame

	var gm = root.get_node_or_null("/root/GameManager")
	check(gm != null, "GameManager Autoload vorhanden")
	if gm == null:
		quit(1)
		return

	print("--- OFFICE UPGRADE SYSTEM ---")
	var oum = gm.office_upgrade_manager
	check(oum != null, "OfficeUpgradeManager instanziiert")

	var p = oum.can_purchase_main_upgrade()
	check(p["can_purchase"] == false, "Haupt-Upgrade 1970 gesperrt (Jahr): " + str(p.get("reason", "")))

	gm.date["year"] = 1979
	gm.cash = 100000000
	p = oum.can_purchase_main_upgrade()
	check(p["can_purchase"] == true, "Haupt-Upgrade ab 1978+Geld kaufbar")

	check(oum.purchase_main_upgrade(), "Haupt-Upgrade gekauft")
	check(oum.purchased_main_upgrades.get(0, false), "purchased_main_upgrades[0] = true")

	var gate = oum.can_advance_era()
	check(gate["can_advance"] == false, "Ära-Wechsel ohne Module gesperrt: " + str(gate.get("reason", "")))

	for module_id in oum.MAIN_UPGRADES[0]["unlock_modules"]:
		check(oum.purchase_module(module_id), "Modul gekauft: " + module_id)

	gate = oum.can_advance_era()
	check(gate["can_advance"] == true, "Upgrade-Pfad komplett ab 1978 (Haupt-Upgrade + alle Module)")

	var era_check = gm.era_manager.can_upgrade_era()
	check(era_check["can_upgrade"] == false, "EraManager kann gateden Wechsel nicht erlauben (Jahr)")

	gm.date["year"] = 1982
	era_check = gm.era_manager.can_upgrade_era()
	check(era_check["can_upgrade"] == true, "Ära-Wechsel frei nach Upgrades + Jahr")
	check(era_check.get("cost", -1) == 0, "Keine Zusatzkosten beim gegateten Wechsel (bereits bezahlt)")

	var cash_before = gm.cash
	check(gm.era_manager.perform_era_upgrade(), "perform_era_upgrade erfolgreich")
	check(gm.current_era == 1, "Ära ist jetzt 1")
	check(gm.cash == cash_before, "Kasse unverändert (keine Doppelabbuchung)")

	print("--- LEGAL SYSTEM ---")
	var lm = gm.legal_manager
	check(lm != null, "LegalManager instanziiert")

	var case_id = lm._open_case("Texas", "safety_violation")
	check(lm.active_cases.has(case_id), "Fall geöffnet: " + case_id)
	var case_data = lm.active_cases[case_id]
	check(case_data["offense"] == "Sicherheitsverstoß", "Tatbestand korrekt benannt")

	var res = lm.attempt_bribe(case_id)
	print("  (Bestechung: ", res, ")")
	check(lm.active_cases.size() == 0 or res.get("success", false) == false, "Bestechung verarbeitet")

	# Fall zu Ende führen -> Historie (Bestechung entfernt Fälle ohne Historieneintrag,
	# daher neuen Fall ohne Bestechung bis zum Urteil durchlaufen lassen)
	var case2 = lm._open_case("Texas", "safety_violation")
	check(lm.active_cases.has(case2), "Zweiter Fall geöffnet")
	lm.active_cases[case2]["months"] = 6
	lm._process_active_cases()
	check(lm.case_history.size() > 0, "Fallhistorie gefüllt")
	if lm.case_history.size() > 0:
		var entry = lm.case_history[0]
		check(entry.has("guilty") and entry.has("penalty"), "Historieneintrag enthält Urteil")

	check(lm.invest_compliance("Texas", 1000000), "Compliance-Investition")
	check(lm.get_compliance("Texas") > 0.0, "Compliance-Level gestiegen")

	var cash_before_lawyer = gm.cash
	check(lm.hire_lawyer("premium"), "Premium-Anwalt eingestellt")
	check(lm.get_lawyer_quality() == 0.85, "Anwaltsqualität 0.85")
	check(gm.cash < cash_before_lawyer, "Anwaltskosten gebucht")

	print("--- SAVE/LOAD ---")
	gm.save_game("test_integration")
	var legal_saved = lm.get_save_data()
	gm.load_game("test_integration")
	var lm2 = root.get_node("/root/GameManager").legal_manager
	check(lm2 != null, "LegalManager nach Load vorhanden")
	check(lm2.get_lawyer_quality() == 0.85, "Anwaltsqualität aus Save wiederhergestellt")

	print("")
	if failures == 0:
		print("ALLE TESTS BESTANDEN")
	else:
		printerr(str(failures) + " TESTS FEHLGESCHLAGEN")
	quit(1 if failures > 0 else 0)

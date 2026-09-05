extends SceneTree
# test_panels.gd - Prüft, dass beide UI-Panels fehlerfrei aufbauen
# Ausführen: godot --headless --path . --script res://test_panels.gd

func _init():
	await process_frame
	await process_frame

	var gm = root.get_node_or_null("/root/GameManager")
	if gm == null:
		printerr("FAIL: GameManager fehlt")
		quit(1)
		return

	var LegalPanel = load("res://LegalPanel.gd")
	var OfficeUpgradePanel = load("res://OfficeUpgradePanel.gd")
	var ok = true

	var lp = LegalPanel.new()
	root.add_child(lp)
	await create_timer(0.6).timeout
	ok = ok and lp.content_area != null and lp.content_area.get_child_count() > 0
	print("LegalPanel aufgebaut: ", lp.content_area != null and lp.content_area.get_child_count() > 0, " (", lp.content_area.get_child_count() if lp.content_area else 0, " Sektionen)")
	lp.show_panel()
	lp.queue_free()

	var op = OfficeUpgradePanel.new()
	root.add_child(op)
	await create_timer(0.6).timeout
	ok = ok and op.content_area != null and op.content_area.get_child_count() > 0
	print("OfficeUpgradePanel aufgebaut: ", op.content_area != null and op.content_area.get_child_count() > 0, " (", op.content_area.get_child_count() if op.content_area else 0, " Sektionen)")
	op.show_panel()
	op.queue_free()

	print("PANEL-TEST: ", "OK" if ok else "FEHLGESCHLAGEN")
	quit(0 if ok else 1)

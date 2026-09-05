extends Control
# OfficeUpgradePanel.gd - UI-Panel für das Büro-Upgrade-System
# Haupt-Upgrade + Module pro Ära; alle Module schalten den Ära-Wechsel frei

# --- UI REFERENZEN ---
var panel: Panel
var main_vbox: VBoxContainer
var scroll_container: ScrollContainer
var content_area: VBoxContainer

var game_manager = null
var upgrade_manager = null

# --- FARBEN ---
const COLOR_HEADER = Color(0.3, 0.9, 0.4)
const COLOR_SECTION = Color(0.5, 0.8, 1.0)
const COLOR_DANGER = Color(1.0, 0.4, 0.3)
const COLOR_OK = Color(0.3, 0.9, 0.4)
const COLOR_DIM = Color(0.7, 0.7, 0.7)
const COLOR_WARN = Color(1.0, 0.6, 0.2)

# Lesbare Namen fuer Effekt-Schluessel
const EFFECT_NAMES = {
	"employee_efficiency": "Mitarbeiter-Effizienz",
	"data_access_speed": "Datenzugriff",
	"save_slots": "Save-Slots",
	"report_accuracy": "Berichtsgenauigkeit",
	"admin_cost_reduction": "Verwaltungskosten",
	"market_info_speed": "Marktinfo-Tempo",
	"news_speed": "Nachrichten-Tempo",
	"oilnn_access": "OilNN-Empfang",
	"price_update_speed": "Preis-Updates",
	"market_advantage": "Marktvorteil",
	"contract_negotiation_bonus": "Verhandlungsbonus",
	"research_speed": "Forschungstempo",
	"historical_accuracy": "Historien-Genauigkeit",
	"reputation": "Reputation",
	"customer_reach": "Kundenreichweite",
	"sales_bonus": "Verkaufsbonus",
	"new_markets": "Neue Maerkte",
	"data_security": "Datensicherheit",
	"disaster_recovery": "Katastrophenschutz",
	"flexibility": "Flexibilitaet",
	"response_time": "Reaktionszeit",
	"price_prediction": "Preisvorhersage",
	"risk_assessment": "Risikoabschaetzung",
	"production_efficiency": "Fördereffizienz",
	"cost_reduction": "Kostenreduktion",
	"survey_accuracy": "Vermessungsgenauigkeit",
	"discovery_chance": "Fundchance",
	"global_synergy": "Globale Synergie",
	"crisis_response": "Krisenreaktion",
}

func _ready():
	await get_tree().create_timer(0.3).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		if game_manager.office_upgrade_manager:
			upgrade_manager = game_manager.office_upgrade_manager
	
	_build_ui()
	_refresh()

func show_panel():
	visible = true
	_refresh()

func hide_panel():
	visible = false

func _build_ui():
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(950, 700)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	
	main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(main_vbox)
	
	# Header
	var header = HBoxContainer.new()
	main_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "BÜRO-UPGRADES"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", COLOR_HEADER)
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	var btn_close = Button.new()
	btn_close.text = "X"
	btn_close.custom_minimum_size = Vector2(45, 45)
	btn_close.pressed.connect(func(): queue_free())
	header.add_child(btn_close)
	
	# Scrollbarer Inhalt
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll_container)
	
	content_area = VBoxContainer.new()
	content_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_area.add_theme_constant_override("separation", 12)
	scroll_container.add_child(content_area)

func _refresh():
	if content_area == null:
		return
	
	for child in content_area.get_children():
		child.queue_free()
	
	if upgrade_manager == null or game_manager == null:
		var err = Label.new()
		err.text = "Upgrade-System nicht verfügbar."
		err.add_theme_color_override("font_color", COLOR_DANGER)
		content_area.add_child(err)
		return
	
	_build_cash_line()
	_build_main_upgrade_section()
	_build_modules_section()
	_build_era_section()

func _money(value: float) -> String:
	var s = str(int(round(value)))
	var out = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return "$" + out

func _effects_text(effects: Dictionary) -> String:
	var parts = []
	for key in effects.keys():
		var eff_name = EFFECT_NAMES.get(key, key)
		var value = effects[key]
		if value is bool:
			parts.append(eff_name)
		else:
			parts.append(eff_name + ": " + str(value))
	return ", ".join(parts)

func _add_section_title(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", COLOR_SECTION)
	content_area.add_child(lbl)
	return lbl

func _build_cash_line():
	var cash_lbl = Label.new()
	cash_lbl.text = "Kasse: " + _money(game_manager.cash)
	cash_lbl.add_theme_font_size_override("font_size", 18)
	cash_lbl.add_theme_color_override("font_color", COLOR_OK)
	content_area.add_child(cash_lbl)

# --- HAUPT-UPGRADE ---
func _build_main_upgrade_section():
	var era = game_manager.current_era
	if not upgrade_manager.MAIN_UPGRADES.has(era):
		var done = Label.new()
		done.text = "Alle Haupt-Upgrades abgeschlossen!"
		done.add_theme_color_override("font_color", COLOR_OK)
		content_area.add_child(done)
		return
	
	var upgrade = upgrade_manager.MAIN_UPGRADES[era]
	var already_owned = upgrade_manager.purchased_main_upgrades.get(era, false)
	
	_add_section_title("HAUPT-UPGRADE (schaltet die Module dieser Ära frei)")
	
	var box = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.15, 0.1)
	style.border_color = Color(0.2, 0.5, 0.2)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	box.add_theme_stylebox_override("panel", style)
	content_area.add_child(box)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	box.add_child(vbox)
	
	var name_lbl = Label.new()
	name_lbl.text = upgrade["name"]
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", COLOR_OK if already_owned else Color.WHITE)
	vbox.add_child(name_lbl)
	
	var desc = Label.new()
	desc.text = upgrade["description"]
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", COLOR_DIM)
	vbox.add_child(desc)
	
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)
	
	var status = Label.new()
	if already_owned:
		status.text = "INSTALLIERT"
		status.add_theme_color_override("font_color", COLOR_OK)
	else:
		var year_ok = game_manager.date["year"] >= upgrade["required_year"]
		status.text = "Kosten: " + _money(upgrade["cost"]) + "  |  ab Jahr " + str(upgrade["required_year"]) + ("" if year_ok else "  (noch nicht verfügbar)")
		status.add_theme_color_override("font_color", COLOR_DIM if year_ok else COLOR_WARN)
		status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(status)
	
	if not already_owned:
		var btn_buy = Button.new()
		btn_buy.text = "KAUFEN"
		btn_buy.disabled = not upgrade_manager.can_purchase_main_upgrade()["can_purchase"]
		btn_buy.pressed.connect(func(): _on_buy_main_upgrade())
		row.add_child(btn_buy)

func _on_buy_main_upgrade():
	if upgrade_manager.purchase_main_upgrade():
		if game_manager.sound_manager:
			game_manager.sound_manager.play_sound("contract_sign")
		_refresh()
	else:
		var check = upgrade_manager.can_purchase_main_upgrade()
		if has_node("/root/FeedbackOverlay"):
			get_node("/root/FeedbackOverlay").show_msg(check.get("reason", "Kauf nicht möglich"), COLOR_DANGER)

# --- MODULE ---
func _build_modules_section():
	var era = game_manager.current_era
	var main_owned = upgrade_manager.purchased_main_upgrades.get(era, false)
	var progress = upgrade_manager.get_module_progress()
	
	_add_section_title("MODULE — %d/%d installiert (alle erforderlich für den Ära-Wechsel)" % [progress.get("purchased", 0), progress.get("total", 0)])
	
	if not main_owned:
		var hint = Label.new()
		hint.text = "Zuerst das Haupt-Upgrade kaufen, um Module freizuschalten."
		hint.add_theme_color_override("font_color", COLOR_WARN)
		content_area.add_child(hint)
		return
	
	var modules = upgrade_manager.get_available_modules()
	if modules.is_empty():
		var done = Label.new()
		done.text = "Alle Module dieser Ära installiert!"
		done.add_theme_color_override("font_color", COLOR_OK)
		content_area.add_child(done)
		return
	
	for module_id in modules:
		var module = upgrade_manager.UPGRADE_MODULES[module_id]
		var owned = upgrade_manager.purchased_modules.get(module_id, false)
		
		var box = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.12, 0.16)
		style.border_color = Color(0.25, 0.3, 0.4)
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		box.add_theme_stylebox_override("panel", style)
		content_area.add_child(box)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		box.add_child(vbox)
		
		var head = HBoxContainer.new()
		head.add_theme_constant_override("separation", 10)
		vbox.add_child(head)
		
		var name_lbl = Label.new()
		name_lbl.text = module["name"]
		name_lbl.add_theme_font_size_override("font_size", 17)
		name_lbl.add_theme_color_override("font_color", COLOR_OK if owned else Color.WHITE)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(name_lbl)
		
		if owned:
			var owned_lbl = Label.new()
			owned_lbl.text = "INSTALLIERT"
			owned_lbl.add_theme_color_override("font_color", COLOR_OK)
			head.add_child(owned_lbl)
		else:
			var btn_buy = Button.new()
			btn_buy.text = "KAUFEN (" + _money(module["cost"]) + ")"
			btn_buy.disabled = not upgrade_manager.can_purchase_module(module_id)["can_purchase"]
			var buy_id: String = module_id
			btn_buy.pressed.connect(func(): _on_buy_module(buy_id))
			head.add_child(btn_buy)
		
		var desc = Label.new()
		desc.text = module["description"]
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_color_override("font_color", COLOR_DIM)
		vbox.add_child(desc)
		
		var effects_lbl = Label.new()
		effects_lbl.text = "Effekt: " + _effects_text(module.get("effect", {}))
		effects_lbl.add_theme_font_size_override("font_size", 13)
		effects_lbl.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
		vbox.add_child(effects_lbl)

func _on_buy_module(module_id: String):
	if upgrade_manager.purchase_module(module_id):
		if game_manager.sound_manager:
			game_manager.sound_manager.play_sound("contract_sign")
		_refresh()
	else:
		var check = upgrade_manager.can_purchase_module(module_id)
		if has_node("/root/FeedbackOverlay"):
			get_node("/root/FeedbackOverlay").show_msg(check.get("reason", "Kauf nicht möglich"), COLOR_DANGER)

# --- ÄRA-WECHSEL ---
func _build_era_section():
	if game_manager.era_manager == null:
		return
	
	var upgrade_check = game_manager.era_manager.can_upgrade_era()
	
	_add_section_title("ÄRA-WECHSEL")
	
	var box = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.16)
	style.border_color = Color(0.4, 0.3, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	box.add_theme_stylebox_override("panel", style)
	content_area.add_child(box)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	box.add_child(vbox)
	
	var next_era = game_manager.current_era + 1
	var status = Label.new()
	if game_manager.era_manager.ERA_DATA.has(next_era):
		var next_name = game_manager.era_manager.ERA_DATA[next_era]["name"]
		status.text = "Nächste Ära: " + next_name + " (ab Jahr " + str(game_manager.era_manager.ERA_DATA[next_era]["year_start"]) + ")"
	else:
		status.text = "Maximale Ära erreicht."
	status.add_theme_color_override("font_color", COLOR_DIM)
	vbox.add_child(status)
	
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)
	
	var state = Label.new()
	state.text = ("BEREIT!" if upgrade_check["can_upgrade"] else upgrade_check.get("reason", "Nicht bereit"))
	state.add_theme_color_override("font_color", COLOR_OK if upgrade_check["can_upgrade"] else COLOR_WARN)
	state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(state)
	
	var btn_advance = Button.new()
	btn_advance.text = "ÄRA WECHSELN"
	btn_advance.custom_minimum_size = Vector2(180, 40)
	btn_advance.disabled = not upgrade_check["can_upgrade"]
	btn_advance.pressed.connect(func(): _on_advance_era())
	row.add_child(btn_advance)

func _on_advance_era():
	if game_manager.era_manager and game_manager.era_manager.perform_era_upgrade():
		if has_node("/root/FeedbackOverlay"):
			var era_name = game_manager.era_manager.get_era_name()
			get_node("/root/FeedbackOverlay").show_msg("ÄRA UPGRADE!\n" + era_name, COLOR_OK)
		if game_manager.sound_manager:
			game_manager.sound_manager.play_sound("era_upgrade")
		_refresh()
	else:
		if has_node("/root/FeedbackOverlay"):
			get_node("/root/FeedbackOverlay").show_msg("Ära-Wechsel noch nicht möglich.", COLOR_DANGER)

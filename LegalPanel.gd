extends Control
# LegalPanel.gd - UI-Panel für das Rechtssystem
# Aktive Verfahren, Bestechung, Anwälte, Compliance-Investitionen und Fallhistorie

# --- UI REFERENZEN ---
var panel: Panel
var main_vbox: VBoxContainer
var scroll_container: ScrollContainer
var content_area: VBoxContainer
var lawyer_label: Label
var lawyer_buttons: HBoxContainer
var cases_container: VBoxContainer
var compliance_container: VBoxContainer
var history_container: VBoxContainer

var game_manager = null
var legal_manager = null

# --- FARBEN ---
const COLOR_HEADER = Color(0.95, 0.78, 0.2)
const COLOR_SECTION = Color(0.5, 0.8, 1.0)
const COLOR_DANGER = Color(1.0, 0.4, 0.3)
const COLOR_OK = Color(0.3, 0.9, 0.4)
const COLOR_DIM = Color(0.7, 0.7, 0.7)

const LAWYER_OPTIONS = [
	{"id": "cheap", "name": "Billig", "cost": 100000, "quality": 0.3},
	{"id": "standard", "name": "Standard", "cost": 500000, "quality": 0.6},
	{"id": "premium", "name": "Premium", "cost": 2000000, "quality": 0.85},
	{"id": "elite", "name": "Elite", "cost": 10000000, "quality": 0.95},
]

func _ready():
	await get_tree().create_timer(0.3).timeout
	if has_node("/root/GameManager"):
		game_manager = get_node("/root/GameManager")
		if game_manager.legal_manager:
			legal_manager = game_manager.legal_manager
	
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
	title.text = "RECHT & ANWÄLTE"
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
	
	if legal_manager == null:
		var err = Label.new()
		err.text = "Rechtssystem nicht verfügbar."
		err.add_theme_color_override("font_color", COLOR_DANGER)
		content_area.add_child(err)
		return
	
	_build_cash_line()
	_build_lawyer_section()
	_build_cases_section()
	_build_compliance_section()
	_build_history_section()

func _money(value: float) -> String:
	# Gruppierung in Tausendern ohne Regex
	var s = str(int(round(value)))
	var out = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return "$" + out

func _add_section_title(text: String) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", COLOR_SECTION)
	content_area.add_child(lbl)
	return lbl

# --- KASSE ---
func _build_cash_line():
	var cash_lbl = Label.new()
	cash_lbl.text = "Kasse: " + _money(game_manager.cash)
	cash_lbl.add_theme_font_size_override("font_size", 18)
	cash_lbl.add_theme_color_override("font_color", COLOR_OK)
	content_area.add_child(cash_lbl)

# --- ANWÄLTE ---
func _build_lawyer_section():
	_add_section_title("ANWALT (reduziert Schuldspruch-Wahrscheinlichkeit und Strafen)")
	
	lawyer_label = Label.new()
	var quality_pct = int(round(legal_manager.get_lawyer_quality() * 100))
	lawyer_label.text = "Aktuelle Anwaltsqualität: %d%%" % quality_pct
	lawyer_label.add_theme_color_override("font_color", COLOR_DIM)
	content_area.add_child(lawyer_label)
	
	lawyer_buttons = HBoxContainer.new()
	lawyer_buttons.add_theme_constant_override("separation", 10)
	content_area.add_child(lawyer_buttons)
	
	for option in LAWYER_OPTIONS:
		var btn = Button.new()
		btn.text = option["name"] + "\n" + _money(option["cost"])
		btn.custom_minimum_size = Vector2(170, 55)
		btn.disabled = game_manager.cash < option["cost"]
		var quality_id: String = option["id"]
		btn.pressed.connect(func(): _on_hire_lawyer(quality_id))
		lawyer_buttons.add_child(btn)

func _on_hire_lawyer(quality_id: String):
	if legal_manager.hire_lawyer(quality_id):
		if has_node("/root/FeedbackOverlay"):
			get_node("/root/FeedbackOverlay").show_msg("Anwalt eingestellt!", COLOR_OK)
		if game_manager.sound_manager:
			game_manager.sound_manager.play_sound("contract_sign")
		_refresh()
	else:
		if has_node("/root/FeedbackOverlay"):
			get_node("/root/FeedbackOverlay").show_msg("Nicht genug Geld!", COLOR_DANGER)

# --- AKTIVE FÄLLE ---
func _build_cases_section():
	_add_section_title("AKTIVE VERFAHREN (" + str(legal_manager.get_active_cases().size()) + ")")
	
	cases_container = VBoxContainer.new()
	cases_container.add_theme_constant_override("separation", 8)
	content_area.add_child(cases_container)
	
	var active_cases = legal_manager.get_active_cases()
	if active_cases.is_empty():
		var none = Label.new()
		none.text = "Keine offenen Verfahren."
		none.add_theme_color_override("font_color", COLOR_DIM)
		cases_container.add_child(none)
		return
	
	for case_id in active_cases.keys():
		var case_data = active_cases[case_id]
		var case_box = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.12, 0.1)
		style.border_color = Color(0.5, 0.3, 0.1)
		style.set_border_width_all(1)
		style.set_corner_radius_all(4)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		case_box.add_theme_stylebox_override("panel", style)
		cases_container.add_child(case_box)
		
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 4)
		case_box.add_child(vbox)
		
		var head = Label.new()
		head.text = "%s — %s" % [case_data.get("region", "?"), case_data.get("offense", "?")]
		head.add_theme_font_size_override("font_size", 18)
		head.add_theme_color_override("font_color", COLOR_DANGER)
		vbox.add_child(head)
		
		var bribe_cost = case_data.get("base_penalty", 0.0) * 0.3
		var details = Label.new()
		details.text = "Beamter: %s | Strafe bis %s | Verfahrensdauer: %d/6 Monate | Korruption: %d%% | Mob-Risiko: %d%%" % [
			case_data.get("official", "?"),
			_money(case_data.get("base_penalty", 0.0)),
			int(case_data.get("months", 0)),
			int(round(case_data.get("corruption_level", 0.0) * 100)),
			int(round(case_data.get("mob_risk", 0.0) * 100)),
		]
		details.add_theme_color_override("font_color", COLOR_DIM)
		vbox.add_child(details)
		
		var action_row = HBoxContainer.new()
		action_row.add_theme_constant_override("separation", 10)
		vbox.add_child(action_row)
		
		var btn_bribe = Button.new()
		btn_bribe.text = "Bestechen (" + _money(bribe_cost) + ")"
		btn_bribe.tooltip_text = "Korrupte Beamte nehmen an, sonst Strafe + Mob-Risiko!"
		btn_bribe.disabled = game_manager.cash < bribe_cost
		var bribe_id: String = case_id
		btn_bribe.pressed.connect(func(): _on_bribe_pressed(bribe_id))
		action_row.add_child(btn_bribe)
		
		var warn = Label.new()
		warn.text = "Bei Aufdeckung: Zusatzstrafe 50% und verdoppelter Mob-Risiko!"
		warn.add_theme_font_size_override("font_size", 13)
		warn.add_theme_color_override("font_color", Color(1.0, 0.6, 0.3))
		action_row.add_child(warn)

func _on_bribe_pressed(case_id: String):
	var result = legal_manager.attempt_bribe(case_id)
	if has_node("/root/FeedbackOverlay"):
		if result.get("success", false):
			get_node("/root/FeedbackOverlay").show_msg("BESTECHUNG ERFOLGREICH\nFall eingestellt. Aber Achtung: Mob-Risiko gestiegen!", Color(1.0, 0.8, 0.2))
		else:
			var reason = result.get("reason", "")
			if reason != "":
				get_node("/root/FeedbackOverlay").show_msg("BESTECHUNG FEHLGESCHLAGEN\n" + reason, COLOR_DANGER)
			else:
				get_node("/root/FeedbackOverlay").show_msg("BESTECHUNG AUFGEOLEGT!\nZusatzstrafe: " + _money(result.get("penalty", 0.0)), COLOR_DANGER)
	_refresh()

# --- COMPLIANCE ---
func _build_compliance_section():
	_add_section_title("COMPLIANCE (senkt Inspektions- und Verfahrensrisiken)")
	
	compliance_container = VBoxContainer.new()
	compliance_container.add_theme_constant_override("separation", 6)
	content_area.add_child(compliance_container)
	
	var has_regions = false
	for region in game_manager.regions:
		if not game_manager.regions[region].get("unlocked", false):
			continue
		has_regions = true
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		compliance_container.add_child(row)
		
		var compliance = legal_manager.get_compliance(region)
		var lbl = Label.new()
		lbl.text = region + ": " + str(int(round(compliance * 100))) + "%"
		lbl.custom_minimum_size = Vector2(220, 0)
		lbl.add_theme_color_override("font_color", COLOR_OK if compliance >= 0.5 else COLOR_DIM)
		row.add_child(lbl)
		
		var btn = Button.new()
		btn.text = "+Investieren ($1.000.000)"
		btn.disabled = game_manager.cash < 1000000
		var region_name: String = region
		btn.pressed.connect(func(): _on_invest_compliance(region_name))
		row.add_child(btn)
	
	if not has_regions:
		var none = Label.new()
		none.text = "Noch keine Regionen erschlossen."
		none.add_theme_color_override("font_color", COLOR_DIM)
		compliance_container.add_child(none)

func _on_invest_compliance(region: String):
	if legal_manager.invest_compliance(region, 1000000):
		if has_node("/root/FeedbackOverlay"):
			get_node("/root/FeedbackOverlay").show_msg("Compliance in " + region + " erhöht!", COLOR_OK)
		if game_manager.sound_manager:
			game_manager.sound_manager.play_sound("money_loss")
		_refresh()

# --- FALLHISTORIE ---
func _build_history_section():
	_add_section_title("FALLHISTORIE")
	
	history_container = VBoxContainer.new()
	history_container.add_theme_constant_override("separation", 4)
	content_area.add_child(history_container)
	
	var history = legal_manager.get_case_history()
	if history.is_empty():
		var none = Label.new()
		none.text = "Keine abgeschlossenen Fälle."
		none.add_theme_color_override("font_color", COLOR_DIM)
		history_container.add_child(none)
		return
	
	var start = max(0, history.size() - 8)
	for i in range(start, history.size()):
		var entry = history[i]
		var lbl = Label.new()
		var guilty = entry.get("status", "") == "closed_guilty" or entry.get("guilty", false)
		var verdict_text = "SCHULDIG" if guilty else "FREISPRUCH"
		lbl.text = "[%s] %s — %s — %s" % [
			entry.get("region", "?"),
			entry.get("offense", "?"),
			verdict_text,
			_money(entry.get("penalty", entry.get("base_penalty", 0.0))),
		]
		lbl.add_theme_color_override("font_color", COLOR_DANGER if guilty else COLOR_OK)
		history_container.add_child(lbl)

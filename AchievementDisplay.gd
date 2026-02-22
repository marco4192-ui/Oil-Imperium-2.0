extends Control
# AchievementDisplay.gd - UI panel to display player achievements

# --- UI REFERENCES ---
var panel: Panel
var main_vbox: VBoxContainer
var scroll_container: ScrollContainer
var achievements_grid: GridContainer

# Category buttons
var category_buttons: HBoxContainer

# Data
var current_category: String = "all"
var achievement_manager = null

# Colors
const COLOR_UNLOCKED = Color(1.0, 0.85, 0.2)  # Gold
const COLOR_LOCKED = Color(0.4, 0.4, 0.4)      # Gray
const COLOR_HIDDEN = Color(0.2, 0.2, 0.2)      # Dark gray

func _ready():
	await get_tree().create_timer(0.3).timeout
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if gm.achievement_manager:
			achievement_manager = gm.achievement_manager
	
	_build_ui()
	_populate_achievements()

func _build_ui():
	# Main panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(900, 650)
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
	main_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(main_vbox)
	
	# Header
	_build_header()
	
	# Progress bar
	_build_progress_section()
	
	# Category filters
	_build_category_buttons()
	
	# Achievements grid
	_build_achievements_grid()

func _build_header():
	var header = HBoxContainer.new()
	main_vbox.add_child(header)
	
	var title = Label.new()
	title.text = "ERFOLGE"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", COLOR_UNLOCKED)
	header.add_child(title)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	
	# Close button
	var btn_close = Button.new()
	btn_close.text = "X"
	btn_close.custom_minimum_size = Vector2(45, 45)
	btn_close.pressed.connect(func(): queue_free())
	header.add_child(btn_close)

func _build_progress_section():
	var progress_section = VBoxContainer.new()
	progress_section.add_theme_constant_override("separation", 5)
	main_vbox.add_child(progress_section)
	
	# Progress text
	if achievement_manager:
		var unlocked = achievement_manager.get_unlocked_count()
		var total = achievement_manager.get_total_count()
		var progress_label = Label.new()
		progress_label.text = "Fortschritt: %d / %d Erfolge freigeschaltet (%.1f%%)" % [unlocked, total, (float(unlocked)/total)*100]
		progress_label.add_theme_font_size_override("font_size", 18)
		progress_section.add_child(progress_label)
		
		# Progress bar
		var progress_bar = ProgressBar.new()
		progress_bar.min_value = 0
		progress_bar.max_value = total
		progress_bar.value = unlocked
		progress_bar.custom_minimum_size = Vector2(0, 25)
		progress_bar.show_percentage = false
		progress_section.add_child(progress_bar)

func _build_category_buttons():
	category_buttons = HBoxContainer.new()
	category_buttons.add_theme_constant_override("separation", 8)
	main_vbox.add_child(category_buttons)
	
	# Add category buttons
	_add_category_button("Alle", "all")
	_add_category_button("Produktion", "production")
	_add_category_button("Finanzen", "finance")
	_add_category_button("Expansion", "expansion")
	_add_category_button("Technologie", "technology")
	_add_category_button("Geschäft", "business")
	_add_category_button("Risiko", "risk")
	_add_category_button("Zeit", "time")
	_add_category_button("Spezial", "special")

func _add_category_button(text: String, category: String):
	var btn = Button.new()
	btn.text = text
	btn.toggle_mode = true
	btn.button_group = _get_or_create_button_group()
	btn.pressed.connect(func(): _on_category_selected(category))
	if category == "all":
		btn.button_pressed = true
	category_buttons.add_child(btn)

var _button_group: ButtonGroup = null
func _get_or_create_button_group() -> ButtonGroup:
	if _button_group == null:
		_button_group = ButtonGroup.new()
	return _button_group

func _build_achievements_grid():
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll_container)
	
	achievements_grid = GridContainer.new()
	achievements_grid.columns = 3
	achievements_grid.add_theme_constant_override("h_separation", 15)
	achievements_grid.add_theme_constant_override("v_separation", 15)
	scroll_container.add_child(achievements_grid)

func _populate_achievements():
	if achievement_manager == null:
		return
	
	# Clear existing
	for child in achievements_grid.get_children():
		child.queue_free()
	
	# Get achievements
	var categories_to_show = []
	if current_category == "all":
		categories_to_show = achievement_manager.get_all_categories()
	else:
		categories_to_show = [current_category]
	
	for category in categories_to_show:
		var achievements = achievement_manager.get_achievements_by_category(category)
		for ach_data in achievements:
			var card = _create_achievement_card(ach_data)
			achievements_grid.add_child(card)

func _create_achievement_card(ach_data: Dictionary) -> PanelContainer:
	var ach_id = ach_data["id"]
	var unlocked = ach_data["unlocked"]
	var data = ach_data["data"]
	var hidden = data.get("hidden", false)
	
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(260, 120)
	
	# Styling
	var style = StyleBoxFlat.new()
	if unlocked:
		style.bg_color = Color(0.15, 0.12, 0.05)
		style.border_color = COLOR_UNLOCKED
	else:
		style.bg_color = Color(0.08, 0.08, 0.08)
		style.border_color = COLOR_LOCKED
	style.border_width_all = 2
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	card.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	card.add_child(vbox)
	
	# Title
	var title = Label.new()
	if hidden and not unlocked:
		title.text = "???"
	else:
		title.text = data.get("title", "Unbekannt")
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", COLOR_UNLOCKED if unlocked else COLOR_LOCKED)
	vbox.add_child(title)
	
	# Description
	var desc = Label.new()
	if hidden and not unlocked:
		desc.text = "Versteckter Erfolg"
	else:
		desc.text = data.get("description", "")
	desc.add_theme_font_size_override("font_size", 13)
	desc.add_theme_color_override("font_color", Color.WHITE if unlocked else Color.GRAY)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)
	
	# Status
	var status = Label.new()
	if unlocked:
		status.text = "✓ FREIGESCHALTET"
		status.add_theme_color_override("font_color", Color.GREEN)
	else:
		# Check for progress
		var progress = achievement_manager.get_progress(ach_id)
		if progress["target"] > 0:
			status.text = "Fortschritt: %.0f / %.0f" % [progress["current"], progress["target"]]
			status.add_theme_color_override("font_color", Color.ORANGE)
		else:
			status.text = "Nicht freigeschaltet"
			status.add_theme_color_override("font_color", Color.GRAY)
	status.add_theme_font_size_override("font_size", 12)
	vbox.add_child(status)
	
	return card

func _on_category_selected(category: String):
	current_category = category
	_populate_achievements()

# --- PUBLIC INTERFACE ---
func show_achievements():
	visible = true
	_populate_achievements()

func hide_achievements():
	visible = false

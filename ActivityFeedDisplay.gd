extends Control
# ActivityFeedDisplay.gd - UI panel to display AI competitor activities and game events

# --- UI REFERENCES ---
var panel: Panel
var main_vbox: VBoxContainer
var scroll_container: ScrollContainer
var activity_list: VBoxContainer

# Filter buttons
var filter_buttons: HBoxContainer

# Data
var current_filter: int = -1  # -1 = all
var activity_feed = null
var game_manager = null

# Colors by activity type
const TYPE_COLORS = {
        0: Color(0.9, 0.3, 0.3),   # AI_PURCHASE - Red
        1: Color(0.8, 0.2, 0.6),   # AI_SABOTAGE - Magenta
        2: Color(0.9, 0.6, 0.2),   # AI_LICENSE - Orange
        3: Color(0.3, 0.8, 0.3),   # AI_EXPANSION - Green
        4: Color(1.0, 0.85, 0.2),  # PLAYER_ACHIEVEMENT - Gold
        5: Color(0.9, 0.9, 0.3),   # RANDOM_EVENT - Yellow
        6: Color(0.3, 0.6, 0.9),   # HISTORICAL_EVENT - Blue
        7: Color(0.2, 0.9, 0.4),   # FINANCIAL_MILESTONE - Bright green
        8: Color(0.6, 0.4, 0.9),   # REGION_UNLOCK - Purple
}

func _ready():
        await get_tree().create_timer(0.3).timeout
        if has_node("/root/GameManager"):
                game_manager = get_node("/root/GameManager")
                if game_manager.activity_feed:
                        activity_feed = game_manager.activity_feed
                        activity_feed.new_activity.connect(_on_new_activity)
        
        _build_ui()
        _populate_activities()

func _build_ui():
        # Main panel
        panel = Panel.new()
        panel.custom_minimum_size = Vector2(500, 600)
        panel.set_anchors_preset(Control.PRESET_FULL_RECT)
        add_child(panel)
        
        var margin = MarginContainer.new()
        margin.set_anchors_preset(Control.PRESET_FULL_RECT)
        margin.add_theme_constant_override("margin_left", 20)
        margin.add_theme_constant_override("margin_right", 20)
        margin.add_theme_constant_override("margin_top", 15)
        margin.add_theme_constant_override("margin_bottom", 15)
        panel.add_child(margin)
        
        main_vbox = VBoxContainer.new()
        main_vbox.add_theme_constant_override("separation", 12)
        margin.add_child(main_vbox)
        
        # Header
        _build_header()
        
        # Filter buttons
        _build_filter_buttons()
        
        # Activity list
        _build_activity_list()

func _build_header():
        var header = HBoxContainer.new()
        main_vbox.add_child(header)
        
        var title = Label.new()
        title.text = "AKTIVITÄTS-LOG"
        title.add_theme_font_size_override("font_size", 26)
        title.add_theme_color_override("font_color", Color(0.2, 0.9, 0.9))
        header.add_child(title)
        
        var spacer = Control.new()
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        header.add_child(spacer)
        
        # Refresh button
        var btn_refresh = Button.new()
        btn_refresh.text = "↻"
        btn_refresh.custom_minimum_size = Vector2(40, 40)
        btn_refresh.pressed.connect(_populate_activities)
        header.add_child(btn_refresh)
        
        # Close button
        var btn_close = Button.new()
        btn_close.text = "X"
        btn_close.custom_minimum_size = Vector2(40, 40)
        btn_close.pressed.connect(func(): queue_free())
        header.add_child(btn_close)

func _build_filter_buttons():
        filter_buttons = HBoxContainer.new()
        filter_buttons.add_theme_constant_override("separation", 6)
        main_vbox.add_child(filter_buttons)
        
        _add_filter_button("Alle", -1)
        _add_filter_button("KI", 0)
        _add_filter_button("Ereignisse", 5)
        _add_filter_button("Erfolge", 4)

func _add_filter_button(text: String, filter: int):
        var btn = Button.new()
        btn.text = text
        btn.toggle_mode = true
        btn.button_group = _get_or_create_button_group()
        btn.pressed.connect(func(): _on_filter_selected(filter))
        if filter == -1:
                btn.button_pressed = true
        filter_buttons.add_child(btn)

var _button_group: ButtonGroup = null
func _get_or_create_button_group() -> ButtonGroup:
        if _button_group == null:
                _button_group = ButtonGroup.new()
        return _button_group

func _build_activity_list():
        scroll_container = ScrollContainer.new()
        scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
        main_vbox.add_child(scroll_container)
        
        activity_list = VBoxContainer.new()
        activity_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        activity_list.add_theme_constant_override("separation", 4)
        scroll_container.add_child(activity_list)

func _populate_activities():
        if activity_feed == null:
                return
        
        # Clear existing
        for child in activity_list.get_children():
                child.queue_free()
        
        # Get activities
        var activities = activity_feed.get_recent_activities(50)
        
        for activity in activities:
                if current_filter != -1 and activity["type"] != current_filter:
                        continue
                
                var entry = _create_activity_entry(activity)
                activity_list.add_child(entry)
        
        # Show empty state if no activities
        if activity_list.get_child_count() == 0:
                var empty_label = Label.new()
                empty_label.text = "Keine Aktivitäten vorhanden"
                empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                empty_label.add_theme_font_size_override("font_size", 18)
                empty_label.modulate = Color.GRAY
                activity_list.add_child(empty_label)

func _create_activity_entry(activity: Dictionary) -> PanelContainer:
        var entry = PanelContainer.new()
        entry.custom_minimum_size = Vector2(0, 60)
        
        # Styling
        var style = StyleBoxFlat.new()
        var type_color = TYPE_COLORS.get(activity["type"], Color.GRAY)
        style.bg_color = Color(type_color.r * 0.15, type_color.g * 0.15, type_color.b * 0.15)
        style.border_color = type_color
        style.border_width_left = 4
        style.border_width_top = 1
        style.border_width_right = 1
        style.border_width_bottom = 1
        style.corner_radius_top_left = 4
        style.corner_radius_top_right = 4
        style.corner_radius_bottom_right = 4
        style.corner_radius_bottom_left = 4
        entry.add_theme_stylebox_override("panel", style)
        
        var hbox = HBoxContainer.new()
        entry.add_child(hbox)
        
        # Timestamp
        var time_label = Label.new()
        time_label.text = "[%s]" % activity["timestamp"]
        time_label.custom_minimum_size.x = 100
        time_label.add_theme_font_size_override("font_size", 12)
        time_label.add_theme_color_override("font_color", Color.GRAY)
        hbox.add_child(time_label)
        
        # Icon based on type
        var icon_label = Label.new()
        icon_label.text = _get_type_icon(activity["type"])
        icon_label.add_theme_font_size_override("font_size", 18)
        icon_label.add_theme_color_override("font_color", type_color)
        hbox.add_child(icon_label)
        
        # Message
        var msg_label = Label.new()
        msg_label.text = _format_activity_message(activity)
        msg_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        msg_label.add_theme_font_size_override("font_size", 14)
        msg_label.add_theme_color_override("font_color", Color.WHITE)
        hbox.add_child(msg_label)
        
        return entry

func _get_type_icon(type: int) -> String:
        match type:
                0: return "[$]"  # AI_PURCHASE
                1: return "[!]"  # AI_SABOTAGE
                2: return "[L]"  # AI_LICENSE
                3: return "[+]"  # AI_EXPANSION
                4: return "[*]"  # PLAYER_ACHIEVEMENT
                5: return "[?]"  # RANDOM_EVENT
                6: return "[N]"  # HISTORICAL_EVENT
                7: return "[M]"  # FINANCIAL_MILESTONE
                8: return "[R]"  # REGION_UNLOCK
                _: return "•"

func _format_activity_message(activity: Dictionary) -> String:
        var data = activity["data"]
        var type = activity["type"]
        
        match type:
                0:  # AI_PURCHASE
                        return "%s kaufte Land in %s ($%s)" % [data.get("company", "???"), data.get("region", "???"), _fmt(data.get("price", 0))]
                1:  # AI_SABOTAGE
                        return "%s führte Sabotage in %s durch" % [data.get("company", "???"), data.get("region", "???")]
                2:  # AI_LICENSE
                        return "%s erwarb Lizenz für %s" % [data.get("company", "???"), data.get("region", "???")]
                3:  # AI_EXPANSION
                        return "%s expandiert nach %s" % [data.get("company", "???"), data.get("region", "???")]
                4:  # PLAYER_ACHIEVEMENT
                        return "ERFOLG: %s" % data.get("title", "???")
                5:  # RANDOM_EVENT
                        return "EREIGNIS: %s" % data.get("title", "???")
                6:  # HISTORICAL_EVENT
                        return "HISTORISCH: %s" % data.get("title", "???")
                7:  # FINANCIAL_MILESTONE
                        return "MEILENSTEIN: %s" % data.get("title", "???")
                8:  # REGION_UNLOCK
                        return "FREISCHALTUNG: %s ist nun verfügbar" % data.get("region", "???")
                _:
                        return "Unbekannte Aktivität"

func _fmt(value) -> String:
        var s = str(int(value))
        var res = ""
        var counter = 0
        for i in range(s.length() - 1, -1, -1):
                res = s[i] + res
                counter += 1
                if counter % 3 == 0 and i > 0:
                        res = "." + res
        return res

func _on_filter_selected(filter: int):
        current_filter = filter
        _populate_activities()

func _on_new_activity(activity: Dictionary):
        if current_filter == -1 or activity["type"] == current_filter:
                var entry = _create_activity_entry(activity)
                activity_list.add_child(entry)
                # Scroll to bottom
                await get_tree().process_frame
                scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)

# --- PUBLIC INTERFACE ---
func show_feed():
        visible = true
        _populate_activities()

func hide_feed():
        visible = false

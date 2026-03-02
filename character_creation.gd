extends Control

# --- UI REFERENZEN ---
@onready var logo_display = $MainContainer/SelctorsBox/LeftColumn/LogoHorizontal/LogoVertrical/LogoDisplay
@onready var company_label = $MainContainer/SelctorsBox/LeftColumn/LogoControls/CompanyNameLabel

@onready var office_display = $MainContainer/SelctorsBox/RightColumn/OfficeDisplay
@onready var office_label = $MainContainer/SelctorsBox/RightColumn/OfficeControls/OfficeNameLabel

@onready var hq_label = $MainContainer/SelctorsBox/RightColumn2/HQControls/HQNameLabel
@onready var hq_display = $MainContainer/SelctorsBox/RightColumn2/HQDisplay
@onready var name_input = $MainContainer/InputBox/NameInput

@onready var btn_load = $TopBar/BtnLoad
@onready var difficulty_option: OptionButton = null
@onready var story_mode_check: CheckBox = null

# Load Menu
var load_popup: PopupMenu

# --- DATEN ---
var logos = [] # Wird aus GameData geladen
var current_logo_idx = 0
var current_office_idx = 0
var current_hq_idx = 0
var tutorial_enabled = true  # Default to enabled for new players
var story_mode_enabled = false  # Story Mode - narrative events
var difficulty_level = 1  # 0=Easy, 1=Normal, 2=Hard, 3=Brutal

func _ready():
        # Daten aus GameData holen
        if GameManager and GameManager.GameData:
                logos = GameManager.GameData.COMPANIES

        _create_top_bar_ui()
        create_load_popup()
        update_ui()

func _create_top_bar_ui():
        # Top bar already exists in scene, add difficulty dropdown
        var top_bar = $TopBar

        # Spacer to push difficulty to the right
        var spacer = Control.new()
        spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
        top_bar.add_child(spacer)

        # Difficulty Selection
        var diff_box = HBoxContainer.new()
        diff_box.name = "DifficultyBox"
        diff_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

        var diff_label = Label.new()
        diff_label.text = "Schwierigkeit: "
        diff_label.add_theme_font_size_override("font_size", 24)
        diff_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        diff_box.add_child(diff_label)

        difficulty_option = OptionButton.new()
        difficulty_option.name = "DifficultyOption"
        difficulty_option.add_item("Einfach")  # 0
        difficulty_option.add_item("Normal")   # 1 - Default
        difficulty_option.add_item("Schwer")   # 2
        difficulty_option.add_item("Brutal")   # 3
        difficulty_option.selected = 1
        difficulty_option.item_selected.connect(_on_difficulty_selected)
        diff_box.add_child(difficulty_option)

        top_bar.add_child(diff_box)

        # Story Mode checkbox in input box
        var input_box = $MainContainer/InputBox

        # Story Mode Toggle (after name input)
        story_mode_check = CheckBox.new()
        story_mode_check.name = "StoryModeCheck"
        story_mode_check.text = "Story Mode (erweiterte Erzaehlung)"
        story_mode_check.button_pressed = false
        story_mode_check.toggled.connect(_on_story_mode_toggled)
        story_mode_check.add_theme_font_size_override("font_size", 22)
        input_box.add_child(story_mode_check)

        # Tutorial Toggle
        var tutorial_check = CheckBox.new()
        tutorial_check.name = "TutorialCheck"
        tutorial_check.text = "Tutorial aktivieren"
        tutorial_check.button_pressed = true
        tutorial_check.toggled.connect(_on_tutorial_toggled)
        tutorial_check.add_theme_font_size_override("font_size", 22)
        input_box.add_child(tutorial_check)

func _on_story_mode_toggled(enabled: bool):
        story_mode_enabled = enabled
        if enabled:
                FeedbackOverlay.show_msg("Story Mode: Narrativ-Erlebnis aktiviert!", Color.CYAN)
        else:
                FeedbackOverlay.show_msg("Klassischer Spielmodus", Color.GRAY)

func _on_difficulty_selected(index: int):
        difficulty_level = index
        var diff_names = ["Einfach", "Normal", "Schwer", "Brutal"]
        var diff_colors = [Color.GREEN, Color.WHITE, Color.ORANGE, Color.RED]
        FeedbackOverlay.show_msg("Schwierigkeit: " + diff_names[index], diff_colors[index])

func _on_tutorial_toggled(enabled: bool):
        tutorial_enabled = enabled

func create_load_popup():
        load_popup = PopupMenu.new()
        load_popup.name = "LoadMenu"
        add_child(load_popup)

        # Existierende Saves prüfen mit Vorschau
        var saves = GameManager.get_existing_saves()
        if saves.is_empty():
                load_popup.add_item("Keine Spielstaende", -1)
                load_popup.set_item_disabled(0, true)
        else:
                for s in saves:
                        # Load save preview data
                        var preview = _get_save_preview(s)
                        var label = "Slot " + s + ": " + preview
                        load_popup.add_item(label, int(s))

        load_popup.id_pressed.connect(_on_load_item_pressed)

func _get_save_preview(slot: String) -> String:
        var path = GameManager.SAVE_PATH_BASE + slot + ".save"
        if not FileAccess.file_exists(path):
                return "Leer"

        var file = FileAccess.open(path, FileAccess.READ)
        if not file:
                return "Fehler"

        var data = file.get_var()
        if typeof(data) != TYPE_DICTIONARY:
                return "Korrupt"

        # Extract preview info
        var cash = 0.0
        var year = 1970
        var month = 1
        var company = "Unknown"

        if data.has("player"):
                cash = data.player.get("cash", 0.0)
                company = data.player.get("company", "Unknown")

        if data.has("date"):
                year = data.date.get("year", 1970)
                month = data.date.get("month", 1)

        # Format cash
        var cash_str = "$" + _fmt_money(int(cash))

        # Format date
        var date_str = "%02d/%d" % [month, year]

        return "%s | %s | %s" % [company, cash_str, date_str]

func _fmt_money(value: int) -> String:
        var s = str(value)
        var res = ""
        var counter = 0
        for i in range(s.length() - 1, -1, -1):
                res = s[i] + res
                counter += 1
                if counter % 3 == 0 and i > 0:
                        res = "." + res
        return res

func _on_btn_load_pressed():
        # Popup an Position des Buttons oeffnen
        var rect = btn_load.get_global_rect()
        var vp_size = get_viewport().get_visible_rect().size

        # Estimate popup width based on content
        var estimated_width = 400
        var estimated_height = 150

        # Clamp position to stay within viewport
        var x = clamp(rect.position.x, 0, vp_size.x - estimated_width)
        var y = clamp(rect.end.y, 0, vp_size.y - estimated_height)

        load_popup.position = Vector2(x, y)
        load_popup.popup()

func _on_load_item_pressed(id):
        if id == -1: return
        GameManager.load_game(str(id))
        get_tree().change_scene_to_file("res://Office.tscn")

func update_ui():
        # 1. Logo & Company
        if logos.size() > 0:
                var company = logos[current_logo_idx]
                company_label.text = company["name"]
                # Fallback fuer Bild
                if ResourceLoader.exists(company["logo"]):
                        logo_display.texture = load(company["logo"])

        # 2. Office
        if GameManager.office_data.has(current_office_idx):
                var off = GameManager.office_data[current_office_idx]
                office_label.text = off["name"]
                if ResourceLoader.exists(off["bg_path"]):
                        office_display.texture = load(off["bg_path"])

        # 3. HQ
        if GameManager.available_hqs.size() > 0:
                var hq = GameManager.available_hqs[current_hq_idx]
                hq_label.text = hq["name"]

                # FIX: Bild korrekt laden
                var path = hq.get("skyline_path", "")
                if path != "" and ResourceLoader.exists(path):
                        hq_display.texture = load(path)
                else:
                        hq_display.texture = null # Leeren, falls kein Bild da ist

# LOGO STEUERUNG
func _on_btn_logo_left_pressed():
        if logos.is_empty(): return
        current_logo_idx = (current_logo_idx - 1 + logos.size()) % logos.size()
        update_ui()

func _on_btn_logo_right_pressed():
        if logos.is_empty(): return
        current_logo_idx = (current_logo_idx + 1) % logos.size()
        update_ui()

# BUERO STEUERUNG
func _on_btn_office_left_pressed():
        var office_count = GameManager.office_data.size()
        current_office_idx = (current_office_idx - 1 + office_count) % office_count
        update_ui()

func _on_btn_office_right_pressed():
        var office_count = GameManager.office_data.size()
        current_office_idx = (current_office_idx + 1) % office_count
        update_ui()

# HQ STEUERUNG
func _on_btn_hq_left_pressed():
        var hq_count = GameManager.available_hqs.size()
        if hq_count == 0: return
        current_hq_idx = (current_hq_idx - 1 + hq_count) % hq_count
        update_ui()

func _on_btn_hq_right_pressed():
        var hq_count = GameManager.available_hqs.size()
        if hq_count == 0: return
        current_hq_idx = (current_hq_idx + 1) % hq_count
        update_ui()

# SPIEL STARTEN
func _on_start_button_pressed():
        var entered_name = name_input.text.strip_edges()

        if entered_name == "":
                name_input.placeholder_text = "Bitte Namen eingeben!"
                return

        # Daten sammeln
        var company_name = "Unbekannt"
        var logo_path = ""

        if logos.size() > 0:
                var selected_company = logos[current_logo_idx]
                company_name = selected_company["name"]
                logo_path = selected_company["logo"]

        # Set tutorial preference
        if GameManager.tutorial_manager:
                if tutorial_enabled:
                        GameManager.tutorial_manager.enable_tutorial()
                else:
                        GameManager.tutorial_manager.disable_tutorial()

        # Set story mode and difficulty
        GameManager.story_mode_enabled = story_mode_enabled
        GameManager.difficulty_level = difficulty_level

        # Story Mode Startnachricht
        if story_mode_enabled:
                print("[STORY MODE] Aktiviert - Erweiterte Erzaehlung wird geladen...")

        # Aufruf mit ALLEN 5 Parametern
        GameManager.start_new_game(
                entered_name,
                company_name,
                logo_path,
                current_office_idx,
                current_hq_idx
        )

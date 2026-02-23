extends Control

# Referenzen
@onready var background = $Background
@onready var btn_computer = $BtnComputer
@onready var btn_map = $BtnMap
@onready var btn_calendar = $BtnCalendar
@onready var lbl_cal_day = $BtnCalendar/LabelDay
@onready var lbl_cal_month = $BtnCalendar/LabelMonth
@onready var btn_newspaper = $BtnNewspaper
@onready var btn_briefcase = $BtnBriefcase
@onready var btn_drawer = $BtnDrawer
@onready var btn_phone = $BtnPhone
@onready var btn_endmonth = $BtnEndMonth
@onready var btn_upgrade = $BtnUpgrade 

# Save-Menu UI
var save_popup: PopupMenu

# Tutorial-Menu UI
var tutorial_popup: PopupMenu

# --- NEUES SABOTAGE UI (CANVAS LAYER) ---
var sabotage_layer: CanvasLayer
var sabotage_panel: Panel
var opt_target: OptionButton
var opt_type: OptionButton
var opt_region: OptionButton
var lbl_cost: Label
var btn_execute: Button

# Zwischenspeicher für Logik
var selected_competitor_data = {} 

# Tooltip UI Variablen
var tooltip_panel: PanelContainer
var tooltip_label: Label

func _ready():
                load_office_style()
                create_save_popup()
                create_tutorial_popup()
                create_sabotage_ui() 
                setup_tooltips()
                
                if not GameManager.data_updated.is_connected(update_ui):
                                GameManager.data_updated.connect(update_ui)
                
                if not GameManager.month_ended.is_connected(_on_month_ended_report):
                                GameManager.month_ended.connect(_on_month_ended_report)
                
                if not GameManager.data_updated.is_connected(check_newspaper_status):
                                GameManager.data_updated.connect(check_newspaper_status)
                                
                if not GameManager.tech_activated.is_connected(check_upgrade_status):
                                GameManager.tech_activated.connect(check_upgrade_status)
                
                # Connect phone ringing signal for visual feedback
                if not GameManager.phone_ringing_changed.is_connected(_on_phone_ringing_changed):
                                GameManager.phone_ringing_changed.connect(_on_phone_ringing_changed)
                
                # Trigger tutorial for office entry
                if GameManager.tutorial_manager and GameManager.tutorial_manager.tutorial_enabled:
                                GameManager.tutorial_trigger.emit("office_enter")
                                
                # Initial Update
                update_ui()
                
                # Check for pending fire events
                if GameManager.show_fire_options and not GameManager.pending_fire_event.is_empty():
                                await get_tree().create_timer(0.5).timeout
                                show_fire_options_dialog()
                
                # Check for pending emergencies
                if GameManager.emergency_manager and not GameManager.emergency_manager.get_active_emergencies().is_empty():
                                _start_phone_animation()

func _on_phone_ringing_changed(is_ringing: bool):
                if is_ringing:
                                _start_phone_animation()
                else:
                                _stop_phone_animation()

# --- KEYBOARD SHORTCUTS ---
func _input(event):
                if event is InputEventKey and event.pressed:
                                var key = event.keycode
                                
                                # N = Next Day
                                if key == KEY_N:
                                                GameManager.next_day()
                                                accept_event()
                                
                                # M = Map / Regions
                                elif key == KEY_M:
                                                _on_btn_map_pressed()
                                                accept_event()
                                
                                # C = Computer
                                elif key == KEY_C:
                                                _on_btn_computer_pressed()
                                                accept_event()
                                
                                # S = Save
                                elif key == KEY_S:
                                                GameManager.save_game(GameManager.current_save_slot)
                                                accept_event()
                                
                                # E = End Month
                                elif key == KEY_E:
                                                _on_btn_end_month_pressed()
                                                accept_event()
                                
                                # T = Toggle Tutorial
                                elif key == KEY_T:
                                                if GameManager.tutorial_manager:
                                                                GameManager.tutorial_manager.toggle_tutorial()
                                                accept_event()
                                
                                # A = Achievements
                                elif key == KEY_A:
                                                _show_achievements()
                                                accept_event()
                                
                                # L = Activity Log
                                elif key == KEY_L:
                                                _show_activity_feed()
                                                accept_event()
                                
                                # F = Financial Report
                                elif key == KEY_F:
                                                _show_financial_report()
                                                accept_event()
                                
                                # $ = Loan Menu
                                elif key == KEY_DOLLAR:
                                                _show_loan_menu()
                                                accept_event()
                                
                                # Number keys 1-9 for quick region selection
                                elif key >= KEY_1 and key <= KEY_9:
                                                var region_idx = key - KEY_1
                                                var visible_regions = []
                                                for r_name in GameManager.regions:
                                                                if GameManager.regions[r_name].get("visible", false):
                                                                                visible_regions.append(r_name)
                                                
                                                if region_idx < visible_regions.size():
                                                                GameManager.current_viewing_region = visible_regions[region_idx]
                                                                _on_btn_map_pressed()
                                                accept_event()
                                
                                # H = Help (show shortcuts)
                                elif key == KEY_H:
                                                show_help()
                                                accept_event()

func show_help():
                var help_text = "=== TASTATURKÜRZEL ===\n\n"
                help_text += "N = Nächster Tag\n"
                help_text += "M = Karte / Regionen\n"
                help_text += "C = Computer\n"
                help_text += "S = Speichern\n"
                help_text += "E = Monat beenden\n"
                help_text += "T = Tutorial an/aus\n"
                help_text += "A = Erfolge anzeigen\n"
                help_text += "L = Aktivitäts-Log\n"
                help_text += "F = Finanzbericht\n"
                help_text += "$ = Kredite\n"
                help_text += "1-9 = Schnellauswahl Region\n"
                help_text += "H = Diese Hilfe"
                
                if has_node("/root/FeedbackOverlay"):
                                get_node("/root/FeedbackOverlay").show_msg(help_text, Color.CYAN)

# --- QUICK ACCESS PANELS ---
func _show_achievements():
                var achievement_display = preload("res://AchievementDisplay.gd").new()
                add_child(achievement_display)
                achievement_display.show_achievements()

func _show_activity_feed():
                var feed_display = preload("res://ActivityFeedDisplay.gd").new()
                add_child(feed_display)
                feed_display.show_feed()

func _show_financial_report():
                var report_panel = preload("res://FinancialReportPanel.gd").new()
                add_child(report_panel)
                report_panel.show_report()

func _show_loan_menu():
                if GameManager.loan_manager == null:
                                if has_node("/root/FeedbackOverlay"):
                                                get_node("/root/FeedbackOverlay").show_msg("Kreditsystem nicht verfügbar", Color.RED)
                                return
                
                var loan_panel = Panel.new()
                loan_panel.custom_minimum_size = Vector2(550, 400)
                loan_panel.set_anchors_preset(Control.PRESET_CENTER)
                add_child(loan_panel)
                
                var margin = MarginContainer.new()
                margin.set_anchors_preset(Control.PRESET_FULL_RECT)
                margin.add_theme_constant_override("margin_left", 20)
                margin.add_theme_constant_override("margin_right", 20)
                margin.add_theme_constant_override("margin_top", 15)
                margin.add_theme_constant_override("margin_bottom", 15)
                loan_panel.add_child(margin)
                
                var vbox = VBoxContainer.new()
                vbox.add_theme_constant_override("separation", 10)
                margin.add_child(vbox)
                
                # Header
                var header = HBoxContainer.new()
                vbox.add_child(header)
                
                var title = Label.new()
                title.text = "KREDITZENTRALE"
                title.add_theme_font_size_override("font_size", 22)
                header.add_child(title)
                
                var spacer = Control.new()
                spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                header.add_child(spacer)
                
                var btn_close = Button.new()
                btn_close.text = "X"
                btn_close.pressed.connect(func(): loan_panel.queue_free())
                header.add_child(btn_close)
                
                # Credit info
                var info = Label.new()
                info.text = "Rating: " + GameManager.loan_manager.get_credit_rating_text() + " | Schulden: $" + _fmt(GameManager.loan_manager.get_total_debt())
                vbox.add_child(info)
                
                # Separator
                var sep = HSeparator.new()
                vbox.add_child(sep)
                
                # Offers
                var offers = GameManager.loan_manager.get_available_offers()
                for offer in offers:
                                var hbox = HBoxContainer.new()
                                hbox.add_theme_constant_override("separation", 10)
                                vbox.add_child(hbox)
                                
                                var lbl = Label.new()
                                lbl.text = "%s: $%s @ %.1f%%" % [offer["name"], _fmt(offer["principal"]), offer["interest_rate"]*100]
                                lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                                hbox.add_child(lbl)
                                
                                var btn = Button.new()
                                btn.text = "AUFNEHMEN"
                                btn.disabled = not offer["can_afford"]
                                btn.pressed.connect(func(): 
                                                var result = GameManager.loan_manager.take_loan(offer["id"])
                                                if has_node("/root/FeedbackOverlay"):
                                                                get_node("/root/FeedbackOverlay").show_msg(result["message"], Color.GREEN if result["success"] else Color.RED)
                                                if result["success"]:
                                                                loan_panel.queue_free()
                                )
                                hbox.add_child(btn)

func load_office_style():
                var office_id = GameManager.current_office_id
                
                # Sicherheitscheck: Daten vorhanden?
                if not GameManager.office_data.has(office_id): return
                                
                var data = GameManager.office_data[office_id]
                
                # 1. Hintergrund setzen
                if data.has("bg_path") and data["bg_path"] != "":
                                background.texture = load(data["bg_path"])
                
                # 2. Buttons positionieren (Vector2 Daten aus GameData nutzen)
                _apply_transform(btn_computer, data, "computer")
                _apply_transform(btn_map, data, "map")
                _apply_transform(btn_calendar, data, "calendar")
                _apply_transform(btn_newspaper, data, "newspaper")
                _apply_transform(btn_briefcase, data, "briefcase")
                _apply_transform(btn_drawer, data, "drawer")
                _apply_transform(btn_phone, data, "phone")
                _apply_transform(btn_endmonth, data, "endmonth")

# Hilfsfunktion, um Position und Größe sicher zu setzen
func _apply_transform(node: Control, data: Dictionary, key_prefix: String):
                if node == null: return
                
                var pos_key = key_prefix + "_pos"
                var size_key = key_prefix + "_size"
                
                if data.has(pos_key):
                                node.position = data[pos_key]
                                
                if data.has(size_key):
                                node.set_deferred("size", data[size_key])

func update_ui():
                var d = GameManager.date["day"]
                var m = GameManager.date["month"] - 1 # Array index 0-11
                
                if lbl_cal_day:
                                lbl_cal_day.text = str(d)
                
                var month_names = ["JAN", "FEB", "MÄR", "APR", "MAI", "JUN", "JUL", "AUG", "SEP", "OKT", "NOV", "DEZ"]
                if lbl_cal_month:
                                lbl_cal_month.text = month_names[m]
                
                check_newspaper_status()
                check_upgrade_status()
                check_phone_ringing()

# --- PHONE RINGING VISUAL ---
func check_phone_ringing():
                if btn_phone == null:
                                return
                
                # Check if phone should be ringing
                var should_ring = false
                
                # Check for emergencies
                if GameManager.emergency_manager and not GameManager.emergency_manager.get_active_emergencies().is_empty():
                                should_ring = true
                
                # Check for sabotage reports
                if GameManager.pending_sabotage_reports.size() > 0:
                                should_ring = true
                
                # Check for story events
                if GameManager.story_event_manager and not GameManager.story_event_manager.get_pending_event().is_empty():
                                should_ring = true
                
                if should_ring and not GameManager.phone_ringing:
                                GameManager.phone_ringing = true
                
                if GameManager.phone_ringing:
                                _start_phone_animation()
                else:
                                _stop_phone_animation()

func _start_phone_animation():
                if btn_phone == null:
                                return
                
                # Stop existing tween
                if phone_ring_tween:
                                phone_ring_tween.kill()
                
                # Create pulsing animation
                phone_ring_tween = create_tween()
                phone_ring_tween.set_loops()
                phone_ring_tween.tween_property(btn_phone, "modulate", Color(1, 0.3, 0.3), 0.3)
                phone_ring_tween.tween_property(btn_phone, "modulate", Color(1, 1, 1), 0.3)

func _stop_phone_animation():
                if btn_phone == null:
                                return
                
                if phone_ring_tween:
                                phone_ring_tween.kill()
                                phone_ring_tween = null
                
                btn_phone.modulate = Color(1, 1, 1)

func _on_btn_calendar_pressed():
                GameManager.next_day()

func _on_btn_end_month_pressed() -> void:
                var current_day = GameManager.date["day"]
                var days_left = GameManager.DAYS_PER_MONTH - current_day + 1
                
                FeedbackOverlay.show_msg("Simuliere Monatsende (" + str(days_left) + " Tage)...")
                
                await get_tree().create_timer(0.5).timeout
                GameManager.advance_time(days_left)

func _on_month_ended_report(report):
                var profit = report.get("revenue", 0) - report.get("expenses", 0)
                var sign_str = "+" if profit >= 0 else ""
                var col = Color.GREEN if profit >= 0 else Color.RED
                
                var msg = "--- MONATSABSCHLUSS ---\n\n"
                msg += "ERGEBNIS: " + sign_str + "$" + _fmt(profit) + "\n"
                msg += "Siehe Statistik für Details."
                FeedbackOverlay.show_msg(msg, col)

func _fmt(value):
                var string = str(int(value))
                var mod = string.length() % 3
                var res = ""
                for i in range(0, string.length()):
                                if i != 0 && i % 3 == mod:
                                                res += "."
                                res += string[i]
                return res

func _on_btn_computer_pressed():
                GameManager.computer_nav_mode = ""
                get_tree().change_scene_to_file("res://Computer.tscn")

func _on_btn_map_pressed():
                # Go to Computer scene with worldmap (OilFieldMenu)
                GameManager.computer_nav_mode = "map"
                get_tree().change_scene_to_file("res://Computer.tscn")

# --- SPEICHERN ---
func create_save_popup():
                save_popup = PopupMenu.new()
                save_popup.name = "SaveMenu"
                add_child(save_popup)
                
                save_popup.add_item("Neuer Spielstand (Slot 1)", 1)
                save_popup.add_item("Neuer Spielstand (Slot 2)", 2)
                save_popup.add_item("Neuer Spielstand (Slot 3)", 3)
                
                if not save_popup.id_pressed.is_connected(_on_save_slot_selected):
                                save_popup.id_pressed.connect(_on_save_slot_selected)

func _on_save_slot_selected(id):
                GameManager.save_game(id)
                FeedbackOverlay.show_msg("Spiel in Slot " + str(id) + " gespeichert!", Color.GREEN)

func _on_save_item_pressed(id):
                GameManager.save_game(str(id))

# --- TUTORIAL ---
func create_tutorial_popup():
                tutorial_popup = PopupMenu.new()
                tutorial_popup.name = "TutorialMenu"
                add_child(tutorial_popup)
                
                tutorial_popup.add_item("Tutorial aktivieren", 1)
                tutorial_popup.add_item("Tutorial deaktivieren", 2)
                tutorial_popup.add_item("Tutorial zurücksetzen", 3)
                
                if not tutorial_popup.id_pressed.is_connected(_on_tutorial_menu_selected):
                                tutorial_popup.id_pressed.connect(_on_tutorial_menu_selected)
                
                # Update menu items based on current state
                _update_tutorial_menu()

func _update_tutorial_menu():
                if tutorial_popup == null: return
                if GameManager.tutorial_manager and GameManager.tutorial_manager.tutorial_enabled:
                                tutorial_popup.set_item_text(0, "✓ Tutorial aktiviert")
                                tutorial_popup.set_item_disabled(0, true)
                                tutorial_popup.set_item_text(1, "Tutorial deaktivieren")
                                tutorial_popup.set_item_disabled(1, false)
                else:
                                tutorial_popup.set_item_text(0, "Tutorial aktivieren")
                                tutorial_popup.set_item_disabled(0, false)
                                tutorial_popup.set_item_text(1, "✓ Tutorial deaktiviert")
                                tutorial_popup.set_item_disabled(1, true)

func _on_tutorial_menu_selected(id):
                if GameManager.tutorial_manager == null: return
                
                match id:
                                1:  # Enable tutorial
                                                GameManager.tutorial_manager.enable_tutorial()
                                                FeedbackOverlay.show_msg("Tutorial aktiviert! Tipps werden nun angezeigt.", Color.CYAN)
                                2:  # Disable tutorial
                                                GameManager.tutorial_manager.disable_tutorial()
                                                FeedbackOverlay.show_msg("Tutorial deaktiviert.", Color.GRAY)
                                3:  # Reset tutorial
                                                GameManager.tutorial_manager.reset_tutorial()
                                                FeedbackOverlay.show_msg("Tutorial zurückgesetzt. Es beginnt von vorn!", Color.CYAN)
                
                _update_tutorial_menu()

# --- BUTTON EVENT HANDLERS ---

# 1. SCHUBLADE -> SABOTAGE
func _on_btn_drawer_pressed(): 
                open_sabotage_menu()

# 2. KOFFER -> SPEICHERN
func _on_btn_briefcase_pressed():
                # Speichermenü an der Mausposition öffnen
                save_popup.position = _get_safe_popup_position(save_popup)
                save_popup.popup()

# Helper function to keep popups within viewport
func _get_safe_popup_position(_popup: PopupMenu) -> Vector2:
                var mouse_pos = get_viewport().get_mouse_position()
                var vp_size = get_viewport().get_visible_rect().size
                
                # Estimate popup size (will be adjusted after popup shows)
                var estimated_width = 250
                var estimated_height = 150
                
                # Clamp position to stay within viewport
                var x = clamp(mouse_pos.x, 0, vp_size.x - estimated_width)
                var y = clamp(mouse_pos.y, 0, vp_size.y - estimated_height)
                
                return Vector2(x, y)

# 3. TELEFON -> MENU (Notrufe, Notfälle & Kredite)
var phone_popup: PopupMenu
var phone_ring_tween: Tween
var emergency_layer: CanvasLayer

func _on_btn_phone_pressed():
                # First check for emergencies - they take priority!
                if GameManager.emergency_manager and not GameManager.emergency_manager.get_active_emergencies().is_empty():
                                _show_emergency_dialog()
                                return
                
                # Create popup menu for phone options
                if phone_popup:
                                phone_popup.queue_free()
                
                phone_popup = PopupMenu.new()
                add_child(phone_popup)
                
                # Check for active sabotage reports
                var has_reports = false
                if GameManager.ai_controller:
                                for comp in GameManager.ai_controller.competitors:
                                                if comp.get("sabotage_reports", []).size() > 0:
                                                                has_reports = true
                                                                break
                
                # Check for emergencies
                var has_emergencies = false
                if GameManager.emergency_manager:
                                has_emergencies = not GameManager.emergency_manager.get_active_emergencies().is_empty()
                
                phone_popup.add_item("🚨 NOTFALL-MENÜ" + (" (!)" if has_emergencies else ""), 1)
                phone_popup.add_item("📡 Sabotage-Berichte" + (" (!)" if has_reports else ""), 2)
                phone_popup.add_item("💰 Kreditzentrale", 3)
                phone_popup.add_separator()
                phone_popup.add_item("📞 Lobbying-Kontakte", 4)
                phone_popup.add_item("🛢️ OPEC-Geheimdienst", 5)
                
                phone_popup.id_pressed.connect(_on_phone_menu_selected)
                phone_popup.position = _get_safe_popup_position(phone_popup)
                phone_popup.popup()
                await phone_popup.popup_hide
                phone_popup.queue_free()

func _on_phone_menu_selected(id):
                match id:
                                1:  # Notfall-Menü
                                                if GameManager.emergency_manager and not GameManager.emergency_manager.get_active_emergencies().is_empty():
                                                                _show_emergency_dialog()
                                                else:
                                                                FeedbackOverlay.show_msg("Keine aktiven Notfälle.\nDas Telefon klingelt bei Problemen.", Color.CYAN)
                                2:  # Sabotage-Berichte
                                                var report = GameManager.answer_phone()
                                                if report == null:
                                                                FeedbackOverlay.show_msg("Leitung tot. Keine aktiven Berichte.", Color.WHITE)
                                                elif report.get("type") == "emergency":
                                                                _show_emergency_dialog()
                                                else:
                                                                var data = report.get("data", {})
                                                                var msg = "BERICHT: " + str(data.get("message", "Unbekannt"))
                                                                var col = Color.ORANGE
                                                                if data.get("success", false) and not data.get("detected", false):
                                                                                col = Color.GREEN
                                                                elif data.get("detected", false):
                                                                                col = Color.RED
                                                                FeedbackOverlay.show_msg(msg, col)
                                3:  # Kreditzentrale
                                                _show_loan_menu()
                                4:  # Lobbying
                                                _show_lobbying_menu()
                                5:  # OPEC
                                                _show_opec_menu()

# --- EMERGENCY DIALOG ---
func _show_emergency_dialog():
                if not GameManager.emergency_manager:
                                return
                
                var emergency = GameManager.emergency_manager.get_current_emergency()
                if emergency.is_empty():
                                emergency = GameManager.emergency_manager.answer_phone()
                
                if emergency.is_empty():
                                FeedbackOverlay.show_msg("Kein aktiver Notfall.", Color.WHITE)
                                return
                
                # Create emergency UI layer
                if emergency_layer:
                                emergency_layer.queue_free()
                
                emergency_layer = CanvasLayer.new()
                emergency_layer.layer = 120
                add_child(emergency_layer)
                
                # Dimmer
                var dimmer = ColorRect.new()
                dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
                dimmer.color = Color(0, 0, 0, 0.8)
                dimmer.pressed.connect(func(): pass)  # Block clicks
                emergency_layer.add_child(dimmer)
                
                # Main panel
                var panel = Panel.new()
                panel.custom_minimum_size = Vector2(700, 550)
                panel.set_anchors_preset(Control.PRESET_CENTER)
                emergency_layer.add_child(panel)
                
                var margin = MarginContainer.new()
                margin.set_anchors_preset(Control.PRESET_FULL_RECT)
                margin.add_theme_constant_override("margin_left", 30)
                margin.add_theme_constant_override("margin_right", 30)
                margin.add_theme_constant_override("margin_top", 20)
                margin.add_theme_constant_override("margin_bottom", 20)
                panel.add_child(margin)
                
                var vbox = VBoxContainer.new()
                vbox.add_theme_constant_override("separation", 15)
                margin.add_child(vbox)
                
                # Header with emergency icon
                var header = HBoxContainer.new()
                vbox.add_child(header)
                
                var icon = Label.new()
                icon.text = emergency.get("icon", "⚠️")
                icon.add_theme_font_size_override("font_size", 48)
                header.add_child(icon)
                
                var title = Label.new()
                title.text = emergency.get("name", "NOTFALL")
                title.add_theme_font_size_override("font_size", 32)
                title.add_theme_color_override("font_color", Color(1, 0.3, 0.2))
                header.add_child(title)
                
                var spacer = Control.new()
                spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                header.add_child(spacer)
                
                var btn_close = Button.new()
                btn_close.text = "X"
                btn_close.add_theme_font_size_override("font_size", 24)
                btn_close.pressed.connect(func(): 
                                emergency_layer.queue_free()
                                emergency_layer = null
                )
                header.add_child(btn_close)
                
                # Description
                var desc = Label.new()
                desc.text = emergency.get("formatted_description", emergency.get("description", ""))
                desc.autowrap_mode = TextServer.AUTOWRAP_WORD
                desc.add_theme_font_size_override("font_size", 20)
                vbox.add_child(desc)
                
                # Location & Time
                var info = Label.new()
                info.text = "📍 " + emergency.get("region", "?") + " | ⏱️ Zeit: " + str(emergency.get("hours_remaining", 0)) + " Stunden"
                info.add_theme_font_size_override("font_size", 18)
                info.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
                vbox.add_child(info)
                
                # Separator
                var sep = HSeparator.new()
                vbox.add_child(sep)
                
                # Resolution options label
                var options_label = Label.new()
                options_label.text = "MÖGLICHE MAßNAHMEN:"
                options_label.add_theme_font_size_override("font_size", 22)
                vbox.add_child(options_label)
                
                # Resolution options container
                var options_container = VBoxContainer.new()
                options_container.add_theme_constant_override("separation", 10)
                vbox.add_child(options_container)
                
                # Add each resolution option
                for method in emergency.get("resolution_methods", []):
                                var btn = Button.new()
                                var cost = int(method.get("cost", 0) * GameManager.inflation_rate)
                                var success_rate = int(method.get("success_rate", 0) * 100)
                                
                                btn.text = method.get("name", "?") + " - $" + GameManager.format_cash(cost) + " (" + str(success_rate) + "% Erfolg)"
                                btn.add_theme_font_size_override("font_size", 20)
                                btn.custom_minimum_size.y = 50
                                
                                # Check if player can afford
                                if cost > GameManager.cash:
                                                btn.disabled = true
                                                btn.modulate = Color(0.5, 0.5, 0.5)
                                
                                btn.pressed.connect(func(): 
                                                var result = GameManager.emergency_manager.resolve_emergency(emergency.get("id", ""), method.get("id", ""))
                                                emergency_layer.queue_free()
                                                emergency_layer = null
                                                if result.get("success", false):
                                                                FeedbackOverlay.show_msg("✅ " + result.get("message", "Erfolg!"), Color.GREEN)
                                                else:
                                                                FeedbackOverlay.show_msg("❌ " + result.get("message", "Fehlgeschlagen!"), Color.RED)
                                )
                                options_container.add_child(btn)
                
                # Spacer
                var vspacer = Control.new()
                vspacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
                vbox.add_child(vspacer)
                
                # Warning
                var warning = Label.new()
                warning.text = "⚠️ Ignorieren führt zu automatischen Strafen nach Ablauf der Zeit!"
                warning.add_theme_font_size_override("font_size", 16)
                warning.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
                warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                vbox.add_child(warning)

# --- LOBBYING MENU ---
func _show_lobbying_menu():
                if not GameManager.lobbying_manager:
                                FeedbackOverlay.show_msg("Lobbying-System nicht verfügbar.", Color.RED)
                                return
                
                var lobby_layer = CanvasLayer.new()
                lobby_layer.layer = 115
                add_child(lobby_layer)
                
                var dimmer = ColorRect.new()
                dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
                dimmer.color = Color(0, 0, 0, 0.85)
                lobby_layer.add_child(dimmer)
                
                var panel = Panel.new()
                panel.custom_minimum_size = Vector2(800, 600)
                panel.set_anchors_preset(Control.PRESET_CENTER)
                lobby_layer.add_child(panel)
                
                var margin = MarginContainer.new()
                margin.set_anchors_preset(Control.PRESET_FULL_RECT)
                margin.add_theme_constant_override("margin_left", 25)
                margin.add_theme_constant_override("margin_right", 25)
                margin.add_theme_constant_override("margin_top", 20)
                margin.add_theme_constant_override("margin_bottom", 20)
                panel.add_child(margin)
                
                var vbox = VBoxContainer.new()
                vbox.add_theme_constant_override("separation", 12)
                margin.add_child(vbox)
                
                # Header
                var header = HBoxContainer.new()
                vbox.add_child(header)
                
                var title = Label.new()
                title.text = "🏛️ LOBBYING-ZENTRALE"
                title.add_theme_font_size_override("font_size", 28)
                header.add_child(title)
                
                var spacer = Control.new()
                spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                header.add_child(spacer)
                
                var btn_close = Button.new()
                btn_close.text = "X"
                btn_close.add_theme_font_size_override("font_size", 22)
                btn_close.pressed.connect(func(): lobby_layer.queue_free())
                header.add_child(btn_close)
                
                # Scroll container for politicians
                var scroll = ScrollContainer.new()
                scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
                vbox.add_child(scroll)
                
                var politicians_container = VBoxContainer.new()
                politicians_container.add_theme_constant_override("separation", 8)
                scroll.add_child(politicians_container)
                
                # Add politicians
                for politician in GameManager.lobbying_manager.get_available_politicians():
                                var pol_panel = PanelContainer.new()
                                pol_panel.custom_minimum_size.y = 80
                                politicians_container.add_child(pol_panel)
                                
                                var hbox = HBoxContainer.new()
                                hbox.add_theme_constant_override("separation", 15)
                                pol_panel.add_child(hbox)
                                
                                # Info
                                var info_vbox = VBoxContainer.new()
                                info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                                hbox.add_child(info_vbox)
                                
                                var name_lbl = Label.new()
                                name_lbl.text = politician.get("name", "?")
                                name_lbl.add_theme_font_size_override("font_size", 20)
                                info_vbox.add_child(name_lbl)
                                
                                var desc_lbl = Label.new()
                                desc_lbl.text = politician.get("description", "")
                                desc_lbl.add_theme_font_size_override("font_size", 14)
                                desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
                                desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
                                info_vbox.add_child(desc_lbl)
                                
                                # Cost & Button
                                var cost_lbl = Label.new()
                                cost_lbl.text = "$" + GameManager.format_cash(politician.get("cost", 0))
                                cost_lbl.add_theme_font_size_override("font_size", 18)
                                cost_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
                                hbox.add_child(cost_lbl)
                                
                                var btn_bribe = Button.new()
                                btn_bribe.text = "EINFLUSS KAUFEN"
                                btn_bribe.disabled = politician.get("cost", 0) > GameManager.cash
                                btn_bribe.pressed.connect(func():
                                                _show_lobbying_actions(politician, lobby_layer)
                                )
                                hbox.add_child(btn_bribe)
                
                # Warning footer
                var warning = Label.new()
                warning.text = "⚠️ Vorsicht: Korruption kann zu Skandalen führen!"
                warning.add_theme_font_size_override("font_size", 14)
                warning.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
                warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                vbox.add_child(warning)

func _show_lobbying_actions(politician: Dictionary, parent_layer: CanvasLayer):
                # Show available actions for this politician
                var actions_popup = Panel.new()
                actions_popup.custom_minimum_size = Vector2(500, 400)
                actions_popup.set_anchors_preset(Control.PRESET_CENTER)
                parent_layer.add_child(actions_popup)
                
                var margin = MarginContainer.new()
                margin.set_anchors_preset(Control.PRESET_FULL_RECT)
                margin.add_theme_constant_override("margin_left", 20)
                margin.add_theme_constant_override("margin_right", 20)
                margin.add_theme_constant_override("margin_top", 15)
                margin.add_theme_constant_override("margin_bottom", 15)
                actions_popup.add_child(margin)
                
                var vbox = VBoxContainer.new()
                vbox.add_theme_constant_override("separation", 10)
                margin.add_child(vbox)
                
                var title = Label.new()
                title.text = "Aktionen: " + politician.get("name", "?")
                title.add_theme_font_size_override("font_size", 22)
                vbox.add_child(title)
                
                for action in GameManager.lobbying_manager.get_available_actions():
                                var btn = Button.new()
                                btn.text = action.get("name", "?")
                                btn.add_theme_font_size_override("font_size", 16)
                                btn.custom_minimum_size.y = 45
                                btn.tooltip_text = action.get("description", "")
                                btn.pressed.connect(func():
                                                var result = GameManager.lobbying_manager.attempt_lobbying(politician.get("id", ""), action.get("id", ""))
                                                actions_popup.queue_free()
                                                if result.get("success", false):
                                                                FeedbackOverlay.show_msg("✅ " + result.get("message", "Erfolg!"), Color.GREEN)
                                                elif result.get("scandal", false):
                                                                FeedbackOverlay.show_msg("🚨 SKANDAL! " + result.get("message", ""), Color.RED)
                                                else:
                                                                FeedbackOverlay.show_msg("❌ " + result.get("message", "Fehlgeschlagen"), Color.ORANGE)
                                )
                                vbox.add_child(btn)
                
                var btn_cancel = Button.new()
                btn_cancel.text = "ABBRECHEN"
                btn_cancel.pressed.connect(func(): actions_popup.queue_free())
                vbox.add_child(btn_cancel)

# --- OPEC MENU ---
func _show_opec_menu():
                if not GameManager.opec_manager:
                                FeedbackOverlay.show_msg("OPEC-System nicht verfügbar.", Color.RED)
                                return
                
                var opec_layer = CanvasLayer.new()
                opec_layer.layer = 115
                add_child(opec_layer)
                
                var dimmer = ColorRect.new()
                dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
                dimmer.color = Color(0, 0, 0, 0.85)
                opec_layer.add_child(dimmer)
                
                var panel = Panel.new()
                panel.custom_minimum_size = Vector2(750, 550)
                panel.set_anchors_preset(Control.PRESET_CENTER)
                opec_layer.add_child(panel)
                
                var margin = MarginContainer.new()
                margin.set_anchors_preset(Control.PRESET_FULL_RECT)
                margin.add_theme_constant_override("margin_left", 25)
                margin.add_theme_constant_override("margin_right", 25)
                margin.add_theme_constant_override("margin_top", 20)
                margin.add_theme_constant_override("margin_bottom", 20)
                panel.add_child(margin)
                
                var vbox = VBoxContainer.new()
                vbox.add_theme_constant_override("separation", 15)
                margin.add_child(vbox)
                
                # Header
                var header = HBoxContainer.new()
                vbox.add_child(header)
                
                var title = Label.new()
                title.text = "🛢️ OPEC-GEHEIMDIENST"
                title.add_theme_font_size_override("font_size", 28)
                header.add_child(title)
                
                var spacer = Control.new()
                spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                header.add_child(spacer)
                
                var btn_close = Button.new()
                btn_close.text = "X"
                btn_close.add_theme_font_size_override("font_size", 22)
                btn_close.pressed.connect(func(): opec_layer.queue_free())
                header.add_child(btn_close)
                
                # Status
                var status = GameManager.opec_manager.get_opec_status()
                var status_lbl = Label.new()
                var crisis_text = "🚨 ÖLKRISE AKTIV!" if status.get("crisis_active", false) else "Markt stabil"
                status_lbl.text = "Status: " + crisis_text + " | Aktive Deals: " + str(status.get("active_deals", 0))
                status_lbl.add_theme_font_size_override("font_size", 18)
                vbox.add_child(status_lbl)
                
                # Separator
                var sep = HSeparator.new()
                vbox.add_child(sep)
                
                # Secret deals header
                var deals_header = Label.new()
                deals_header.text = "VERTRAULICHE ANGEBOTE:"
                deals_header.add_theme_font_size_override("font_size", 20)
                vbox.add_child(deals_header)
                
                # Deals container
                var scroll = ScrollContainer.new()
                scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
                vbox.add_child(scroll)
                
                var deals_container = VBoxContainer.new()
                deals_container.add_theme_constant_override("separation", 8)
                scroll.add_child(deals_container)
                
                for deal in GameManager.opec_manager.get_available_secret_deals():
                                var deal_panel = PanelContainer.new()
                                deal_panel.custom_minimum_size.y = 70
                                deals_container.add_child(deal_panel)
                                
                                var hbox = HBoxContainer.new()
                                hbox.add_theme_constant_override("separation", 10)
                                deal_panel.add_child(hbox)
                                
                                var info = VBoxContainer.new()
                                info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
                                hbox.add_child(info)
                                
                                var name_lbl = Label.new()
                                name_lbl.text = deal.get("name", "?")
                                name_lbl.add_theme_font_size_override("font_size", 18)
                                info.add_child(name_lbl)
                                
                                var desc_lbl = Label.new()
                                desc_lbl.text = deal.get("description", "")
                                desc_lbl.add_theme_font_size_override("font_size", 12)
                                desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
                                info.add_child(desc_lbl)
                                
                                var cost_lbl = Label.new()
                                cost_lbl.text = "$" + GameManager.format_cash(deal.get("cost", 0))
                                cost_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
                                hbox.add_child(cost_lbl)
                                
                                var risk_lbl = Label.new()
                                risk_lbl.text = str(int(deal.get("risk", 0) * 100)) + "% Risiko"
                                risk_lbl.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
                                hbox.add_child(risk_lbl)
                                
                                var btn = Button.new()
                                btn.text = "DEAL"
                                btn.disabled = deal.get("cost", 0) > GameManager.cash
                                btn.pressed.connect(func():
                                                var result = GameManager.opec_manager.attempt_secret_deal(deal.get("id", ""))
                                                opec_layer.queue_free()
                                                if result.get("success", false):
                                                                FeedbackOverlay.show_msg("🤝 Deal erfolgreich!", Color.GREEN)
                                                elif result.get("scandal", false):
                                                                FeedbackOverlay.show_msg("🚨 " + result.get("message", "Skandal!"), Color.RED)
                                                else:
                                                                FeedbackOverlay.show_msg("❌ " + result.get("message", ""), Color.ORANGE)
                                )
                                hbox.add_child(btn)
                
                # Warning
                var warning = Label.new()
                warning.text = "⚠️ Geheimdienste können aufgedeckt werden - hoher Risikofaktor!"
                warning.add_theme_font_size_override("font_size", 14)
                warning.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
                warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                vbox.add_child(warning)

# --- ZEITUNG ---
func check_newspaper_status():
                if btn_newspaper:
                                var has_unread = GameManager.unread_news.size() > 0
                                var has_headlines = false
                                
                                # Check for newspaper headlines
                                if GameManager.newspaper_manager:
                                                has_headlines = not GameManager.newspaper_manager.get_current_headlines().is_empty()
                                
                                if has_unread or has_headlines:
                                                btn_newspaper.modulate = Color(1, 0.5, 0.5) 
                                else:
                                                btn_newspaper.modulate = Color(1, 1, 1)

func _on_btn_newspaper_pressed():
                # Check for newspaper headlines first (from NewspaperManager)
                if GameManager.newspaper_manager:
                                var headlines = GameManager.newspaper_manager.get_current_headlines()
                                if not headlines.is_empty():
                                                _show_newspaper_headlines()
                                                return
                
                # Then check for unread news (old system)
                if not GameManager.unread_news.is_empty():
                                var news = GameManager.unread_news.pop_front()
                                var txt = "[ " + news.get("title", "INFO") + " ]\n\n" + news.get("text", "")
                                FeedbackOverlay.show_msg(txt, Color.WHITE)
                                GameManager.news_archive.append(news)
                                check_newspaper_status()
                                return
                
                # Show options menu when no news
                var options_popup = PopupMenu.new()
                add_child(options_popup)
                options_popup.add_item("📰 Zeitung anzeigen", 1)
                options_popup.add_item("📚 Archiv (" + str(GameManager.news_archive.size()) + " Einträge)", 2)
                options_popup.add_separator()
                options_popup.add_item("❓ Tutorial-Einstellungen", 3)
                options_popup.id_pressed.connect(_on_newspaper_menu_selected)
                options_popup.position = _get_safe_popup_position(options_popup)
                options_popup.popup()
                await options_popup.popup_hide
                options_popup.queue_free()

func _show_newspaper_headlines():
                if not GameManager.newspaper_manager:
                                return
                
                var headlines = GameManager.newspaper_manager.get_current_headlines()
                if headlines.is_empty():
                                FeedbackOverlay.show_msg("Keine aktuellen Schlagzeilen.", Color.WHITE)
                                return
                
                # Create newspaper display layer
                var news_layer = CanvasLayer.new()
                news_layer.layer = 115
                add_child(news_layer)
                
                var dimmer = ColorRect.new()
                dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
                dimmer.color = Color(0, 0, 0, 0.85)
                news_layer.add_child(dimmer)
                
                # Newspaper panel
                var panel = Panel.new()
                panel.custom_minimum_size = Vector2(700, 600)
                panel.set_anchors_preset(Control.PRESET_CENTER)
                news_layer.add_child(panel)
                
                # Style the panel like old paper
                var style = StyleBoxFlat.new()
                style.bg_color = Color(0.95, 0.92, 0.85)
                style.border_color = Color(0.3, 0.25, 0.2)
                style.set_border_width_all(4)
                panel.add_theme_stylebox_override("panel", style)
                
                var margin = MarginContainer.new()
                margin.set_anchors_preset(Control.PRESET_FULL_RECT)
                margin.add_theme_constant_override("margin_left", 30)
                margin.add_theme_constant_override("margin_right", 30)
                margin.add_theme_constant_override("margin_top", 20)
                margin.add_theme_constant_override("margin_bottom", 20)
                panel.add_child(margin)
                
                var vbox = VBoxContainer.new()
                vbox.add_theme_constant_override("separation", 12)
                margin.add_child(vbox)
                
                # Masthead
                var masthead = Label.new()
                masthead.text = "━━━━━ THE DAILY BARREL ━━━━━"
                masthead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                masthead.add_theme_font_size_override("font_size", 28)
                masthead.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
                vbox.add_child(masthead)
                
                # Date line
                var date_line = Label.new()
                date_line.text = "%s %d | Ölpreis: $%.2f/Fass" % [
                                _get_month_name_full(GameManager.date["month"]),
                                GameManager.date["year"],
                                GameManager.oil_price
                ]
                date_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                date_line.add_theme_font_size_override("font_size", 14)
                date_line.add_theme_color_override("font_color", Color(0.4, 0.35, 0.3))
                vbox.add_child(date_line)
                
                # Separator
                var sep = HSeparator.new()
                vbox.add_child(sep)
                
                # Scroll container for headlines
                var scroll = ScrollContainer.new()
                scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
                vbox.add_child(scroll)
                
                var headlines_container = VBoxContainer.new()
                headlines_container.add_theme_constant_override("separation", 15)
                scroll.add_child(headlines_container)
                
                # Add each headline
                for headline in headlines:
                                var headline_box = VBoxContainer.new()
                                headline_box.add_theme_constant_override("separation", 5)
                                headlines_container.add_child(headline_box)
                                
                                var title = Label.new()
                                title.text = headline.get("title", "?")
                                title.autowrap_mode = TextServer.AUTOWRAP_WORD
                                title.add_theme_font_size_override("font_size", 20)
                                title.add_theme_color_override("font_color", _get_category_color(headline.get("category", -1)))
                                headline_box.add_child(title)
                                
                                var text = Label.new()
                                text.text = headline.get("text", "")
                                text.autowrap_mode = TextServer.AUTOWRAP_WORD
                                text.add_theme_font_size_override("font_size", 14)
                                text.add_theme_color_override("font_color", Color(0.2, 0.15, 0.1))
                                headline_box.add_child(text)
                                
                                # Date
                                var date_lbl = Label.new()
                                date_lbl.text = "[" + str(headline.get("date", "?")) + "]"
                                date_lbl.add_theme_font_size_override("font_size", 12)
                                date_lbl.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))
                                headline_box.add_child(date_lbl)
                
                # Close button
                var close_hbox = HBoxContainer.new()
                close_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
                vbox.add_child(close_hbox)
                
                var btn_close = Button.new()
                btn_close.text = "SCHLIESSEN"
                btn_close.add_theme_font_size_override("font_size", 18)
                btn_close.custom_minimum_size = Vector2(200, 50)
                btn_close.pressed.connect(func(): news_layer.queue_free())
                close_hbox.add_child(btn_close)

func _get_month_name_full(month: int) -> String:
                var months = ["Januar", "Februar", "März", "April", "Mai", "Juni",
                                          "Juli", "August", "September", "Oktober", "November", "Dezember"]
                return months[month - 1] if month >= 1 and month <= 12 else "?"

func _get_category_color(category: int) -> Color:
                match category:
                                0: return Color(0.6, 0.1, 0.1)  # WORLD_EVENT - Dark red
                                1: return Color(0.1, 0.5, 0.1)  # COMPANY_SUCCESS - Green
                                2: return Color(0.6, 0.3, 0.1)  # COMPANY_FAILURE - Brown
                                3: return Color(0.6, 0.1, 0.1)  # HISTORICAL_EVENT - Dark red
                                4: return Color(0.6, 0.5, 0.1)  # OPEC_NEWS - Gold
                                5: return Color(0.3, 0.3, 0.6)  # POLITICAL_NEWS - Blue
                                6: return Color(0.4, 0.4, 0.4)  # MARKET_NEWS - Gray
                                7: return Color(0.8, 0.3, 0.1)  # DISASTER - Orange
                                _: return Color(0.2, 0.15, 0.1)

func _on_newspaper_menu_selected(id):
                match id:
                                1:  # Show newspaper
                                                _show_newspaper_headlines()
                                2:  # Archive
                                                if GameManager.news_archive.is_empty():
                                                                FeedbackOverlay.show_msg("Archiv ist leer.", Color.WHITE)
                                                else:
                                                                var archive_text = "=== NACHRICHTEN-ARCHIV ===\n\n"
                                                                for news in GameManager.news_archive:
                                                                                archive_text += "[" + news.get("date_str", "?") + "] " + news.get("title", "?") + "\n"
                                                                FeedbackOverlay.show_msg(archive_text, Color.WHITE)
                                3:  # Tutorial settings
                                                tutorial_popup.position = _get_safe_popup_position(tutorial_popup)
                                                tutorial_popup.popup()

# --- UPGRADES ---
func check_upgrade_status():
                if btn_upgrade:
                                # Use era_manager for upgrade check
                                if GameManager.era_manager:
                                                var upgrade_check = GameManager.era_manager.can_upgrade_era()
                                                if upgrade_check["can_upgrade"]:
                                                                btn_upgrade.visible = true
                                                                btn_upgrade.modulate = Color(0, 1, 0)  # Green - upgrade available
                                                else:
                                                                # Show button if year is right but money is missing
                                                                var year = GameManager.date["year"]
                                                                var current_era = GameManager.current_era
                                                                if current_era == 0 and year >= 1982:
                                                                                btn_upgrade.visible = true
                                                                                btn_upgrade.modulate = Color(1, 0.5, 0)  # Orange - need money
                                                                elif current_era == 1 and year >= 1995:
                                                                                btn_upgrade.visible = true
                                                                                btn_upgrade.modulate = Color(1, 0.5, 0)  # Orange - need money
                                                                else:
                                                                                btn_upgrade.visible = false
                                else:
                                                # Fallback to old system
                                                if GameManager.check_tech_availability():
                                                                btn_upgrade.visible = true
                                                                btn_upgrade.modulate = Color(0, 1, 0)
                                                else:
                                                                btn_upgrade.visible = false

func _on_btn_upgrade_pressed():
                # Use era_manager for upgrade
                if GameManager.era_manager:
                                var upgrade_check = GameManager.era_manager.can_upgrade_era()
                                if upgrade_check["can_upgrade"]:
                                                if GameManager.era_manager.perform_era_upgrade():
                                                                var era_name = GameManager.era_manager.get_era_name()
                                                                FeedbackOverlay.show_msg("ÄRA UPGRADE!\n" + era_name, Color.GREEN)
                                                                load_office_style()
                                                                return
                                # Show why upgrade failed
                                FeedbackOverlay.show_msg(upgrade_check["reason"], Color.RED)
                else:
                                # Fallback to old system
                                if GameManager.upgrade_era():
                                                FeedbackOverlay.show_msg("Büro & Technik aufgerüstet!", Color.GREEN)
                                                load_office_style()
                                else:
                                                FeedbackOverlay.show_msg("Nicht genug Geld oder Jahr noch nicht erreicht.")


# ==============================================================================
# --- SABOTAGE SYSTEM (WIZARD, NEUTRAL START, BIG FONT) ---
# ==============================================================================

func create_sabotage_ui():
                # Aufräumen falls nötig
                if sabotage_layer: sabotage_layer.queue_free()
                
                # CanvasLayer sorgt dafür, dass es ÜBERALLEM liegt (Z-Index 110)
                sabotage_layer = CanvasLayer.new()
                sabotage_layer.layer = 110 
                sabotage_layer.visible = false
                add_child(sabotage_layer)
                
                # Dimmer (Hintergrund abdunkeln)
                var dimmer = ColorRect.new()
                dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
                dimmer.color = Color(0, 0, 0, 0.85) # Dunkler Hintergrund
                sabotage_layer.add_child(dimmer)
                
                # Haupt-Panel (Kompakter & Weiter oben)
                sabotage_panel = Panel.new()
                sabotage_panel.custom_minimum_size = Vector2(900, 650)
                sabotage_panel.set_anchors_preset(Control.PRESET_CENTER)
                
                # Manuelles Zentrieren, aber nach OBEN verschoben
                sabotage_panel.anchor_left = 0.5; sabotage_panel.anchor_top = 0.5
                sabotage_panel.anchor_right = 0.5; sabotage_panel.anchor_bottom = 0.5
                
                # Wir schieben es 50 Pixel nach oben (-375 statt -325)
                sabotage_panel.offset_left = -450; sabotage_panel.offset_top = -375 
                sabotage_panel.offset_right = 450; sabotage_panel.offset_bottom = 275
                sabotage_layer.add_child(sabotage_panel)
                
                var margin = MarginContainer.new()
                margin.set_anchors_preset(Control.PRESET_FULL_RECT)
                margin.add_theme_constant_override("margin_left", 40)
                margin.add_theme_constant_override("margin_right", 40)
                margin.add_theme_constant_override("margin_top", 30)
                margin.add_theme_constant_override("margin_bottom", 30)
                sabotage_panel.add_child(margin)
                
                var vbox = VBoxContainer.new()
                vbox.add_theme_constant_override("separation", 25)
                margin.add_child(vbox)
                
                # Header
                var title = Label.new()
                title.text = "SCHATTEN-DOSSIER"
                title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                title.add_theme_font_size_override("font_size", 40)
                title.add_theme_color_override("font_color", Color(1, 0.3, 0.3)) # Rot
                vbox.add_child(title)
                
                # --- SCHRITT 1: GEGNER ---
                var lbl1 = Label.new()
                lbl1.text = "1. ZIELPERSON:"
                lbl1.add_theme_font_size_override("font_size", 24)
                vbox.add_child(lbl1)
                
                opt_target = OptionButton.new()
                opt_target.custom_minimum_size.y = 50 
                # Große Schrift für Button UND Popup
                opt_target.add_theme_font_size_override("font_size", 35) 
                opt_target.get_popup().add_theme_font_size_override("font_size", 35)
                opt_target.item_selected.connect(_on_target_selected)
                vbox.add_child(opt_target)
                
                # --- SCHRITT 2: METHODE ---
                var lbl2 = Label.new()
                lbl2.text = "2. METHODE:"
                lbl2.add_theme_font_size_override("font_size", 24)
                vbox.add_child(lbl2)
                
                opt_type = OptionButton.new()
                opt_type.custom_minimum_size.y = 50
                opt_type.add_theme_font_size_override("font_size", 35)
                opt_type.get_popup().add_theme_font_size_override("font_size", 35)
                opt_type.disabled = true 
                opt_type.item_selected.connect(_on_type_selected)
                vbox.add_child(opt_type)
                
                # --- SCHRITT 3: REGION ---
                var lbl3 = Label.new()
                lbl3.text = "3. ZIELGEBIET:"
                lbl3.add_theme_font_size_override("font_size", 24)
                vbox.add_child(lbl3)
                
                opt_region = OptionButton.new()
                opt_region.custom_minimum_size.y = 50
                opt_region.add_theme_font_size_override("font_size", 35)
                opt_region.get_popup().add_theme_font_size_override("font_size", 35)
                opt_region.disabled = true 
                opt_region.item_selected.connect(_on_region_selected)
                vbox.add_child(opt_region)
                
                # Spacer
                var spacer = Control.new()
                spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
                vbox.add_child(spacer)
                
                # --- INFO & KOSTEN ---
                var sep = HSeparator.new()
                vbox.add_child(sep)
                
                lbl_cost = Label.new()
                lbl_cost.text = "Gesamtkosten: ---"
                lbl_cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
                lbl_cost.add_theme_font_size_override("font_size", 36)
                lbl_cost.add_theme_color_override("font_color", Color(1, 0.8, 0.2)) # Gold
                vbox.add_child(lbl_cost)
                
                # --- BUTTONS ---
                var hbox_btns = HBoxContainer.new()
                hbox_btns.alignment = BoxContainer.ALIGNMENT_END
                hbox_btns.add_theme_constant_override("separation", 30)
                vbox.add_child(hbox_btns)
                
                var btn_cancel = Button.new()
                btn_cancel.text = "ABBRECHEN"
                btn_cancel.add_theme_font_size_override("font_size", 24)
                btn_cancel.custom_minimum_size = Vector2(200, 60)
                btn_cancel.pressed.connect(func(): sabotage_layer.visible = false)
                hbox_btns.add_child(btn_cancel)
                
                btn_execute = Button.new()
                btn_execute.text = "AUSFÜHREN"
                btn_execute.add_theme_font_size_override("font_size", 24)
                btn_execute.custom_minimum_size = Vector2(250, 60)
                btn_execute.disabled = true
                btn_execute.modulate = Color(1, 0.4, 0.4)
                btn_execute.pressed.connect(_on_execute_sabotage_pressed)
                hbox_btns.add_child(btn_execute)

func open_sabotage_menu():
                sabotage_layer.visible = true
                selected_competitor_data = {}
                
                opt_target.clear()
                opt_type.clear()
                opt_region.clear()
                
                opt_target.disabled = false
                opt_type.disabled = true
                opt_region.disabled = true
                btn_execute.disabled = true
                lbl_cost.text = "Kosten: ---"
                
                # START: Platzhalter als erstes Item (Neutral)
                opt_target.add_item("- BITTE WÄHLEN -", 999)
                
                if GameManager.ai_controller and GameManager.ai_controller.competitors:
                                var idx = 0
                                for comp in GameManager.ai_controller.competitors:
                                                opt_target.add_item(comp["name"], idx)
                                                idx += 1
                                                
                opt_target.select(0)
                
                # Dummy-Items für gesperrte Felder
                opt_type.add_item("- WARTET -", 999); opt_type.select(0)
                opt_region.add_item("- WARTET -", 999); opt_region.select(0)

func _on_target_selected(index):
                var id = opt_target.get_item_id(index)
                
                # Wenn Platzhalter (999) gewählt -> RESET ALLES DARUNTER
                if id == 999:
                                selected_competitor_data = {}
                                opt_type.clear(); opt_type.add_item("- WARTET -", 999); opt_type.select(0); opt_type.disabled = true
                                opt_region.clear(); opt_region.add_item("- WARTET -", 999); opt_region.select(0); opt_region.disabled = true
                                lbl_cost.text = "Kosten: ---"
                                btn_execute.disabled = true
                                return
                
                selected_competitor_data = GameManager.ai_controller.competitors[id]
                
                # Methode aktivieren
                opt_type.disabled = false
                opt_type.clear()
                
                # Neutraler Start für Methode
                opt_type.add_item("- METHODE WÄHLEN -", 999)
                
                var sab_ops = GameManager.GameData.SABOTAGE_OPTIONS
                var op_idx = 0
                for key in sab_ops:
                                var op = sab_ops[key]
                                opt_type.add_item(op["name"], op_idx)
                                opt_type.set_item_metadata(op_idx + 1, key) 
                                op_idx += 1
                
                opt_type.select(0)
                                
                # Region Reset
                opt_region.clear(); opt_region.add_item("- WARTET -", 999); opt_region.select(0); opt_region.disabled = true
                lbl_cost.text = "Kosten: ---"
                btn_execute.disabled = true

func _on_type_selected(index):
                var id = opt_type.get_item_id(index)
                
                if id == 999:
                                opt_region.clear(); opt_region.add_item("- WARTET -", 999); opt_region.select(0); opt_region.disabled = true
                                lbl_cost.text = "Kosten: ---"
                                btn_execute.disabled = true
                                return
                
                opt_region.disabled = false
                opt_region.clear()
                opt_region.add_item("- ZIELGEBIET WÄHLEN -", 999)
                
                var target_name = selected_competitor_data["name"]
                var found_any = false
                
                for r_name in GameManager.regions:
                                if GameManager.regions[r_name] == null: continue
                                var region_data = GameManager.regions[r_name]
                                
                                # NUR SICHTBARE REGIONEN ANZEIGEN
                                if not region_data.get("visible", false): continue
                                
                                var is_active = false
                                if region_data.has("claims"):
                                                for c in region_data["claims"]:
                                                                if c == null or typeof(c) != TYPE_DICTIONARY: continue
                                                                if c.get("is_empty", false): continue
                                                                if c.get("ai_owner") == target_name:
                                                                                is_active = true
                                                                                break
                                if is_active:
                                                opt_region.add_item(r_name)
                                                opt_region.set_item_metadata(opt_region.item_count - 1, r_name)
                                                found_any = true
                                                
                if not found_any:
                                opt_region.clear(); opt_region.add_item("KEINE ZIELE GEFUNDEN", 999); opt_region.disabled = true
                
                opt_region.select(0)
                lbl_cost.text = "Kosten: ---"
                btn_execute.disabled = true

func _on_region_selected(index):
                var id = opt_region.get_item_id(index)
                if id == 999: 
                                lbl_cost.text = "Kosten: ---"
                                btn_execute.disabled = true
                                return
                
                var type_key = opt_type.get_selected_metadata()
                var base_cost = GameManager.GameData.SABOTAGE_OPTIONS[type_key]["cost"]
                var real_cost = int(base_cost * GameManager.inflation_rate)
                lbl_cost.text = "KOSTEN: $" + _fmt(real_cost)
                btn_execute.disabled = false

func _on_execute_sabotage_pressed():
                var type_key = opt_type.get_selected_metadata()
                var region_name = opt_region.get_selected_metadata()
                var result = GameManager.player_order_sabotage(type_key, region_name)
                sabotage_layer.visible = false
                if result.success: FeedbackOverlay.show_msg("AUFTRAG ERTEILT: Operation läuft...", Color.GREEN)
                else: FeedbackOverlay.show_msg(result.message, Color.RED)

# --- FIRE OPTIONS DIALOG ---
var fire_dialog_layer: CanvasLayer

func show_fire_options_dialog():
                if fire_dialog_layer:
                                fire_dialog_layer.queue_free()
                
                var fire_data = GameManager.pending_fire_event
                if fire_data.is_empty():
                                return
                
                fire_dialog_layer = CanvasLayer.new()
                fire_dialog_layer.layer = 150
                add_child(fire_dialog_layer)
                
                # Dimmer background
                var dimmer = ColorRect.new()
                dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
                dimmer.color = Color(0, 0, 0, 0.85)
                fire_dialog_layer.add_child(dimmer)
                
                # Main panel
                var panel = Panel.new()
                panel.custom_minimum_size = Vector2(600, 400)
                panel.set_anchors_preset(Control.PRESET_CENTER)
                fire_dialog_layer.add_child(panel)
                
                var margin = MarginContainer.new()
                margin.set_anchors_preset(Control.PRESET_FULL_RECT)
                margin.add_theme_constant_override("margin_left", 30)
                margin.add_theme_constant_override("margin_right", 30)
                margin.add_theme_constant_override("margin_top", 20)
                margin.add_theme_constant_override("margin_bottom", 20)
                panel.add_child(margin)
                
                var vbox = VBoxContainer.new()
                vbox.add_theme_constant_override("separation", 20)
                margin.add_child(vbox)
                
                # Title
                var title = Label.new()
                title.text = "🔥 ÖLFELD-BRAND! 🔥"
                title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                title.add_theme_font_size_override("font_size", 36)
                title.add_theme_color_override("font_color", Color(1, 0.3, 0))
                vbox.add_child(title)
                
                # Region info
                var info = Label.new()
                info.text = "REGION: " + fire_data.get("region", "???")
                info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                info.add_theme_font_size_override("font_size", 24)
                info.add_theme_color_override("font_color", Color.YELLOW)
                vbox.add_child(info)
                
                # Description
                var desc = Label.new()
                desc.text = fire_data.get("event_text", "Ein Ölfield brennt!")
                desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
                desc.add_theme_font_size_override("font_size", 18)
                desc.autowrap_mode = TextServer.AUTOWRAP_WORD
                vbox.add_child(desc)
                
                # Spacer
                var spacer = Control.new()
                spacer.custom_minimum_size.y = 20
                vbox.add_child(spacer)
                
                # Option buttons
                var btn_vbox = VBoxContainer.new()
                btn_vbox.add_theme_constant_override("separation", 15)
                vbox.add_child(btn_vbox)
                
                # Option 1: Play mini-game
                var btn_play = Button.new()
                btn_play.text = "SELBST LÖSCHEN (Mini-Game)\nKostet 1 Monat Zeit"
                btn_play.custom_minimum_size.y = 60
                btn_play.add_theme_font_size_override("font_size", 20)
                btn_play.pressed.connect(func():
                                fire_dialog_layer.queue_free()
                                GameManager.start_firefighter_minigame()
                )
                btn_vbox.add_child(btn_play)
                
                # Option 2: Hire Ted Redhair
                var btn_ted = Button.new()
                var ted_cost = int(GameManager.TED_REDHAIR_COST * GameManager.inflation_rate)
                btn_ted.text = "TED REDHAIR ANHEUERN\n$" + _fmt(ted_cost) + " (100% Erfolg)"
                btn_ted.custom_minimum_size.y = 60
                btn_ted.add_theme_font_size_override("font_size", 20)
                btn_ted.disabled = GameManager.cash < ted_cost
                btn_ted.pressed.connect(func():
                                var result = GameManager.hire_ted_redhair()
                                fire_dialog_layer.queue_free()
                                FeedbackOverlay.show_msg(result.message, Color.GREEN if result.success else Color.RED)
                )
                btn_vbox.add_child(btn_ted)
                
                # Option 3: Ignore
                var btn_ignore = Button.new()
                btn_ignore.text = "IGNORIEREN\nFeld 6 Monate ausgefallen"
                btn_ignore.custom_minimum_size.y = 60
                btn_ignore.add_theme_font_size_override("font_size", 20)
                btn_ignore.modulate = Color(1, 0.5, 0.5)
                btn_ignore.pressed.connect(func():
                                GameManager.ignore_fire()
                                fire_dialog_layer.queue_free()
                )
                btn_vbox.add_child(btn_ignore)

# --- TOOLTIPS ---
func setup_tooltips():
                tooltip_panel = PanelContainer.new()
                tooltip_panel.visible = false
                tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
                tooltip_panel.z_index = 100
                var style = StyleBoxFlat.new()
                style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
                style.border_color = Color.WHITE
                style.border_width_bottom=1; style.border_width_top=1; style.border_width_left=1; style.border_width_right=1
                tooltip_panel.add_theme_stylebox_override("panel", style)
                tooltip_label = Label.new()
                tooltip_panel.add_child(tooltip_label)
                add_child(tooltip_panel)
                
                _connect_tooltip(btn_computer, "Öl-Terminal")
                _connect_tooltip(btn_map, "Weltkarte / Claims")
                _connect_tooltip(btn_calendar, "Nächster Tag")
                _connect_tooltip(btn_endmonth, "Monat beenden")
                _connect_tooltip(btn_phone, "Telefon (Notrufe & Kredite)")
                _connect_tooltip(btn_briefcase, "Speichern")
                _connect_tooltip(btn_drawer, "Sabotage Dossier")
                _connect_tooltip(btn_newspaper, "Archiv")
                _connect_tooltip(btn_upgrade, "Upgrade")

func _connect_tooltip(node, text):
                node.mouse_entered.connect(func(): _show_tooltip(text, node))
                node.mouse_exited.connect(func(): tooltip_panel.visible = false)

func _show_tooltip(text, node):
                tooltip_label.text = text
                tooltip_panel.visible = true
                var target_pos = node.global_position
                var target_size = node.size
                tooltip_panel.position = Vector2(target_pos.x + target_size.x/2 - tooltip_panel.size.x/2, target_pos.y - 50)

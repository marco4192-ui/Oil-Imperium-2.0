extends Control
# FirefighterMiniGame.gd - Oil field fire fighting mini-game
# Player uses dynamite to extinguish burning oil rigs in a simulated 3D environment

# --- GAME CONFIG ---
const GAME_TIME: float = 45.0  # Seconds to complete
const DYNAMITE_COUNT: int = 5
const RIG_COUNT_MIN: int = 3
const RIG_COUNT_MAX: int = 5
const BASE_DAMAGE: float = 50.0  # Minimum damage if game played
const DAMAGE_PER_RIG: float = 10.0  # Additional damage per burning rig left
const RECOVERY_MONTHS: int = 3  # Minimum months of damage
const RECOVERY_RATE: float = 10.0  # % recovery per month after minimum

# --- GAME STATE ---
var time_remaining: float = GAME_TIME
var dynamite_left: int = DYNAMITE_COUNT
var burning_rigs: Array = []  # Array of rig dictionaries
var extinguished_count: int = 0
var game_active: bool = false
var game_result: Dictionary = {}

# --- PLAYER ---
var player_pos: Vector2 = Vector2(960, 800)  # Screen position
var player_depth: float = 0.5  # 0 = front, 1 = back
var player_speed: float = 300.0
var move_up: bool = false
var move_down: bool = false
var move_left: bool = false
var move_right: bool = false

# --- UI REFERENCES ---
var game_layer: CanvasLayer
var background: ColorRect
var player: Control
var dynamite_indicator: Label
var timer_label: Label
var rigs_container: Control
var message_label: Label

# --- CALLBACK ---
var callback: Callable = Callable()

# --- CALLED FROM GAME MANAGER ---
var region_name: String = ""
var claim_id: String = ""

func _ready():
	_build_ui()
	_start_game()

func _build_ui():
	# Full screen game layer
	game_layer = CanvasLayer.new()
	game_layer.layer = 200
	add_child(game_layer)
	
	# Desert/background
	background = ColorRect.new()
	background.color = Color(0.6, 0.5, 0.3)  # Sandy brown
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_layer.add_child(background)
	
	# Add some depth gradient (simulated horizon)
	var horizon = ColorRect.new()
	horizon.color = Color(0.4, 0.6, 0.8)  # Sky blue
	horizon.set_anchors_preset(Control.PRESET_FULL_RECT)
	horizon.custom_minimum_size.y = 300
	horizon.anchor_bottom = 0.3
	horizon.offset_bottom = 0
	background.add_child(horizon)
	
	# Container for rigs (sorted by depth)
	rigs_container = Control.new()
	rigs_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_layer.add_child(rigs_container)
	
	# Player character
	player = Control.new()
	player.set_anchors_preset(Control.PRESET_CENTER)
	player.custom_minimum_size = Vector2(60, 80)
	player.position = player_pos
	game_layer.add_child(player)
	
	# Draw player (simple figure)
	var player_panel = Panel.new()
	player_panel.custom_minimum_size = Vector2(60, 80)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.8)  # Blue worker suit
	style.border_color = Color(0.1, 0.1, 0.4)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	player_panel.add_theme_stylebox_override("panel", style)
	player.add_child(player_panel)
	
	# Player head
	var head = Panel.new()
	head.custom_minimum_size = Vector2(30, 30)
	head.position = Vector2(15, -25)
	var head_style = StyleBoxFlat.new()
	head_style.bg_color = Color(0.9, 0.7, 0.5)  # Skin tone
	head_style.corner_radius_top_left = 15
	head_style.corner_radius_top_right = 15
	head_style.corner_radius_bottom_right = 15
	head_style.corner_radius_bottom_left = 15
	head.add_theme_stylebox_override("panel", head_style)
	player.add_child(head)
	
	# HUD - Timer
	timer_label = Label.new()
	timer_label.text = "ZEIT: " + str(int(time_remaining))
	timer_label.add_theme_font_size_override("font_size", 32)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	timer_label.position = Vector2(20, 20)
	timer_label.add_theme_constant_override("shadow_offset_x", 2)
	timer_label.add_theme_constant_override("shadow_offset_y", 2)
	game_layer.add_child(timer_label)
	
	# HUD - Dynamite count
	dynamite_indicator = Label.new()
	dynamite_indicator.text = "DYNAMIT: " + str(dynamite_left)
	dynamite_indicator.add_theme_font_size_override("font_size", 28)
	dynamite_indicator.add_theme_color_override("font_color", Color(1, 0.5, 0))
	dynamite_indicator.position = Vector2(20, 60)
	game_layer.add_child(dynamite_indicator)
	
	# HUD - Instructions
	var instructions = Label.new()
	instructions.text = "WASD = Bewegen | LEERTASTE = Dynamit werfen | Rigs löschen!"
	instructions.add_theme_font_size_override("font_size", 20)
	instructions.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	instructions.anchor_left = 0.5
	instructions.position = Vector2(-300, 1040)
	game_layer.add_child(instructions)
	
	# Message label (center of screen)
	message_label = Label.new()
	message_label.text = ""
	message_label.add_theme_font_size_override("font_size", 48)
	message_label.add_theme_color_override("font_color", Color.YELLOW)
	message_label.set_anchors_preset(Control.PRESET_CENTER)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.visible = false
	game_layer.add_child(message_label)

func _start_game():
	# Spawn burning rigs
	var rig_count = randi_range(RIG_COUNT_MIN, RIG_COUNT_MAX)
	
	for i in range(rig_count):
		var rig = {
			"pos": Vector2(randf_range(200, 1720), randf_range(150, 500)),
			"depth": randf_range(0.3, 0.9),  # Distance from player
			"burning": true,
			"extinguished": false,
			"scale": 1.0,
			"control": null
		}
		burning_rigs.append(rig)
		_create_rig_visual(rig, i)
	
	game_active = true

func _create_rig_visual(rig: Dictionary, index: int):
	# Create visual representation of burning rig
	var rig_control = Control.new()
	rig_control.position = rig["pos"]
	
	# Scale based on depth (further = smaller)
	var scale_val = 1.0 - (rig["depth"] * 0.5)
	rig["scale"] = scale_val
	rig_control.scale = Vector2(scale_val, scale_val)
	
	# Oil rig structure (simplified)
	var rig_panel = Panel.new()
	rig_panel.custom_minimum_size = Vector2(80, 120)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.3, 0.3)  # Dark metal
	style.border_color = Color(0.2, 0.2, 0.2)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	rig_panel.add_theme_stylebox_override("panel", style)
	rig_control.add_child(rig_panel)
	
	# Fire effect (animated color rect)
	var fire = ColorRect.new()
	fire.color = Color(1, 0.3, 0)  # Orange fire
	fire.custom_minimum_size = Vector2(60, 80)
	fire.position = Vector2(10, -60)
	rig_control.add_child(fire)
	rig["fire_control"] = fire
	
	# Fire glow
	var glow = ColorRect.new()
	glow.color = Color(1, 0.6, 0, 0.5)  # Yellow glow
	glow.custom_minimum_size = Vector2(100, 100)
	glow.position = Vector2(-10, -80)
	rig_control.add_child(glow)
	rig["glow_control"] = glow
	
	rigs_container.add_child(rig_control)
	rig["control"] = rig_control

func _process(delta):
	if not game_active:
		return
	
	# Update timer
	time_remaining -= delta
	timer_label.text = "ZEIT: " + str(int(time_remaining))
	
	if time_remaining <= 10:
		timer_label.add_theme_color_override("font_color", Color.RED)
	
	# Check time out
	if time_remaining <= 0:
		_end_game(false)
		return
	
	# Player movement
	var move_dir = Vector2.ZERO
	if move_left: move_dir.x -= 1
	if move_right: move_dir.x += 1
	if move_up: move_dir.y -= 1
	if move_down: move_dir.y += 1
	
	# Apply movement (scaled by depth for 3D effect)
	var actual_speed = player_speed * (1.0 - player_depth * 0.3)
	player_pos += move_dir.normalized() * actual_speed * delta
	
	# Clamp player position
	player_pos.x = clamp(player_pos.x, 100, 1820)
	player_pos.y = clamp(player_pos.y, 200, 900)
	
	# Update player visual
	player.position = player_pos
	player.scale = Vector2(1.0 - player_depth * 0.3, 1.0 - player_depth * 0.3)
	
	# Animate fires
	_animate_fires(delta)

func _animate_fires(delta):
	for rig in burning_rigs:
		if rig["burning"] and rig.has("fire_control"):
			var fire = rig["fire_control"]
			# Flicker effect
			var flicker = randf_range(0.8, 1.2)
			fire.color = Color(1, 0.3 + randf() * 0.3, 0)
			fire.scale = Vector2(flicker, flicker * 1.2)
			
			if rig.has("glow_control"):
				rig["glow_control"].color = Color(1, 0.6, 0, 0.3 + randf() * 0.3)

func _input(event):
	if not game_active:
		return
	
	if event is InputEventKey:
		if event.pressed:
			match event.keycode:
				KEY_W, KEY_UP: move_up = true
				KEY_S, KEY_DOWN: move_down = true
				KEY_A, KEY_LEFT: move_left = true
				KEY_D, KEY_RIGHT: move_right = true
				KEY_SPACE: 
					_throw_dynamite()
		else:
			match event.keycode:
				KEY_W, KEY_UP: move_up = false
				KEY_S, KEY_DOWN: move_down = false
				KEY_A, KEY_LEFT: move_left = false
				KEY_D, KEY_RIGHT: move_right = false
				KEY_ESCAPE: _end_game(false)

func _throw_dynamite():
	if dynamite_left <= 0:
		_show_message("KEIN DYNAMIT MEHR!", Color.RED)
		return
	
	dynamite_left -= 1
	dynamite_indicator.text = "DYNAMIT: " + str(dynamite_left)
	
	# Find nearest burning rig
	var nearest_rig = null
	var nearest_dist = INF
	
	for rig in burning_rigs:
		if rig["burning"] and not rig["extinguished"]:
			var dist = player_pos.distance_to(rig["pos"])
			# Account for depth - further rigs need to be closer in screen space
			var depth_adjusted_dist = dist * (1.0 + rig["depth"] * 0.5)
			if depth_adjusted_dist < nearest_dist and depth_adjusted_dist < 300:
				nearest_dist = depth_adjusted_dist
				nearest_rig = rig
	
	if nearest_rig:
		_extinguish_rig(nearest_rig)
	else:
		_show_message("ZU WEIT WEG!", Color.ORANGE)

func _extinguish_rig(rig: Dictionary):
	rig["burning"] = false
	rig["extinguished"] = true
	extinguished_count += 1
	
	# Visual feedback - remove fire
	if rig.has("fire_control"):
		rig["fire_control"].visible = false
	if rig.has("glow_control"):
		rig["glow_control"].visible = false
	
	# Change rig color to show it's extinguished
	if rig.has("control"):
		var panel = rig["control"].get_child(0)
		if panel:
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.5, 0.5, 0.5)  # Greyed out
			style.border_color = Color(0.3, 0.3, 0.3)
			style.border_width_left = 2
			style.border_width_top = 2
			style.border_width_right = 2
			style.border_width_bottom = 2
			panel.add_theme_stylebox_override("panel", style)
	
	_show_message("GELÖSCHT! (" + str(extinguished_count) + "/" + str(burning_rigs.size()) + ")", Color.GREEN)
	
	# Check if all extinguished
	var still_burning = 0
	for r in burning_rigs:
		if r["burning"]:
			still_burning += 1
	
	if still_burning == 0:
		_end_game(true)

func _show_message(text: String, color: Color = Color.YELLOW):
	message_label.text = text
	message_label.add_theme_color_override("font_color", color)
	message_label.visible = true
	
	# Hide after delay
	await get_tree().create_timer(1.0).timeout
	message_label.visible = false

func _end_game(success: bool):
	game_active = false
	
	# Calculate damage
	var burning_left = 0
	for rig in burning_rigs:
		if rig["burning"]:
			burning_left += 1
	
	var damage = BASE_DAMAGE + (burning_left * DAMAGE_PER_RIG)
	damage = min(damage, 100.0)  # Cap at 100%
	
	if success:
		_show_message("ALLE GELÖSCHT!\nSchaden: " + str(int(damage)) + "%", Color.GREEN)
	else:
		if burning_left == burning_rigs.size():
			# Complete failure
			damage = 100.0
			_show_message("FEHLGESCHLAGEN!\nFeld ausgefallen!", Color.RED)
		else:
			_show_message("ZEIT ABGELAUFEN!\nSchaden: " + str(int(damage)) + "%", Color.ORANGE)
	
	# Store result
	game_result = {
		"success": success,
		"damage_percent": damage,
		"rigs_extinguished": extinguished_count,
		"rigs_total": burning_rigs.size(),
		"complete_failure": (burning_left == burning_rigs.size())
	}
	
	# Wait then return
	await get_tree().create_timer(2.0).timeout
	
	# Call callback if set
	if callback.is_valid():
		callback.call(game_result)
	
	# Return to office
	get_tree().change_scene_to_file("res://Office.tscn")

# --- STATIC HELPER FOR GAME MANAGER ---
static func calculate_recovery(damage_percent: float, months_since_fire: int) -> float:
	# Returns the current damage percentage after recovery
	if months_since_fire < RECOVERY_MONTHS:
		return damage_percent
	
	var recovery_months = months_since_fire - RECOVERY_MONTHS
	var recovered = recovery_months * RECOVERY_RATE
	return max(0, damage_percent - recovered)

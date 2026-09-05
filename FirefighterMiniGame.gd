extends Control
# FirefighterMiniGame.gd - brennende Ölfelder persönlich löschen
# Wie im Original von 1988: Seitenansicht eines brennenden Bohrturms.
# Du richtest die Wasserkanone mit der Maus und pumpt Wasser auf die
# Flammenbasis. Schaffst du es nicht vor Ablauf der Zeit, ist das Feld verloren.

# --- SPIELKONFIGURATION ---
const GAME_TIME: float = 60.0
const FIRE_HP_MAX: float = 100.0
const DROPLET_DAMAGE: float = 0.06     # HP pro Wassertropfen-Treffer
const DROPLETS_PER_SECOND: float = 90.0
const WATER_SPEED: float = 1050.0
const WATER_GRAVITY: float = 620.0
const CANNON_POS := Vector2(260, 920)
const TOWER_X: float = 1150.0
const TOWER_BASE_Y: float = 930.0
const TOWER_HEIGHT: float = 560.0
const FLAME_BASE_Y: float = 700.0      # Flamme brennt am Turmfuß

# --- SPIELZUSTAND ---
var time_remaining: float = GAME_TIME
var fire_hp: float = FIRE_HP_MAX
var wind: float = 0.0
var game_active: bool = false
var pumping: bool = false
var droplet_spawn_acc: float = 0.0
var elapsed: float = 0.0
var flame_t: float = 0.0
var finished: bool = false

# Wassertropfen: {pos, vel, life}
var droplets: Array = []
var splash_particles: Array = []  # {pos, vel, life}

# --- UI ---
var hud_time_bar: ProgressBar
var hud_fire_bar: ProgressBar
var hud_wind_label: Label
var message_label: Label
var world: Node2D

# --- VON GAME MANAGER GESETZT ---
var region_name: String = ""
var claim_id = -1

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_world()
	_build_hud()
	game_active = true
	if has_node("/root/GameManager") and get_node("/root/GameManager").sound_manager:
		get_node("/root/GameManager").sound_manager.play_sound("fire_alarm")

# ==============================================================================
# AUFBAU
# ==============================================================================

func _build_world():
	# Himmel (Abendrot)
	var sky = TextureRect.new()
	var grad = Gradient.new()
	grad.colors = PackedColorArray([Color(0.25, 0.08, 0.05), Color(0.75, 0.3, 0.1), Color(0.98, 0.6, 0.25)])
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var gtex = GradientTexture2D.new()
	gtex.gradient = grad
	gtex.fill_from = Vector2(0, 0)
	gtex.fill_to = Vector2(0, 1)
	sky.texture = gtex
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)

	# Welt-Zeichenebene: Turm, Flamme, Wasser, Kanone, Boden
	# (draw-Signal, damit alles über dem Himmel und unter dem HUD liegt)
	world = Node2D.new()
	world.draw.connect(_on_world_draw)
	add_child(world)

func _build_hud():
	# Kopfzeile: Zeit + Feuerintensität + Wind
	var top = HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 16
	top.offset_bottom = 84
	top.add_theme_constant_override("separation", 24)
	add_child(top)

	var time_box = VBoxContainer.new()
	time_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(time_box)
	var lbl_time = Label.new()
	lbl_time.text = "ZEIT"
	lbl_time.add_theme_font_size_override("font_size", 16)
	time_box.add_child(lbl_time)
	hud_time_bar = _make_bar(Color(0.3, 0.7, 1.0))
	time_box.add_child(hud_time_bar)

	var fire_box = VBoxContainer.new()
	fire_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(fire_box)
	var lbl_fire = Label.new()
	lbl_fire.text = "FEUER-INTENSITÄT"
	lbl_fire.add_theme_font_size_override("font_size", 16)
	fire_box.add_child(lbl_fire)
	hud_fire_bar = _make_bar(Color(1.0, 0.35, 0.1))
	fire_box.add_child(hud_fire_bar)

	var wind_box = VBoxContainer.new()
	wind_box.custom_minimum_size.x = 240
	top.add_child(wind_box)
	var lbl_wind = Label.new()
	lbl_wind.text = "WIND"
	lbl_wind.add_theme_font_size_override("font_size", 16)
	wind_box.add_child(lbl_wind)
	hud_wind_label = Label.new()
	hud_wind_label.text = "→ 0"
	hud_wind_label.add_theme_font_size_override("font_size", 22)
	wind_box.add_child(hud_wind_label)

	# Anleitung / Ergebnis
	message_label = Label.new()
	message_label.anchor_left = 0.5; message_label.anchor_right = 0.5
	message_label.anchor_top = 0.5; message_label.anchor_bottom = 0.5
	message_label.offset_left = -520; message_label.offset_right = 520
	message_label.offset_top = -200; message_label.offset_bottom = -100
	message_label.text = "ÖLFELD STEHT IN FLAMMEN!\n\nMaus = Kanone richten, LINKSKLICK halten (oder LEERTASTE) = Wasser pumpen\nLösche die Flamme an der Basis, bevor die Zeit abläuft!\nESC = aufgeben (Feld verloren)"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 22)
	message_label.add_theme_color_override("font_color", Color(1, 1, 1))
	message_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	message_label.add_theme_constant_override("shadow_offset_x", 2)
	message_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(message_label)

	var tween = create_tween()
	tween.tween_interval(5.0)
	tween.tween_property(message_label, "modulate:a", 0.0, 1.0)

func _make_bar(col: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 26)
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.set_corner_radius_all(6)
	var fill = StyleBoxFlat.new()
	fill.bg_color = col
	fill.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

# ==============================================================================
# SPIELLOGIK
# ==============================================================================

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pumping = event.pressed
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE and game_active:
			_end_game(false, true)
		elif event.keycode == KEY_SPACE:
			pumping = true
	elif event is InputEventKey and not event.pressed and event.keycode == KEY_SPACE:
		pumping = false

func _process(delta):
	if not game_active:
		return

	elapsed += delta
	flame_t += delta
	time_remaining -= delta

	# Wind oszilliert
	wind = sin(elapsed * 0.35) * 0.65 + sin(elapsed * 0.13 + 1.7) * 0.35
	if hud_wind_label:
		var dir = "→" if wind >= 0.0 else "←"
		hud_wind_label.text = "%s %d" % [dir, int(abs(wind) * 10)]

	# Wasser pumpen
	if pumping:
		droplet_spawn_acc += DROPLETS_PER_SECOND * delta
		while droplet_spawn_acc >= 1.0:
			droplet_spawn_acc -= 1.0
			_spawn_droplet()

	_update_droplets(delta)
	_update_splash(delta)

	# HUD
	if hud_time_bar:
		hud_time_bar.value = time_remaining / GAME_TIME * 100.0
	if hud_fire_bar:
		hud_fire_bar.value = fire_hp / FIRE_HP_MAX * 100.0

	if fire_hp <= 0.0:
		_end_game(true)
	elif time_remaining <= 0.0:
		_end_game(false)

	if world:
		world.queue_redraw()

func _aim_direction() -> Vector2:
	var mouse = get_global_mouse_position()
	var dir = mouse - CANNON_POS
	if dir.length() < 10.0:
		return Vector2.RIGHT
	return dir.normalized()

func _spawn_droplet():
	var dir = _aim_direction()
	dir = dir.rotated(randf_range(-0.035, 0.035))
	var speed = WATER_SPEED * randf_range(0.92, 1.08)
	droplets.append({
		"pos": CANNON_POS + dir * 60.0,
		"vel": dir * speed,
		"life": 3.0
	})

func _flame_rect() -> Rect2:
	# Trefferzone der Flamme (schrumpft mit sinkendem HP)
	var hp_frac = clamp(fire_hp / FIRE_HP_MAX, 0.0, 1.0)
	var flame_height = 90.0 + 420.0 * hp_frac
	var flame_width = 40.0 + 110.0 * hp_frac
	var lean = wind * 90.0 * hp_frac
	var base_x = TOWER_X + lean
	return Rect2(base_x - flame_width * 0.5, FLAME_BASE_Y - flame_height, flame_width, flame_height)

func _update_droplets(delta):
	var flame = _flame_rect()
	var to_kill: Array = []
	for i in range(droplets.size()):
		var d = droplets[i]
		d["vel"].y += WATER_GRAVITY * delta
		d["vel"].x += wind * 26.0 * delta
		d["pos"] += d["vel"] * delta
		d["life"] -= delta

		if flame.has_point(d["pos"]):
			# Treffer: Feuer kühlen, Dampf erzeugen
			fire_hp -= DROPLET_DAMAGE
			to_kill.append(i)
			if splash_particles.size() < 220 and randf() < 0.5:
				splash_particles.append({
					"pos": d["pos"],
					"vel": Vector2(randf_range(-90, 90), randf_range(-260, -80)),
					"life": randf_range(0.3, 0.7)
				})
			continue

		if d["pos"].y > TOWER_BASE_Y - 6.0:
			to_kill.append(i)
			continue
		if d["life"] <= 0.0:
			to_kill.append(i)

	for i in range(to_kill.size() - 1, -1, -1):
		droplets.remove_at(to_kill[i])

func _update_splash(delta):
	var to_kill: Array = []
	for i in range(splash_particles.size()):
		var p = splash_particles[i]
		p["vel"].y += 300.0 * delta
		p["vel"] *= 0.97
		p["pos"] += p["vel"] * delta
		p["life"] -= delta
		if p["life"] <= 0.0:
			to_kill.append(i)
	for i in range(to_kill.size() - 1, -1, -1):
		splash_particles.remove_at(to_kill[i])

# ==============================================================================
# ZEICHNEN (im draw-Signal des World-Knotens, siehe _build_world)
# ==============================================================================

func _on_world_draw():
	_draw_ground()
	_draw_tower()
	_draw_cannon()
	_draw_flame()
	_draw_water()

func _draw_ground():
	# Sandboden
	var w = get_viewport_rect().size.x
	world.draw_rect(Rect2(0, TOWER_BASE_Y - 10, w, get_viewport_rect().size.y), Color(0.2, 0.14, 0.09))
	world.draw_rect(Rect2(0, TOWER_BASE_Y - 10, w, 8), Color(0.3, 0.21, 0.13))

func _draw_tower():
	# Bohrturm als Stahlfachwerk (Silhouette)
	var dark = Color(0.09, 0.07, 0.06)
	var x = TOWER_X
	var base_y = TOWER_BASE_Y
	var top_y = base_y - TOWER_HEIGHT
	var half_base = 120.0
	var half_top = 34.0

	# Beine
	world.draw_line(Vector2(x - half_base, base_y), Vector2(x - half_top, top_y), dark, 14.0)
	world.draw_line(Vector2(x + half_base, base_y), Vector2(x + half_top, top_y), dark, 14.0)
	# Querstege + Diagonalen
	var steps = 6
	for i in range(steps + 1):
		var f = float(i) / steps
		var y = base_y + (top_y - base_y) * f
		var half = half_base + (half_top - half_base) * f
		world.draw_line(Vector2(x - half, y), Vector2(x + half, y), dark, 8.0)
		if i > 0:
			var f_prev = float(i - 1) / steps
			var y_prev = base_y + (top_y - base_y) * f_prev
			var half_prev = half_base + (half_top - half_base) * f_prev
			world.draw_line(Vector2(x - half_prev, y_prev), Vector2(x + half, y), dark, 5.0)
			world.draw_line(Vector2(x + half_prev, y_prev), Vector2(x - half, y), dark, 5.0)
	# Krone + Blockhaus + Ventil
	world.draw_rect(Rect2(x - half_top - 12, top_y - 26, (half_top + 12) * 2, 26), dark)
	world.draw_rect(Rect2(x - 170, base_y - 110, 150, 110), Color(0.13, 0.1, 0.08))
	world.draw_rect(Rect2(x - 155, base_y - 92, 30, 40), Color(0.3, 0.22, 0.14))

func _draw_cannon():
	var base_col = Color(0.85, 0.25, 0.12)
	# Anhänger
	world.draw_rect(Rect2(CANNON_POS.x - 70, CANNON_POS.y - 46, 140, 26), base_col)
	# Räder
	world.draw_circle(Vector2(CANNON_POS.x - 44, CANNON_POS.y - 22), 20, Color(0.12, 0.12, 0.12))
	world.draw_circle(Vector2(CANNON_POS.x + 44, CANNON_POS.y - 22), 20, Color(0.12, 0.12, 0.12))
	world.draw_circle(Vector2(CANNON_POS.x - 44, CANNON_POS.y - 22), 8, Color(0.5, 0.5, 0.5))
	world.draw_circle(Vector2(CANNON_POS.x + 44, CANNON_POS.y - 22), 8, Color(0.5, 0.5, 0.5))
	# Rohr in Zielrichtung
	var dir = _aim_direction()
	var barrel_len = 78.0
	var tip = CANNON_POS + dir * barrel_len + Vector2(0, -50)
	var back = CANNON_POS + Vector2(0, -50)
	world.draw_line(back, tip, Color(0.2, 0.2, 0.22), 16.0)
	world.draw_circle(tip, 11.0, Color(0.15, 0.15, 0.17))
	# Ziel-Strichel
	if game_active:
		var aim_end = CANNON_POS + _aim_direction() * 900.0 + Vector2(0, -50)
		for i in range(1, 6):
			var p = (CANNON_POS + Vector2(0, -50)).lerp(aim_end, i / 6.0)
			world.draw_circle(p, 3.0, Color(1, 1, 1, 0.28))

func _draw_flame():
	if fire_hp <= 0.0:
		return
	var hp_frac = clamp(fire_hp / FIRE_HP_MAX, 0.0, 1.0)
	var flame_height = 90.0 + 420.0 * hp_frac
	var flame_width = 40.0 + 110.0 * hp_frac
	var lean = wind * 90.0 * hp_frac

	# flackernde Pulsation
	var flicker = sin(flame_t * 9.0) * 0.06 + sin(flame_t * 17.0 + 1.3) * 0.04
	flame_height *= 1.0 + flicker

	var base_x = TOWER_X + lean
	var base_y = FLAME_BASE_Y + 14

	# Glow
	world.draw_circle(Vector2(base_x, base_y - flame_height * 0.35), flame_width * 2.6, Color(1.0, 0.5, 0.1, 0.10))

	# drei Flammenschichten (außen -> innen)
	var layers = [
		{"w": 1.0, "h": 1.0, "col": Color(1.0, 0.42, 0.05, 0.95)},
		{"w": 0.66, "h": 0.74, "col": Color(1.0, 0.68, 0.1, 0.95)},
		{"w": 0.36, "h": 0.46, "col": Color(1.0, 0.95, 0.6, 0.98)},
	]
	for layer in layers:
		var pts = PackedVector2Array()
		var w = flame_width * layer["w"]
		var h = flame_height * layer["h"]
		var segs = 14
		# Linke Kante von unten nach oben; gleiche Sway-Kurve fuer beide Kanten,
		# damit sich das Polygon nie selbst schneidet (Sonst kollabiert die Triangulierung).
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for i in range(segs + 1):
			var f = float(i) / segs
			var y = base_y - h * f
			var taper = max(sin(f * PI) * (1.0 - f * 0.55), 0.0)
			var sway = sin(flame_t * 6.0 + f * 5.0) * 14.0 * f + lean * 0.25 * f
			left.append(Vector2(base_x + sway - w * taper * 0.5, y))
			right.append(Vector2(base_x + sway + w * taper * 0.5, y))
		pts.append_array(left)
		for i in range(right.size() - 1, -1, -1):
			pts.append(right[i])
		world.draw_colored_polygon(pts, layer["col"])

	# Rauch
	var smoke_count = int(6 * hp_frac) + 2
	for i in range(smoke_count):
		var t = flame_t * 0.5 + i * 1.7
		var f = fmod(t, 3.0) / 3.0
		var sx = base_x + sin(t * 2.0) * 30.0 + wind * 180.0 * f
		var sy = base_y - flame_height - f * 260.0
		var r = 20.0 + f * 60.0
		world.draw_circle(Vector2(sx, sy), r, Color(0.15, 0.13, 0.12, 0.30 * (1.0 - f)))

	# Funken
	for i in range(5):
		var t = flame_t * 1.4 + i * 2.4
		var f = fmod(t, 1.6) / 1.6
		var ex = base_x + sin(t * 3.1) * 40.0 + wind * 300.0 * f
		var ey = base_y - flame_height * 0.9 - f * 320.0
		world.draw_circle(Vector2(ex, ey), 3.5 - f * 2.0, Color(1.0, 0.6, 0.2, 1.0 - f))

func _draw_water():
	# Wassertropfen
	for d in droplets:
		world.draw_circle(d["pos"], 5.0, Color(0.45, 0.72, 1.0, 0.95))
		world.draw_circle(d["pos"] + Vector2(0, 4), 3.4, Color(0.6, 0.82, 1.0, 0.55))
	# Dampf/Splash
	for p in splash_particles:
		var a = clamp(p["life"] / 0.7, 0.0, 1.0)
		world.draw_circle(p["pos"], 6.0 + (0.7 - p["life"]) * 14.0, Color(0.9, 0.95, 1.0, 0.4 * a))

# ==============================================================================
# ENDE
# ==============================================================================

func _end_game(success: bool, aborted: bool = false):
	if finished:
		return
	finished = true
	game_active = false
	pumping = false

	var damage: float
	var complete_failure := false

	if success:
		# Gelöscht: Restschaden abhängig von der benötigten Zeit
		damage = clamp(15.0 + (GAME_TIME - time_remaining) * 0.5, 15.0, 60.0)
		message_label.text = "GELÖSCHT!\nDas Ölfeld ist gerettet (Schaden: %d%%)" % int(damage)
		message_label.modulate = Color(0.4, 1.0, 0.4)
		if has_node("/root/GameManager") and get_node("/root/GameManager").sound_manager:
			get_node("/root/GameManager").sound_manager.play_sound("achievement")
	else:
		if aborted or fire_hp > FIRE_HP_MAX * 0.6:
			complete_failure = true
			damage = 100.0
			message_label.text = "FELD VERLOREN!\nDie Bohrstelle ist zerstört und muss neu gebohrt werden."
		else:
			damage = 70.0
			message_label.text = "NUR TEILWEISE GELÖSCHT\nSchaden: 70% — Förderung stark eingeschränkt"
		message_label.modulate = Color(1.0, 0.4, 0.3) if complete_failure else Color(1.0, 0.7, 0.2)
		if has_node("/root/GameManager") and get_node("/root/GameManager").sound_manager:
			get_node("/root/GameManager").sound_manager.play_sound("game_over")
	message_label.modulate.a = 1.0

	# Ergebnis anwenden (vorher ging das Ergebnis verloren — Feuer hatte keine Folgen)
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		if region_name != "":
			gm._apply_fire_damage(region_name, claim_id, damage, complete_failure)
		if not gm.pending_fire_event.is_empty():
			gm.pending_fire_event.clear()
		if "show_fire_options" in gm:
			gm.show_fire_options = false
		if has_node("/root/FeedbackOverlay"):
			get_node("/root/FeedbackOverlay").show_msg(message_label.text, Color(0.4, 1.0, 0.4) if success else Color(1.0, 0.5, 0.3))

	# Zurück ins Büro
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://Office.tscn")

extends Control
# FirefighterMiniGame.gd - Ölfeldbrände per Dynamit löschen (wie im Original von 1988)
# Eine Karte mit brennenden Bohrtürmen. Ted Redhair läuft per WASD/Pfeiltasten
# über das Gelände, mit LEERTASTE legt er Dynamit. Der Druckluft-Sog der
# Explosion erstickt die Flammen - aber wer zu nah steht, stirbt und alle
# Türme brennen ab. Je schneller ein Turm gelöscht ist, desto geringer der Schaden.

# --- SPIELKONFIGURATION ---
const GAME_TIME: float = 75.0
const TOWER_COUNT: int = 5
const DAMAGE_PER_SECOND: float = 0.9   # Schaden pro Turm, solange er brennt
const EXPLOSION_DAMAGE: float = 8.0    # Zusatzschaden pro Sprengung
const FUSE_TIME: float = 2.2           # Brennzeit des Dynamits
const BLAST_RADIUS: float = 230.0      # Löschradius der Explosion
const KILL_RADIUS: float = 165.0       # Wer hier steht, stirbt
const MAX_ACTIVE_CHARGES: int = 2
const TED_SPEED: float = 310.0
const TOWER_KEEP_OUT: float = 85.0     # Ted kann nicht durch Türme laufen

# --- KARTE (Design 1920x1080) ---
const MAP_RECT := Rect2(90, 130, 1740, 860)

# --- SPIELZUSTAND ---
var time_remaining: float = GAME_TIME
var game_active: bool = false
var finished: bool = false
var elapsed: float = 0.0
var ted_dead: bool = false

var towers: Array = []        # {pos, hp, damage, burning, main}
var charges: Array = []       # {pos, fuse}
var booms: Array = []         # {pos, age, radius}
var ted_pos := Vector2(300, 900)
var move_vec := Vector2.ZERO
var shake: float = 0.0

# --- UI ---
var hud_time_bar: ProgressBar
var message_label: Label
var hud_tower_label: Label

# --- VON GAME MANAGER GESETZT ---
var region_name: String = ""
var claim_id = -1

func _ready():
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_setup_towers()
	_build_hud()
	game_active = true
	if has_node("/root/GameManager") and get_node("/root/GameManager").sound_manager:
		get_node("/root/GameManager").sound_manager.play_sound("fire_alarm")

func _setup_towers():
	# Feste, gut verteilte Positionen mit leichtem Zufall (Design 1920x1080)
	var spots := [
		Vector2(360, 340), Vector2(950, 260), Vector2(1560, 380),
		Vector2(620, 800), Vector2(1330, 780),
	]
	spots.shuffle()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(Time.get_unix_time_from_system())
	for i in range(TOWER_COUNT):
		var pos: Vector2 = spots[i] + Vector2(rng.randf_range(-40, 40), rng.randf_range(-30, 30))
		towers.append({
			"pos": pos,
			"hp": 100.0,
			"damage": 0.0,
			"burning": true,
			"main": (i == 0),
			"flicker": rng.randf_range(0.0, 10.0),
		})
	# Ted startet frei von Türmen
	ted_pos = Vector2(240, 930)
	for t in towers:
		if ted_pos.distance_to(t["pos"]) < 260.0:
			ted_pos = Vector2(240, 620)
			break

# ==============================================================================
# HUD
# ==============================================================================

func _build_hud():
	var top = HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 14
	top.offset_bottom = 76
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

	var tw_box = VBoxContainer.new()
	tw_box.custom_minimum_size.x = 430
	top.add_child(tw_box)
	hud_tower_label = Label.new()
	hud_tower_label.text = "BRÄNDE: %d/%d" % [TOWER_COUNT, TOWER_COUNT]
	hud_tower_label.add_theme_font_size_override("font_size", 20)
	tw_box.add_child(hud_tower_label)

	message_label = Label.new()
	message_label.anchor_left = 0.5; message_label.anchor_right = 0.5
	message_label.offset_left = -560; message_label.offset_right = 560
	message_label.offset_top = 90; message_label.offset_bottom = 210
	message_label.text = "ÖLFELD IN FLAMMEN — SPRENGUNG LÖSCHT DAS FEUER!\n\nWASD / PFEILTASTEN = laufen   |   LEERTASTE = Dynamit legen\nRenn nach dem Legen sofort weg — die Explosion tötet dich!\nJe schneller ein Turm gelöscht ist, desto geringer der Schaden."
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 21)
	message_label.add_theme_color_override("font_color", Color(1, 1, 1))
	message_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	message_label.add_theme_constant_override("shadow_offset_x", 2)
	message_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(message_label)
	var tween = create_tween()
	tween.tween_interval(5.5)
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
# EINGABE & LOGIK
# ==============================================================================

func _input(event):
	if not game_active:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				_end_game(false, true)
			KEY_SPACE:
				_place_dynamite()
	if event is InputEventKey:
		var v := Vector2.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): v.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): v.y += 1
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): v.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): v.x += 1
		move_vec = v.normalized() if v.length() > 0 else Vector2.ZERO

func _process(delta):
	if not game_active:
		return

	elapsed += delta
	time_remaining -= delta
	shake = max(0.0, shake - delta * 30.0)

	# Ted bewegen (mit Kollision an Türmen und Kartenrand)
	if not ted_dead:
		var next = ted_pos + move_vec * TED_SPEED * delta
		next.x = clamp(next.x, MAP_RECT.position.x + 20, MAP_RECT.end.x - 20)
		next.y = clamp(next.y, MAP_RECT.position.y + 20, MAP_RECT.end.y - 20)
		for t in towers:
			var base: Vector2 = t["pos"] + Vector2(0, 30)
			if next.distance_to(base) < TOWER_KEEP_OUT:
				next = ted_pos
				break
		ted_pos = next

	# Brände fressen Lebensenergie
	for t in towers:
		if t["burning"]:
			t["damage"] = min(100.0, t["damage"] + DAMAGE_PER_SECOND * delta)

	# Zünder ticken
	var to_detonate: Array = []
	for c in charges:
		c["fuse"] -= delta
		if c["fuse"] <= 0.0:
			to_detonate.append(c)
	for c in to_detonate:
		charges.erase(c)
		_detonate(c["pos"])

	if hud_time_bar:
		hud_time_bar.value = time_remaining / GAME_TIME * 100.0
	if hud_tower_label:
		var out = 0
		for t in towers:
			if not t["burning"]:
				out += 1
		hud_tower_label.text = "BRÄNDE: %d/%d gelöscht" % [out, TOWER_COUNT]

	queue_redraw()

	if _all_out():
		_end_game(true)
	elif time_remaining <= 0.0:
		_end_game(false)

func _all_out() -> bool:
	for t in towers:
		if t["burning"]:
			return false
	return true

func _main_tower() -> Dictionary:
	for t in towers:
		if t["main"]:
			return t
	return towers[0] if towers.size() > 0 else {}

func _place_dynamite():
	if ted_dead:
		return
	if charges.size() >= MAX_ACTIVE_CHARGES:
		return
	charges.append({"pos": ted_pos + Vector2(0, 6), "fuse": FUSE_TIME})
	if has_node("/root/GameManager") and get_node("/root/GameManager").sound_manager:
		get_node("/root/GameManager").sound_manager.play_sound("ui_click")

func _detonate(pos: Vector2):
	booms.append({"pos": pos, "age": 0.0, "radius": BLAST_RADIUS})
	shake = 14.0
	if has_node("/root/GameManager") and get_node("/root/GameManager").sound_manager:
		get_node("/root/GameManager").sound_manager.play_sound("explosion")

	# Flammen im Löschradius ersticken (plötzlicher Sauerstoff-Entzug)
	for t in towers:
		if t["burning"] and (t["pos"] + Vector2(0, -20)).distance_to(pos) <= BLAST_RADIUS:
			t["burning"] = false
			t["hp"] = max(0.0, t["hp"] - 5.0)
			t["damage"] = min(100.0, t["damage"] + EXPLOSION_DAMAGE)

	# Zu nah dran? Ted stirbt -> alle Türme brennen ab
	if not ted_dead and ted_pos.distance_to(pos) <= KILL_RADIUS:
		ted_dead = true
		for t in towers:
			t["burning"] = true
			t["damage"] = 100.0
		if has_node("/root/FeedbackOverlay"):
			get_node("/root/FeedbackOverlay").show_msg("TED IST GESTORBEN!\nAlle Türme sind abgebrannt!", Color(1.0, 0.2, 0.1))

# ==============================================================================
# ZEICHNEN (alles im Wurzel-Control, HUD liegt als Kind darüber)
# ==============================================================================

func _draw():
	var ox = 0.0
	var oy = 0.0
	if shake > 0.0:
		ox = randf_range(-shake, shake)
		oy = randf_range(-shake, shake)
	draw_set_transform(Vector2(ox, oy), 0.0, Vector2.ONE)

	_draw_ground()
	for t in towers:
		_draw_tower(t)
	_draw_charges()
	_draw_booms()
	if not ted_dead:
		_draw_ted()
	elif shake > 0.0 or elapsed < 3.0:
		_draw_ted_ghost()

func _draw_ground():
	# Sandboden mit Flecken
	draw_rect(MAP_RECT, Color(0.76, 0.62, 0.4))
	draw_rect(Rect2(MAP_RECT.position, Vector2(MAP_RECT.size.x, 10)), Color(0.6, 0.47, 0.3))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	for i in range(60):
		var p = Vector2(rng.randf_range(MAP_RECT.position.x, MAP_RECT.end.x), rng.randf_range(MAP_RECT.position.y, MAP_RECT.end.y))
		var r = rng.randf_range(6.0, 18.0)
		var shade = rng.randf_range(0.0, 1.0)
		draw_circle(p, r, Color(0.72 - shade * 0.05, 0.58 - shade * 0.04, 0.36 - shade * 0.03, 0.35))
	# dunkle Ölflecken unter brennenden Türmen
	for t in towers:
		if t["burning"]:
			draw_circle(t["pos"] + Vector2(0, 34), 46.0, Color(0.12, 0.09, 0.07, 0.55))

func _draw_tower(t: Dictionary):
	var pos: Vector2 = t["pos"]
	var dark = Color(0.16, 0.12, 0.09)
	var x = pos.x
	var base_y = pos.y + 30
	var top_y = pos.y - 110
	var half_base = 42.0
	var half_top = 14.0
	# Beine + Querstreben
	draw_line(Vector2(x - half_base, base_y), Vector2(x - half_top, top_y), dark, 7.0)
	draw_line(Vector2(x + half_base, base_y), Vector2(x + half_top, top_y), dark, 7.0)
	for i in range(4):
		var f = float(i + 1) / 4.0
		var y = base_y + (top_y - base_y) * f
		var half = half_base + (half_top - half_base) * f
		draw_line(Vector2(x - half, y), Vector2(x + half, y), dark, 4.0)
	# Krone
	draw_rect(Rect2(x - half_top - 6, top_y - 12, (half_top + 6) * 2, 12), dark)
	# Lebensenergie-Balken über dem Turm
	var bar_w = 90.0
	var frac = clamp(1.0 - t["damage"] / 100.0, 0.0, 1.0)
	draw_rect(Rect2(x - bar_w / 2 - 1, pos.y - 152, bar_w + 2, 10), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(x - bar_w / 2, pos.y - 151, bar_w * frac, 8),
			Color(0.9 - frac * 0.6, 0.15 + frac * 0.6, 0.1))
	if t["main"]:
		draw_circle(Vector2(x, pos.y - 165), 6.0, Color(0.2, 0.9, 0.4))
	# Flamme
	if t["burning"]:
		_draw_flame(Vector2(x, top_y - 8), 46.0, 80.0, t["flicker"])

func _draw_flame(base: Vector2, w: float, h: float, seed_t: float):
	var flicker = sin((elapsed + seed_t) * 9.0) * 0.07 + sin((elapsed + seed_t) * 15.0 + 1.1) * 0.05
	h *= 1.0 + flicker
	var layers = [
		{"w": 1.0, "h": 1.0, "col": Color(1.0, 0.42, 0.05, 0.95)},
		{"w": 0.62, "h": 0.72, "col": Color(1.0, 0.68, 0.1, 0.95)},
		{"w": 0.32, "h": 0.44, "col": Color(1.0, 0.95, 0.6, 0.98)},
	]
	for layer in layers:
		var pts = PackedVector2Array()
		var lw = w * layer["w"]
		var lh = h * layer["h"]
		var segs = 10
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for i in range(segs + 1):
			var f = float(i) / segs
			var y = base.y - lh * f
			var taper = max(sin(f * PI) * (1.0 - f * 0.5), 0.0)
			var sway = sin((elapsed + seed_t) * 5.0 + f * 4.0) * 6.0 * f
			left.append(Vector2(base.x + sway - lw * taper * 0.5, y))
			right.append(Vector2(base.x + sway + lw * taper * 0.5, y))
		pts.append_array(left)
		for i in range(right.size() - 1, -1, -1):
			pts.append(right[i])
		draw_colored_polygon(pts, layer["col"])
	# Rauchfaden
	for i in range(3):
		var t = elapsed * 0.5 + i * 1.9 + seed_t
		var f = fmod(t, 2.4) / 2.4
		var sx = base.x + sin(t * 2.0) * 12.0
		var sy = base.y - h - f * 160.0
		draw_circle(Vector2(sx, sy), 10.0 + f * 26.0, Color(0.15, 0.13, 0.12, 0.3 * (1.0 - f)))

func _draw_charges():
	for c in charges:
		# Dynamit-Bündel
		draw_rect(Rect2(c["pos"].x - 12, c["pos"].y - 7, 24, 14), Color(0.75, 0.2, 0.15))
		draw_rect(Rect2(c["pos"].x - 12, c["pos"].y - 7, 24, 4), Color(0.9, 0.85, 0.7))
		# blinkender Zündpunkt, schneller je näher die Detonation
		var blink = 6.0 + (FUSE_TIME - c["fuse"]) * 14.0
		if fmod(elapsed, 1.0) < 0.5 or blink > 12.0:
			if fmod(elapsed * blink, 1.0) < 0.5:
				draw_circle(c["pos"] + Vector2(0, -10), 4.0, Color(1.0, 0.1, 0.1))
		# Warnkreis (Todeszone)
		draw_arc(c["pos"], KILL_RADIUS, 0, TAU, 48, Color(1.0, 0.1, 0.1, 0.10 + 0.10 * sin(elapsed * 6.0)), 2.0)

func _draw_booms():
	for b in booms:
		b["age"] += 0.016
		var f = clamp(b["age"] / 0.7, 0.0, 1.0)
		var r = BLAST_RADIUS * (0.3 + 0.7 * f)
		draw_arc(b["pos"], r, 0, TAU, 48, Color(1.0, 0.9, 0.5, 1.0 - f), 8.0 * (1.0 - f) + 1.0)
		draw_circle(b["pos"], 40.0 * (1.0 - f) + 10.0, Color(1.0, 0.75, 0.25, 0.5 * (1.0 - f)))
		for i in range(6):
			var a = f * 6.0 + float(i) * 1.05
			var p = b["pos"] + Vector2(cos(a), sin(a)) * r * 0.8
			draw_circle(p, 14.0 * (1.0 - f), Color(0.2, 0.18, 0.16, 0.5 * (1.0 - f)))

func _draw_ted():
	# Ted Redhair: kleine Figur mit rotem Haar
	var p = ted_pos
	var bob = 0.0 if move_vec == Vector2.ZERO else sin(elapsed * 12.0) * 2.0
	# Schatten
	draw_circle(p + Vector2(0, 14), 11.0, Color(0, 0, 0, 0.3))
	# Körper
	draw_rect(Rect2(p.x - 7, p.y - 6 + bob, 14, 16), Color(0.85, 0.85, 0.9))
	# Kopf
	draw_circle(p + Vector2(0, -12 + bob), 8.0, Color(0.95, 0.78, 0.62))
	# rotes Haar
	draw_circle(p + Vector2(0, -16 + bob), 7.5, Color(0.85, 0.25, 0.1))
	# Zielkreis um Ted (Positionsmarke)
	draw_arc(p + Vector2(0, 6), 20.0, 0, TAU, 24, Color(1, 1, 1, 0.35), 2.0)

func _draw_ted_ghost():
	# Überbleibsel nach Teds Tod
	var p = ted_pos
	draw_circle(p + Vector2(0, 8), 12.0, Color(0.1, 0.1, 0.1, 0.7))
	draw_circle(p + Vector2(0, -8), 6.0, Color(0.5, 0.15, 0.05, 0.7))

# ==============================================================================
# ENDE
# ==============================================================================

func _end_game(success: bool, aborted: bool = false):
	if finished:
		return
	finished = true
	game_active = false

	var main = _main_tower()
	var damage: float
	var complete_failure := false

	if ted_dead:
		complete_failure = true
		damage = 100.0
		message_label.text = "TED GESTORBEN — ALLE TÜRME VERBRANNT!\nDie Bohrstelle ist zerstört und muss neu gebohrt werden."
		message_label.modulate = Color(1.0, 0.3, 0.2)
	elif success:
		# Durchschnittsschaden der gelöschten Türme + Explosionsrest
		var avg = 0.0
		for t in towers:
			avg += t["damage"]
		avg /= max(1.0, float(towers.size()))
		damage = clamp(avg + 10.0, 15.0, 60.0)
		message_label.text = "ALLE BRÄNDE GELÖSCHT!\nGesamtschaden: %d%%" % int(damage)
		message_label.modulate = Color(0.4, 1.0, 0.4)
		if has_node("/root/GameManager") and get_node("/root/GameManager").sound_manager:
			get_node("/root/GameManager").sound_manager.play_sound("achievement")
	else:
		if main.is_empty() or main.get("burning", true):
			complete_failure = true
			damage = 100.0
			message_label.text = "ZEIT ABGELAUFEN — FELD VERLOREN!\nDie Bohrstelle ist zerstört und muss neu gebohrt werden."
			message_label.modulate = Color(1.0, 0.3, 0.2)
		else:
			damage = 70.0
			message_label.text = "ZEIT ABGELAUFEN — NUR TEILGERETTET\nSchaden: 70% — Förderung stark eingeschränkt"
			message_label.modulate = Color(1.0, 0.7, 0.2)
		if has_node("/root/GameManager") and get_node("/root/GameManager").sound_manager:
			get_node("/root/GameManager").sound_manager.play_sound("game_over")
	if aborted and not ted_dead:
		message_label.text = "ABGEBROCHEN — FELD VERLOREN!"
		complete_failure = true
		damage = 100.0
	message_label.modulate.a = 1.0

	# Ergebnis anwenden
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

	await get_tree().create_timer(3.5).timeout
	get_tree().change_scene_to_file("res://Office.tscn")

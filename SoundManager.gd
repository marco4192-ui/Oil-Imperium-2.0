extends Node
# SoundManager.gd - Comprehensive sound effect system
# Handles UI sounds, game events, and era-appropriate audio feedback

# ==============================================================================
# SOUND CATEGORIES
# ==============================================================================

enum SoundCategory {
	UI,
	GAME_EVENT,
	AMBIENT,
	DRILLING,
	SUCCESS,
	FAILURE,
	WARNING,
	SPECIAL
}

# ==============================================================================
# SOUND DEFINITIONS
# ==============================================================================

const SOUNDS = {
	# UI Sounds
	"ui_click": {"path": "res://assets/sounds/ui/click.wav", "category": SoundCategory.UI, "volume_db": -5.0},
	"ui_hover": {"path": "res://assets/sounds/ui/hover.wav", "category": SoundCategory.UI, "volume_db": -8.0},
	"ui_open": {"path": "res://assets/sounds/ui/open.wav", "category": SoundCategory.UI, "volume_db": -5.0},
	"ui_close": {"path": "res://assets/sounds/ui/close.wav", "category": SoundCategory.UI, "volume_db": -5.0},
	"ui_error": {"path": "res://assets/sounds/ui/error.wav", "category": SoundCategory.UI, "volume_db": -3.0},

	# Financial Sounds
	"money_gain": {"path": "res://assets/sounds/money/gain.wav", "category": SoundCategory.SUCCESS, "volume_db": -5.0},
	"money_loss": {"path": "res://assets/sounds/money/loss.wav", "category": SoundCategory.FAILURE, "volume_db": -5.0},
	"contract_sign": {"path": "res://assets/sounds/money/contract.wav", "category": SoundCategory.SUCCESS, "volume_db": -3.0},
	"loan_taken": {"path": "res://assets/sounds/money/loan.wav", "category": SoundCategory.GAME_EVENT, "volume_db": -5.0},

	# Drilling Sounds
	"drill_start": {"path": "res://assets/sounds/drilling/start.wav", "category": SoundCategory.DRILLING, "volume_db": 0.0},
	"drill_success": {"path": "res://assets/sounds/drilling/success.wav", "category": SoundCategory.SUCCESS, "volume_db": 0.0},
	"drill_dry": {"path": "res://assets/sounds/drilling/dry.wav", "category": SoundCategory.FAILURE, "volume_db": -3.0},
	"oil_gush": {"path": "res://assets/sounds/drilling/gush.wav", "category": SoundCategory.SPECIAL, "volume_db": 0.0},

	# Event Sounds
	"news_alert": {"path": "res://assets/sounds/events/news.wav", "category": SoundCategory.WARNING, "volume_db": -5.0},
	"phone_ring": {"path": "res://assets/sounds/events/phone.wav", "category": SoundCategory.WARNING, "volume_db": 0.0},
	"alert_critical": {"path": "res://assets/sounds/events/critical.wav", "category": SoundCategory.WARNING, "volume_db": 0.0},
	"fire_alarm": {"path": "res://assets/sounds/events/fire.wav", "category": SoundCategory.WARNING, "volume_db": 0.0},

	# Ambient
	"office_ambient": {"path": "res://assets/sounds/ambient/office.wav", "category": SoundCategory.AMBIENT, "volume_db": -15.0, "loop": true},
	"computer_ambient": {"path": "res://assets/sounds/ambient/computer.wav", "category": SoundCategory.AMBIENT, "volume_db": -15.0, "loop": true},
	"outside_ambient": {"path": "res://assets/sounds/ambient/outside.wav", "category": SoundCategory.AMBIENT, "volume_db": -20.0, "loop": true},

	# Achievement/Special
	"achievement": {"path": "res://assets/sounds/special/achievement.wav", "category": SoundCategory.SPECIAL, "volume_db": 0.0},
	"era_upgrade": {"path": "res://assets/sounds/special/era_upgrade.wav", "category": SoundCategory.SPECIAL, "volume_db": 0.0},
	"game_over": {"path": "res://assets/sounds/special/game_over.wav", "category": SoundCategory.SPECIAL, "volume_db": 0.0},
	"victory": {"path": "res://assets/sounds/special/victory.wav", "category": SoundCategory.SPECIAL, "volume_db": 0.0},

	# Sabotage
	"sabotage_success": {"path": "res://assets/sounds/sabotage/success.wav", "category": SoundCategory.GAME_EVENT, "volume_db": -3.0},
	"sabotage_fail": {"path": "res://assets/sounds/sabotage/fail.wav", "category": SoundCategory.FAILURE, "volume_db": -3.0},
	"sabotage_exposed": {"path": "res://assets/sounds/sabotage/exposed.wav", "category": SoundCategory.WARNING, "volume_db": 0.0}
}

# ==============================================================================
# ERA-SPECIFIC SOUND MODIFIERS
# ==============================================================================

const ERA_SOUND_MODIFIERS = {
	0: {  # 1970s - Analog warmth
		"pitch_scale": 1.0,
		"lowpass_freq": 8000,
		"description": "Analoger Sound"
	},
	1: {  # 1980s - Digital/Crisp
		"pitch_scale": 1.02,
		"lowpass_freq": 12000,
		"description": "Digitaler 80er Sound"
	},
	2: {  # 1990s - CD Quality
		"pitch_scale": 1.0,
		"lowpass_freq": 20000,
		"description": "CD-Qualitaet"
	},
	3: {  # 2000s+ - Modern HD
		"pitch_scale": 1.0,
		"lowpass_freq": 22000,
		"description": "HD Audio"
	}
}

# ==============================================================================
# STATE
# ==============================================================================

var game_manager = null
var sound_pools: Dictionary = {}
var active_ambient: AudioStreamPlayer = null
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var ambient_volume: float = 0.7
var sound_enabled: bool = true

# Audio buses
var sfx_bus_index: int = 1
var ambient_bus_index: int = 2

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_buses()
	_preload_common_sounds()

func _setup_audio_buses():
	# Ensure audio buses exist
	var bus_layout = AudioServer.get_bus_count()
	if bus_layout < 3:
		# Create SFX bus if needed
		if bus_layout == 1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(1, "SFX")
		# Create Ambient bus if needed
		if bus_layout <= 2:
			AudioServer.add_bus()
			AudioServer.set_bus_name(2, "Ambient")

	sfx_bus_index = AudioServer.get_bus_index("SFX")
	ambient_bus_index = AudioServer.get_bus_index("Ambient")

func _preload_common_sounds():
	# Preload frequently used sounds
	var common_sounds = ["ui_click", "ui_hover", "money_gain", "money_loss", "drill_success"]

	for sound_id in common_sounds:
		if SOUNDS.has(sound_id):
			var sound_data = SOUNDS[sound_id]
			if ResourceLoader.exists(sound_data["path"]):
				sound_pools[sound_id] = {
					"stream": load(sound_data["path"]),
					"data": sound_data
				}

# ==============================================================================
# MAIN PLAY FUNCTIONS
# ==============================================================================

func play_sound(sound_id: String, override_volume: float = -1000.0) -> bool:
	if not sound_enabled:
		return false

	if not SOUNDS.has(sound_id):
		push_warning("Sound not found: " + sound_id)
		return false

	var sound_data = SOUNDS[sound_id]
	var stream: AudioStream

	# Check if preloaded
	if sound_pools.has(sound_id):
		stream = sound_pools[sound_id]["stream"]
	else:
		if not ResourceLoader.exists(sound_data["path"]):
			return false
		stream = load(sound_data["path"])

	# Create player
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = _get_bus_for_category(sound_data["category"])

	# Set volume
	var vol = sound_data["volume_db"]
	if override_volume > -1000:
		vol = override_volume
	player.volume_db = vol * sfx_volume

	# Apply era modifier
	if game_manager:
		var era_mod = ERA_SOUND_MODIFIERS.get(game_manager.current_era, ERA_SOUND_MODIFIERS[0])
		player.pitch_scale = era_mod["pitch_scale"]

	# Play and cleanup
	add_child(player)
	player.play()
	player.finished.connect(func(): player.queue_free())

	return true

func play_ui_sound(action: String):
	match action:
		"click":
			play_sound("ui_click")
		"hover":
			play_sound("ui_hover")
		"open":
			play_sound("ui_open")
		"close":
			play_sound("ui_close")
		"error":
			play_sound("ui_error")

func play_game_event(event_type: String, success: bool = true):
	match event_type:
		"drilling":
			if success:
				play_sound("drill_success")
			else:
				play_sound("drill_dry")
		"sale":
			if success:
				play_sound("money_gain")
			else:
				play_sound("money_loss")
		"contract":
			play_sound("contract_sign")
		"sabotage":
			if success:
				play_sound("sabotage_success")
			else:
				play_sound("sabotage_fail")
		"news":
			play_sound("news_alert")
		"phone":
			play_sound("phone_ring")
		"achievement":
			play_sound("achievement")
		"fire":
			play_sound("fire_alarm")
		"era_upgrade":
			play_sound("era_upgrade")

# ==============================================================================
# AMBIENT SOUNDS
# ==============================================================================

func start_ambient(ambient_type: String = "office"):
	if not sound_enabled:
		return

	# Stop current ambient
	stop_ambient()

	var sound_id = ambient_type + "_ambient"
	if not SOUNDS.has(sound_id):
		sound_id = "office_ambient"

	if not SOUNDS.has(sound_id):
		return

	var sound_data = SOUNDS[sound_id]
	if not ResourceLoader.exists(sound_data["path"]):
		return

	var stream = load(sound_data["path"])
	active_ambient = AudioStreamPlayer.new()
	active_ambient.stream = stream
	active_ambient.bus = "Ambient"
	active_ambient.volume_db = sound_data["volume_db"] * ambient_volume
	active_ambient.autoplay = true

	if sound_data.get("loop", false):
		# Set loop mode if supported
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		elif stream is AudioStreamOGGVorbis:
			stream.loop = true

	add_child(active_ambient)

func stop_ambient():
	if active_ambient:
		active_ambient.stop()
		active_ambient.queue_free()
		active_ambient = null

func set_ambient_volume(volume: float):
	ambient_volume = clamp(volume, 0.0, 1.0)
	if active_ambient:
		var base_db = SOUNDS.get("office_ambient", {}).get("volume_db", -15.0)
		active_ambient.volume_db = base_db * ambient_volume

# ==============================================================================
# VOLUME CONTROL
# ==============================================================================

func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)

func toggle_sound(enabled: bool):
	sound_enabled = enabled
	if not enabled:
		stop_ambient()

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

func _get_bus_for_category(category: SoundCategory) -> String:
	match category:
		SoundCategory.AMBIENT:
			return "Ambient"
		_:
			return "SFX"

func linear_to_db(value: float) -> float:
	if value <= 0.0:
		return -80.0
	return 20.0 * log(value) / log(10.0)

# ==============================================================================
# EVENT CONNECTIONS
# ==============================================================================

func connect_to_game_events():
	if game_manager == null:
		return

	# Connect to relevant signals
	if game_manager.has_signal("month_ended"):
		game_manager.month_ended.connect(_on_month_ended)

	if game_manager.has_signal("tech_researched"):
		game_manager.tech_researched.connect(_on_tech_researched)

	if game_manager.achievement_manager:
		game_manager.achievement_manager.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_month_ended(_report):
	play_sound("news_alert")

func _on_tech_researched(_tech_id):
	play_sound("achievement")

func _on_achievement_unlocked(_achievement_id):
	play_sound("achievement")

# ==============================================================================
# SAVE/LOAD
# ==============================================================================

func get_save_data() -> Dictionary:
	return {
		"master_volume": master_volume,
		"sfx_volume": sfx_volume,
		"ambient_volume": ambient_volume,
		"sound_enabled": sound_enabled
	}

func load_save_data(data: Dictionary):
	master_volume = data.get("master_volume", 1.0)
	sfx_volume = data.get("sfx_volume", 1.0)
	ambient_volume = data.get("ambient_volume", 0.7)
	sound_enabled = data.get("sound_enabled", true)

	set_master_volume(master_volume)

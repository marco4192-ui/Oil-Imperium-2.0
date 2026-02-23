extends Node

# MusicManager - Handles background music based on current era
# Era mapping: 0 = 1970s, 1 = 1980s, 2 = 1990s, 3 = 2000s

const MUSIC_TRACKS = {
	0: "res://assets/background-loops/70s-background-melody.mp3",
	1: "res://assets/background-loops/80s-background-melody.mp3",
	2: "res://assets/background-loops/90s-background-melody.mp3",
	3: "res://assets/background-loops/00s-background-melody.mp3",
}

var current_era: int = 0
var music_player: AudioStreamPlayer
var is_playing: bool = false
var volume_db: float = -5.0
var fade_duration: float = 1.0

# Reference to GameManager
var game_manager = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_music_player()

func _setup_music_player():
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = volume_db
	music_player.bus = "Master"
	add_child(music_player)

func initialize(gm):
	game_manager = gm
	
	# Connect to GameManager signals
	if game_manager:
		if game_manager.has_signal("era_changed"):
			game_manager.era_changed.connect(_on_era_changed)
		
		# Set initial era
		current_era = game_manager.current_era
		play_music_for_era(current_era)

func play_music_for_era(era: int):
	if not MUSIC_TRACKS.has(era):
		return
	
	var track_path = MUSIC_TRACKS[era]
	var stream = load(track_path)
	
	if stream == null:
		return
	
	# Crossfade to new track
	if music_player.playing:
		_crossfade_to(stream)
	else:
		music_player.stream = stream
		music_player.play()
		is_playing = true

func _crossfade_to(new_stream):
	# Fade out current
	var fade_out = create_tween()
	fade_out.tween_property(music_player, "volume_db", -40.0, fade_duration)
	
	await fade_out.finished
	
	# Switch stream
	music_player.stream = new_stream
	music_player.volume_db = -40.0
	music_player.play()
	
	# Fade in new
	var fade_in = create_tween()
	fade_in.tween_property(music_player, "volume_db", volume_db, fade_duration)

func _on_era_changed(new_era: int):
	if new_era != current_era:
		current_era = new_era
		play_music_for_era(new_era)

func stop_music():
	if music_player:
		music_player.stop()
		is_playing = false

func pause_music():
	if music_player and music_player.playing:
		music_player.stream_paused = true

func resume_music():
	if music_player and music_player.stream_paused:
		music_player.stream_paused = false

func set_volume(db: float):
	volume_db = db
	if music_player:
		music_player.volume_db = volume_db

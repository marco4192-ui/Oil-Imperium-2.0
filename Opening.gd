extends Control

# Opening Sequence for Oil Imperium 2.0
# Creates a dynamic collage of images synchronized with music

# Image textures
const IMAGE_PATHS := [
        "res://assets/opening/opening-01.png",
        "res://assets/opening/opening-02.png",
        "res://assets/opening/opening-03.png",
        "res://assets/opening/opening-04.png",
        "res://assets/opening/opening-05.png",
        "res://assets/opening/opening-06.png",
        "res://assets/opening/opening-07.png",
        "res://assets/opening/opening-08.png",
        "res://assets/opening/opening-09.png",
        "res://assets/opening/opening-10.png",
        "res://assets/opening/opening-11.png",
        "res://assets/opening/opening-12.png",
]

const MUSIC_PATH := "res://assets/opening/Opening-Theme.mp3"
const MAIN_MENU_SCENE := "res://CharacterCreation.tscn"

# Animation timing (total ~31 seconds)
const TOTAL_DURATION := 31.0
const IMAGE_INTERVAL := 1.8  # Time between image appearances (was 2.3)
const FIRST_IMAGE_DELAY := 0.3  # Delay before first image (was 0.5)
const TITLE_SHOW_TIME := 22.0  # When to show title during music

# UI elements
var background: ColorRect
var images_container: Control
var title_label: Label
var skip_label: Label
var music_player: AudioStreamPlayer

# Image display nodes
var image_nodes: Array = []
var current_image_index: int = 0

# Animation state
var animation_timer: float = 0.0
var is_finished: bool = false
var title_visible: bool = false

# Predefined positions for collage layout (12 images)
# Format: [x_ratio, y_ratio, scale, rotation_degrees, z_index]
const COLLAGE_POSITIONS := [
        # Image 1: Center, large (main hero image)
        [0.5, 0.5, 0.65, 0.0, 1],
        # Image 2: Top left, medium
        [0.15, 0.18, 0.35, -5.0, 2],
        # Image 3: Top right, medium
        [0.85, 0.2, 0.38, 4.0, 3],
        # Image 4: Left side, small
        [0.12, 0.5, 0.32, -3.0, 4],
        # Image 5: Right side, small
        [0.88, 0.55, 0.3, 6.0, 5],
        # Image 6: Bottom left, medium
        [0.22, 0.82, 0.36, -8.0, 6],
        # Image 7: Bottom right, medium
        [0.78, 0.85, 0.34, 7.0, 7],
        # Image 8: Top center-left
        [0.32, 0.25, 0.28, -2.0, 8],
        # Image 9: Top center-right
        [0.68, 0.28, 0.30, 3.0, 9],
        # Image 10: Center-left
        [0.25, 0.55, 0.26, -4.0, 10],
        # Image 11: Center-right
        [0.75, 0.52, 0.27, 5.0, 11],
        # Image 12: Bottom center
        [0.5, 0.88, 0.32, 0.0, 12],
]

# Animation types for each image
const ANIMATION_TYPES := [
        "zoom",       # Image 1 - main hero, zoom effect
        "fly_left",   # Image 2
        "fly_right",  # Image 3
        "fly_top",    # Image 4
        "fly_bottom", # Image 5
        "fly_left",   # Image 6
        "fly_right",  # Image 7
        "zoom",       # Image 8
        "fly_top",    # Image 9
        "fly_bottom", # Image 10
        "fly_left",   # Image 11
        "zoom",       # Image 12
]

func _ready():
        _setup_background()
        _setup_images_container()
        _setup_title()
        _setup_skip_label()
        _setup_music()
        _start_sequence()

func _setup_background():
        background = ColorRect.new()
        background.color = Color.BLACK
        background.set_anchors_preset(Control.PRESET_FULL_RECT)
        background.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(background)

func _setup_images_container():
        images_container = Control.new()
        images_container.set_anchors_preset(Control.PRESET_FULL_RECT)
        images_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(images_container)

func _setup_title():
        title_label = Label.new()
        title_label.text = "OIL IMPERIUM 2.0"
        title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        title_label.set_anchors_preset(Control.PRESET_CENTER)
        title_label.custom_minimum_size = Vector2(1200, 200)
        title_label.position = Vector2(-600, -100)
        title_label.add_theme_font_size_override("font_size", 96)
        
        # Mechanical/steel color scheme - dark steel with metallic accent
        var steel_color = Color(0.7, 0.75, 0.8)  # Light steel gray
        var _dark_steel = Color(0.3, 0.35, 0.4)   # Dark steel for outline (future use)
        
        title_label.add_theme_color_override("font_color", steel_color)
        title_label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.12))
        title_label.add_theme_constant_override("outline_size", 12)
        
        # Add shadow effect for 3D metallic look
        title_label.modulate.a = 0.0
        title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        title_label.z_index = 100
        title_label.visible = false
        add_child(title_label)

func _setup_skip_label():
        skip_label = Label.new()
        skip_label.text = "Click to skip"
        skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        skip_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
        skip_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
        skip_label.position = Vector2(-30, -30)
        skip_label.add_theme_font_size_override("font_size", 20)
        skip_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.6))
        skip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(skip_label)

func _setup_music():
        music_player = AudioStreamPlayer.new()
        music_player.stream = load(MUSIC_PATH)
        music_player.volume_db = 0.0
        music_player.bus = "Master"
        add_child(music_player)

func _start_sequence():
        music_player.play()
        await get_tree().create_timer(FIRST_IMAGE_DELAY).timeout
        _show_next_image()

func _process(delta):
        if is_finished:
                return
        
        animation_timer += delta
        
        if current_image_index < IMAGE_PATHS.size():
                var next_time = FIRST_IMAGE_DELAY + (current_image_index + 1) * IMAGE_INTERVAL
                if animation_timer >= next_time - FIRST_IMAGE_DELAY:
                        _show_next_image()
        
        # Show title at specific time during music, not when music ends
        if not title_visible and animation_timer >= TITLE_SHOW_TIME:
                _show_title()

func _show_next_image():
        if current_image_index >= IMAGE_PATHS.size():
                return
        
        var index = current_image_index
        var texture = load(IMAGE_PATHS[index])
        
        var img_rect = TextureRect.new()
        img_rect.texture = texture
        img_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
        img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        img_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
        
        var layout = COLLAGE_POSITIONS[index]
        var x_ratio = layout[0]
        var y_ratio = layout[1]
        var scale_val = layout[2]
        var rot_deg = layout[3]
        var z_idx = layout[4]
        
        var viewport_size = get_viewport().get_visible_rect().size
        var img_size = viewport_size.y * scale_val
        
        img_rect.custom_minimum_size = Vector2(img_size, img_size)
        img_rect.size = Vector2(img_size, img_size)
        img_rect.position = Vector2(
                viewport_size.x * x_ratio - img_size / 2,
                viewport_size.y * y_ratio - img_size / 2
        )
        img_rect.rotation_degrees = rot_deg
        img_rect.z_index = z_idx
        
        var shadow = _create_shadow(img_rect.position, img_rect.size, rot_deg)
        images_container.add_child(shadow)
        shadow.modulate.a = 0.0
        _fade_in_node(shadow, 0.5)
        
        images_container.add_child(img_rect)
        image_nodes.append(img_rect)
        
        var anim_type = ANIMATION_TYPES[index]
        _apply_entrance_animation(img_rect, anim_type, viewport_size)
        
        current_image_index += 1

func _create_shadow(pos: Vector2, shadow_size: Vector2, rot_degrees: float) -> ColorRect:
        var shadow = ColorRect.new()
        shadow.color = Color(0, 0, 0, 0.5)
        shadow.custom_minimum_size = shadow_size
        shadow.size = shadow_size
        shadow.position = pos + Vector2(10, 10)
        shadow.rotation_degrees = rot_degrees
        shadow.z_index = -1
        shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
        return shadow

func _apply_entrance_animation(node: Control, anim_type: String, viewport_size: Vector2):
        var target_pos = node.position
        var duration = 0.8
        
        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_QUAD)
        
        match anim_type:
                "fade":
                        node.modulate.a = 0.0
                        tween.tween_property(node, "modulate:a", 1.0, duration)
                
                "zoom":
                        node.modulate.a = 0.0
                        node.scale = Vector2(0.1, 0.1)
                        tween.parallel().tween_property(node, "modulate:a", 1.0, duration)
                        tween.parallel().tween_property(node, "scale", Vector2(1.0, 1.0), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
                
                "fly_left":
                        node.position.x = -node.size.x
                        node.modulate.a = 0.0
                        tween.parallel().tween_property(node, "position:x", target_pos.x, duration)
                        tween.parallel().tween_property(node, "modulate:a", 1.0, duration * 0.5)
                
                "fly_right":
                        node.position.x = viewport_size.x + node.size.x
                        node.modulate.a = 0.0
                        tween.parallel().tween_property(node, "position:x", target_pos.x, duration)
                        tween.parallel().tween_property(node, "modulate:a", 1.0, duration * 0.5)
                
                "fly_top":
                        node.position.y = -node.size.y
                        node.modulate.a = 0.0
                        tween.parallel().tween_property(node, "position:y", target_pos.y, duration)
                        tween.parallel().tween_property(node, "modulate:a", 1.0, duration * 0.5)
                
                "fly_bottom":
                        node.position.y = viewport_size.y + node.size.y
                        node.modulate.a = 0.0
                        tween.parallel().tween_property(node, "position:y", target_pos.y, duration)
                        tween.parallel().tween_property(node, "modulate:a", 1.0, duration * 0.5)
                
                _:
                        node.modulate.a = 0.0
                        tween.tween_property(node, "modulate:a", 1.0, duration)

func _fade_in_node(node: Control, duration: float):
        var tween = create_tween()
        tween.tween_property(node, "modulate:a", 1.0, duration)

func _show_title():
        title_visible = true
        title_label.visible = true
        
        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_QUAD)
        
        title_label.scale = Vector2(0.5, 0.5)
        title_label.modulate.a = 0.0
        
        tween.parallel().tween_property(title_label, "modulate:a", 1.0, 1.5)
        tween.parallel().tween_property(title_label, "scale", Vector2(1.0, 1.0), 1.5).set_trans(Tween.TRANS_ELASTIC)
        
        tween.tween_callback(_pulse_title)
        
        await get_tree().create_timer(3.0).timeout
        is_finished = true
        
        var skip_tween = create_tween()
        skip_tween.tween_property(skip_label, "modulate:a", 0.0, 0.5)

func _pulse_title():
        var tween = create_tween()
        tween.set_loops()
        # Steel/metallic shimmer effect
        tween.tween_property(title_label, "modulate", Color(0.85, 0.88, 0.92), 1.2)
        tween.tween_property(title_label, "modulate", Color(0.7, 0.75, 0.8), 1.2)

func _input(event):
        if event is InputEventMouseButton and event.pressed:
                _skip_to_end()
        elif event is InputEventKey and event.pressed:
                if event.keycode == KEY_ESCAPE or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
                        _skip_to_end()

func _skip_to_end():
        if is_finished:
                _go_to_main_menu()
                return
        
        music_player.stop()
        
        while current_image_index < IMAGE_PATHS.size():
                var index = current_image_index
                var texture = load(IMAGE_PATHS[index])
                var img_rect = TextureRect.new()
                img_rect.texture = texture
                img_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
                img_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
                img_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
                
                var layout = COLLAGE_POSITIONS[index]
                var viewport_size = get_viewport().get_visible_rect().size
                var img_size = viewport_size.y * layout[2]
                
                img_rect.custom_minimum_size = Vector2(img_size, img_size)
                img_rect.size = Vector2(img_size, img_size)
                img_rect.position = Vector2(
                        viewport_size.x * layout[0] - img_size / 2,
                        viewport_size.y * layout[1] - img_size / 2
                )
                img_rect.rotation_degrees = layout[3]
                img_rect.z_index = layout[4]
                
                images_container.add_child(img_rect)
                image_nodes.append(img_rect)
                current_image_index += 1
        
        _show_title()
        is_finished = true
        skip_label.visible = false

func _go_to_main_menu():
        if music_player:
                music_player.stop()
        get_tree().change_scene_to_file(MAIN_MENU_SCENE)

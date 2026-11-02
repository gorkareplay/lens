extends CanvasLayer

signal play_requested(fade_duration: float)

const MENU_FADE_DURATION := 1.4
const TITLE_ART := preload("res://Sprites/title.jpg")
const PLAY_BUTTON_ART := preload("res://Sprites/play_button.png")

var menu_root: Control
var title_image: TextureRect
var play_button: TextureButton
var play_button_height_ratio := 1.0

func _ready() -> void:
	layer = 120
	_build_menu()
	get_viewport().size_changed.connect(_resize_menu)
	_resize_menu()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _build_menu() -> void:
	menu_root = Control.new()
	menu_root.name = "MenuRoot"
	menu_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(menu_root)

	var background := ColorRect.new()
	background.name = "WhiteBackground"
	background.color = Color.WHITE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	menu_root.add_child(background)

	var center := CenterContainer.new()
	center.name = "MenuCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	menu_root.add_child(center)

	var content := VBoxContainer.new()
	content.name = "MenuContent"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 26)
	content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	center.add_child(content)

	title_image = TextureRect.new()
	title_image.name = "TitleImage"
	title_image.texture = TITLE_ART
	title_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title_image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_image.custom_minimum_size = Vector2(760, 250)
	title_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(title_image)

	var button_image := PLAY_BUTTON_ART.get_image()
	var button_bounds := button_image.get_used_rect()
	button_image = button_image.get_region(button_bounds)
	play_button_height_ratio = float(button_image.get_height()) / float(button_image.get_width())
	var button_texture := ImageTexture.create_from_image(button_image)
	var click_mask := BitMap.new()
	click_mask.create_from_image_alpha(button_image)

	play_button = TextureButton.new()
	play_button.name = "PlayButton"
	play_button.texture_normal = button_texture
	play_button.texture_hover = button_texture
	play_button.texture_pressed = button_texture
	play_button.texture_focused = button_texture
	play_button.texture_click_mask = click_mask
	play_button.ignore_texture_size = true
	play_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	play_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	play_button.focus_mode = Control.FOCUS_ALL
	play_button.tooltip_text = "Play"
	play_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	play_button.mouse_entered.connect(func(): play_button.modulate = Color(1.18, 1.18, 1.18, 1.0))
	play_button.mouse_exited.connect(func(): play_button.modulate = Color.WHITE)
	play_button.pressed.connect(_on_play_pressed)
	content.add_child(play_button)
	play_button.grab_focus()

func _resize_menu() -> void:
	if not is_instance_valid(title_image) or not is_instance_valid(play_button):
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var title_width := minf(viewport_size.x * 0.88, 920.0)
	var title_height := minf(viewport_size.y * 0.34, 276.0)
	title_image.custom_minimum_size = Vector2(title_width, title_height)
	var available_button_height := maxf(viewport_size.y - title_height - 66.0, 0.0)
	var button_width := minf(minf(viewport_size.x * 0.4, 360.0), available_button_height / play_button_height_ratio)
	play_button.custom_minimum_size = Vector2(button_width, button_width * play_button_height_ratio)

func _on_play_pressed() -> void:
	play_button.disabled = true
	play_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.get_node("WhiteBackground").mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.get_node("MenuCenter").mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.get_node("MenuCenter/MenuContent").mouse_filter = Control.MOUSE_FILTER_IGNORE
	var menu_fade := create_tween()
	menu_fade.set_trans(Tween.TRANS_SINE)
	menu_fade.set_ease(Tween.EASE_IN_OUT)
	menu_fade.tween_property(menu_root, "modulate", Color(1, 1, 1, 0), MENU_FADE_DURATION)
	await menu_fade.finished
	menu_root.hide()
	play_requested.emit(MENU_FADE_DURATION)

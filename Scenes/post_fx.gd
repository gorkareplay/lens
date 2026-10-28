extends CanvasLayer

@onready var colorrect: ColorRect = $ColorRect
@onready var shader_material: ShaderMaterial = colorrect.material as ShaderMaterial

# Keeps track of the active tween so we can cancel/restart it smoothly
var color_tween: Tween

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass

# Helper function to smoothly transition both colors over 1 second. ai made it
func transition_to_colors(target_a: Color, target_b: Color) -> void:
	# If a tween is already running, kill it so we can start a new smooth blend from the current spot
	if color_tween and color_tween.is_valid():
		color_tween.kill()
	
	# Grab the current shader colors as our starting point
	var start_a = shader_material.get_shader_parameter("color_a")
	var start_b = shader_material.get_shader_parameter("color_b")
	
	# Fallback safety check if they haven't been initialized yet
	if start_a == null: start_a = Color(0, 0, 0, 1)
	if start_b == null: start_b = Color(1, 1, 1, 1)
	
	# Create a new tween that runs both properties in parallel over 1.0 second
	color_tween = create_tween().set_parallel(true)
	
	color_tween.tween_method(
		func(c: Color) -> void: shader_material.set_shader_parameter("color_a", c),
		start_a, target_a, 0.5
	)
	color_tween.tween_method(
		func(c: Color) -> void: shader_material.set_shader_parameter("color_b", c),
		start_b, target_b, 0.5
	)

func _on_player_no_lens_signal() -> void:
	print("nolens")
	transition_to_colors(Color(0, 0, 0, 1), Color(1, 1, 1, 1)) # Black to White

func _on_player_red_lens_signal() -> void:
	print("redlens")
	transition_to_colors(Color(1, 0, 0, 1), Color(0, 1, 1, 1)) # Red to Green

func _on_player_green_lens_signal() -> void:
	print("greenlens")
	transition_to_colors(Color(0, 1, 0, 1), Color(1, 0, 1, 1)) # Green to Magenta

func _on_player_blue_lens_signal() -> void:
	print("bluelens")
	transition_to_colors(Color(0, 0, 1, 1), Color(1, 1, 0, 1)) # Blue to Yellow

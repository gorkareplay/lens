extends Camera3D

@export var sensitivity: float = 0.003
@export var smooth_speed: float = 25.0 # Higher = faster/snappier, Lower = smoother/heavier

var max_pitch: float = deg_to_rad(89.0)
var min_pitch: float = deg_to_rad(-89.0)

# Target variables to track where the mouse wants to look
var target_yaw: float = 0.0
var target_pitch: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Initialize targets to match the camera's starting orientation
	target_yaw = rotation.y
	target_pitch = rotation.x

func _input(event: InputEvent) -> void:
	if not Dialogue.active:
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			# Add to our target values instead of snapping the camera instantly
			target_yaw -= event.relative.x * sensitivity
			target_pitch -= event.relative.y * sensitivity
		
			# Clamp the vertical look limit immediately
			target_pitch = clamp(target_pitch, min_pitch, max_pitch)

func _process(delta: float) -> void:
	if not Dialogue.active:
		# Smoothly glide (interpolate) the camera's actual rotation toward the targets every frame
		rotation.y = lerp_angle(rotation.y, target_yaw, smooth_speed * delta)
		rotation.x = lerp_angle(rotation.x, target_pitch, smooth_speed * delta)
	
		# Keep roll locked to avoid tilting sideways
		rotation.z = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

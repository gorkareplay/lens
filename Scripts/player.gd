extends CharacterBody3D

@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@export var max_speed := 4.0
@export var ground_accel := 20.0
@export var ground_friction := 30.0
@export var air_accel := 6.0
@export var air_friction := 0.5
@export var jump_velocity := 4.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("ui_accept"):
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := Vector3.ZERO

	if input_dir != Vector2.ZERO:
		var cam := camera if camera else get_viewport().get_camera_3d()
		var cam_basis := cam.global_transform.basis

		var forward := -cam_basis.z
		forward.y = 0
		forward = forward.normalized()

		var right := cam_basis.x
		right.y = 0
		right = right.normalized()

		direction = (right * input_dir.x + forward * -input_dir.y).normalized()

	var accel := ground_accel if is_on_floor() else air_accel
	var friction := ground_friction if is_on_floor() else air_friction

	var horizontal := Vector3(velocity.x, 0, velocity.z)

	if direction != Vector3.ZERO:
		horizontal = horizontal.move_toward(direction * max_speed, accel * delta)
	else:
		horizontal = horizontal.move_toward(Vector3.ZERO, friction * delta)

	velocity.x = horizontal.x
	velocity.z = horizontal.z

	move_and_slide()

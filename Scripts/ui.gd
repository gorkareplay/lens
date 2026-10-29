extends Control

@onready var button: Button = $ResumeButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if get_tree().paused:
		button.disabled = false
		button.visible = true

func _on_resume_button_pressed() -> void:
	unpause()
	
func unpause():
	button.disabled = true
	button.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().paused = false

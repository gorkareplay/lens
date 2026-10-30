extends Node3D

@export var prologue_sit_down: DialogueData
@export var tutorial_base: DialogueData

# voice values here

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await Dialogue.say(prologue_sit_down)
	await Dialogue.say(tutorial_base)
	await Dialogue.say_raw(["Press 1, 2, 3 and 4 to change lenses."], "#%$^!")
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta: float) -> void:

		
	
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

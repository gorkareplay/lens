extends Node3D

@export var dialouge_status: int = 0

# voice values here
var sherif_voice: Array = [92.0, 0.55, 0.10, 0.55, -9.0]

var lines: Array = [
	# Sherif startup line. lines[0]
	[
		"Huh, new renovation...", 
		"Everything is clean and shiny.", 
		"Doesn't look like the old \"Sables De Mars\" that burned down to the ground.",
		"I need to make sure that my gear still works properly."
	]
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_dialouge_talk(sherif_voice, "Sherif", lines[0], 1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if dialouge_status == 1:
		_dialouge_talk(sherif_voice, "#%$^!", ["Press 0, 1, 2 and 3 to change lenses."], 2)
	
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _dialouge_talk(voice: Array, _name: String, line: Array, new_dialouge_status: int):
	VoiceSynth.set_voice.callv(voice)
	await Dialogue.say(line)
	dialouge_status = new_dialouge_status

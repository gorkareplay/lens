extends Node3D

@export var prologue_sit_down: DialogueData
@export var tutorial_base: DialogueData

@onready var player = $Player
@onready var restaurant: Node3D = $Restaurant
@onready var wallpaper_costil = $StaticBody3D/WallpaperCostil
@onready var music = $MusicPlayer

var phase := "tutorial"
var in_kitchen := false
var in_park := false
var busy := false
var seen_lenses := {}
var clues := {}
var actors := {}
var objective: Label
var prompt: Label
var menu: Control
@onready var title_menu = $UI
var trail_visuals: Array[Node3D] = []
var waiter_home := Vector3(9.5, 0.65, 3.35)

func _ready() -> void:
	_build_hud()
	_build_world()
	player.global_position = restaurant.to_global(Vector3(5.2, 0.5, 5.5))
	player.menu_active = true
	player.controls_locked = true
	player.interaction_requested.connect(_interact)
	player.lens_changed.connect(_lens_changed)
	title_menu.play_requested.connect(_start_game)
	busy = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _start_game() -> void:
	if not player.menu_active:
		return
	player.menu_active = false
	player.controls_locked = true
	music.stream = load("res://Sound/main_theme.mp3")
	music.play()
	_set_objective("Try the red (2), green (3), and blue (4) lenses.")
	await Dialogue.say(prologue_sit_down)
	await Dialogue.say(tutorial_base)
	await Dialogue.say_raw(["Move with WASD, look with the mouse, and press E to interact. Switch lenses with 1–4."], "")
	busy = false
	player.controls_locked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	objective = Label.new()
	layer.add_child(objective)
	objective.position = Vector2(20, 16)
	objective.add_theme_font_size_override("font_size", 20)
	objective.add_theme_color_override("font_color", Color.WHITE)
	objective.add_theme_color_override("font_outline_color", Color.BLACK)
	objective.add_theme_constant_override("outline_size", 5)
	prompt = Label.new()
	var prompt_center := CenterContainer.new()
	layer.add_child(prompt_center)
	prompt_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prompt_center.offset_top = -42
	prompt_center.offset_bottom = -42
	prompt_center.add_child(prompt)
	prompt.custom_minimum_size = Vector2(520, 36)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 18)
	prompt.add_theme_color_override("font_color", Color.WHITE)
	prompt.add_theme_color_override("font_outline_color", Color.BLACK)
	prompt.add_theme_constant_override("outline_size", 5)
	var cross := Label.new()
	cross.text = "+"
	var cross_center := CenterContainer.new()
	layer.add_child(cross_center)
	cross_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cross_center.add_child(cross)
	cross.custom_minimum_size = Vector2(20, 30)
	cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cross.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cross.add_theme_font_size_override("font_size", 24)
	cross.add_theme_color_override("font_color", Color.WHITE)
	cross.add_theme_color_override("font_outline_color", Color.BLACK)
	cross.add_theme_constant_override("outline_size", 4)

func _process(_delta: float) -> void:
	prompt.text = ""
	if busy or Dialogue.active or player.controls_locked:
		return
	var hit = player.raycast.get_collider()
	if hit and hit.has_meta("story_id"):
		var needed: String = hit.get_meta("lens", "any")
		var suffix := "" if needed == "any" or needed == player.lens else " (%s lens)" % needed
		prompt.text = "E — " + str(hit.get_meta("label")) + suffix

func _set_objective(value: String) -> void:
	objective.text = value

func _lens_changed(lens: String) -> void:
	get_tree().call_group("blue_lens_arrows", "set_blue_lens_active", lens == "blue")
	_update_markers()
	if phase != "tutorial" or lens == "base" or seen_lenses.has(lens) or busy:
		return
	seen_lenses[lens] = true
	busy = true
	await _say(["tutorial_" + lens])
	busy = false
	if seen_lenses.size() == 3:
		phase = "approach"
		_set_objective("Speak to the waiter.")
		_update_markers()

func _say(ids: Array, character: Node3D = null) -> void:
	var animator: AnimatedSprite3D
	if character:
		animator = character.get_node_or_null("Interactable") as AnimatedSprite3D
	for id in ids:
		var data := load("res://Dialogue/%s.tres" % id) as DialogueData
		if data:
			if animator:
				var animation := "talk" if data.speaker == character.get_meta("label", "") else "idle"
				if animator.sprite_frames and animator.sprite_frames.has_animation(animation):
					animator.play(animation)
			await Dialogue.say(data)
	if animator and animator.sprite_frames and animator.sprite_frames.has_animation("idle"):
		animator.play("idle")

func _character(id: String, file: String, pos: Vector3, title: String, parent: Node3D = restaurant) -> void:
	var node: StaticBody3D = load("res://Scenes/Characters/%s.tscn" % file).instantiate()
	parent.add_child(node)
	node.position = pos
	node.set_meta("story_id", id)
	node.set_meta("label", title)
	node.set_meta("lens", "any")
	actors[id] = node

func _marker(id: String, title: String, pos: Vector3, lens: String, parent: Node3D = restaurant) -> void:
	var node: StaticBody3D = load("res://Scenes/Interactables/%s.tscn" % id).instantiate()
	parent.add_child(node)
	node.position = pos
	node.set_meta("story_id", id)
	node.set_meta("label", title)
	node.set_meta("lens", lens)
	actors[id] = node

func _floor_at(center: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = center
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	body.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func _build_world() -> void:
	_character("waiter1", "waiter_one", Vector3(5.2, 0.65, 4.0), "Waiter #1")
	_character("guest", "loyal_customer", Vector3(8.64, 0.65, 4.7), "Regular guest")
	_character("chef", "chef", Vector3(5.3, 0.65, 0.8), "Chef")
	_character("cook", "cook", Vector3(4.3, 0.65, -0.5), "Cook")
	_marker("office_door", "Office door", Vector3(9.737, 0.0, 2.631), "any")
	_marker("back_door", "Back door", Vector3(0.572, 0.0, -1.241), "any")
	_marker("kitchen_door", "Kitchen door", Vector3(5.91, 0.0, 2.052), "any")
	_marker("wallpaper", "Torn wallpaper", Vector3(8.249, 0.822, -1.163), "green")
	_marker("office_window", "Office window", Vector3(10.527, 0.857, 1.111), "green")
	_marker("office_computer", "Computer", Vector3(8.593, 0.723, 0.379), "green")
	_marker("office_blood", "Blood", Vector3(7.942, 0.12, -1.986), "red")
	_marker("kitchen_stove", "Damaged stove", Vector3(4.635, 0.292, -0.721), "green")
	_marker("kitchen_blood", "Blood by the stove", Vector3(4.9, 0.16, -0.95), "red")
	_marker("safe", "Empty safe", Vector3(8.725, 0.363, -1.542), "green")
	_marker("keys", "Keys", Vector3(8.517, 0.257, -2.426), "green")
	_marker("storage_blood", "Blood", Vector3(26.5, 0.9, -1), "red")
	_marker("trail", "Blood trail", Vector3(4, 0.0, -6.751), "red")
	_marker("possessions", "Documents, money and knife", Vector3(-2, 0.1, -8.5), "green")
	_character("body", "manager", Vector3(7.631, 0.286, -2.128), "Manager")
	actors.body.rotation.z = PI / 2
	_character("waiter2", "waiter_two", Vector3(-1.8, 0.559, -8.393), "Waiter #2")
	_update_markers()

func _update_markers() -> void:
	for drop in trail_visuals:
		drop.visible = player.lens == "red" and phase in ["park", "help_return"]
	for id in actors:
		var node: Node3D = actors[id]
		var lens: String = node.get_meta("lens", "any")
		var available := true
		if id == "body": available = clues.has("wallpaper")
		if id in ["safe", "keys", "storage_blood", "closet_exit"]: available = clues.has("wallpaper")
		if id in ["waiter2", "possessions", "trail", "park_exit"]: available = phase in ["park", "help_return", "ended"]
		if id in ["wallpaper", "office_window", "office_computer", "office_shelves", "office_blood"]: available = phase not in ["tutorial", "approach", "lead"]
		if id == "keys" and clues.has("keys"): available = false
		# Characters remain visible as silhouettes; evidence appears in its lens.
		var is_character: bool = id in ["waiter1", "waiter2", "guest", "chef", "cook", "body", "office_door", "back_door", "kitchen_door"]
		node.visible = available and (is_character or lens == "any" or lens == player.lens)
		if not is_character:
			node.collision_layer = 2 if node.visible else 0

func _travel(pos: Vector3) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO

func _interact(target: Object) -> void:
	if busy or Dialogue.active or player.controls_locked or not target.has_meta("story_id"):
		return
	var id: String = target.get_meta("story_id")
	var required: String = target.get_meta("lens", "any")
	if required != "any" and required != player.lens:
		return
	busy = true
	match id:
		"waiter1":
			if phase == "approach":
				await _say(["waiter1_panic", "detective_suppose", "waiter1_thief_report", "detective_call_police", "waiter1_plea", "detective_follow"], target as Node3D)
				phase = "lead"
				_set_objective("Follow the waiter to the office door.")
				var tween := create_tween()
				tween.tween_property(actors.waiter1, "position", waiter_home, 4.0)
			elif phase == "hall":
				await _say(["hall_waiter_asks", "hall_detective_reply", "hall_waiter_suggests"], target as Node3D)
				phase = "investigate"
				_set_objective("Question people about the strange man.")
			elif phase == "help_return":
				await _say(["ending2_waiter1_thief", "ending2_detective_reply", "ending2_waiter1_hesitate", "ending2_detective_responsibility"], target as Node3D)
				await _revenge_ending()
			elif phase == "investigate":
				await _say(["waiter1_q_runner", "waiter1_a_runner"], target as Node3D)
		"office_door":
			if phase == "lead":
				await _say(["office_door_waiter", "office_enter"], actors.waiter1)
				phase = "office"
				_set_objective("Search the office.")
				_travel(restaurant.to_global(Vector3(9.85, 0.5, 2.0)))
				await Dialogue.say_raw(["The hell is this abomination of a wallpaper?...", "They look horrible."])
			elif phase == "office" and clues.has("body"):
				_travel(restaurant.to_global(Vector3(9.95, 0.5, 3.25)))
				phase = "hall"
				_set_objective("Speak to the waiter outside the office.")
				await _say(["hall_detective_thoughts"])
			elif phase == "office":
				await Dialogue.say_raw(["I should search the office before leaving."], "Detective")
		"kitchen_door":
			if in_kitchen:
				_travel(restaurant.to_global(Vector3(6.213, 0.5, 2.521)))
				in_kitchen = false
			else:
				_travel(restaurant.to_global(Vector3(6.213, 0.5, 1.581)))
				in_kitchen = true
		"wallpaper":
			clues.wallpaper = true
			await _say(["storage_body_reveal"])
			_set_objective("Search the hidden space.")
			target.position = Vector3(100.0, 100.0, 100.0)
			wallpaper_costil.queue_free()
		"closet_exit":
			_travel(restaurant.to_global(Vector3(9.7, 0.5, 1.75)))
			_set_objective("Search the office.")
		"body":
			clues.body = true
			await _say(["storage_body"])
			_set_objective("Search for evidence.")
		"safe", "keys", "storage_blood", "office_window", "office_computer", "office_shelves", "office_blood":
			clues[id] = true
			await _say(["storage_safe" if id == "safe" else "storage_keys" if id == "keys" else id])
		"kitchen_stove":
			await Dialogue.say_raw(["The damage around the stove looks like the remains of an explosion."], "Detective")
		"kitchen_blood":
			await Dialogue.say_raw(["A faint streak of blood near the damaged wall."], "Detective")
		"guest":
			if phase == "investigate":
				await _say(["guest_q", "guest_a"], target as Node3D)
				clues.guest = true
		"chef":
			if phase == "investigate":
				await _say(["chef_q", "chef_a"], target as Node3D)
				clues.chef = true
		"cook":
			if phase == "investigate" and clues.has("chef"):
				await _say(["cook_scared", "cook_detective_pardon", "cook_reply"], target as Node3D)
		"back_door":
			if phase == "investigate" and clues.has("guest") and clues.has("chef") and not in_park:
				phase = "park"
				_travel(restaurant.to_global(Vector3(0.844, 0.5, -1.799)))
				_set_objective("Follow the blood trail.")
				in_park = true
			elif in_park:
				_travel(restaurant.to_global(Vector3(0.844, 0.5, -0.829)))
				in_park = false
				if phase == "help_return": 
					_set_objective("Return to the waiter by the office and speak to him.")
			elif clues.has("keys"):
				await Dialogue.say_raw(["I should get more information first"], "Detective")
			else:
				await Dialogue.say_raw(["Locked"], "Detective")
		"trail":
			await Dialogue.say_raw(["Blood leads from the office window into the park."], "Detective")
			_set_objective("Follow the blood trail.")
		"possessions":
			await Dialogue.say_raw(["Documents, money, and a knife. He took them from the restaurant."], "Detective")
		"waiter2":
			if phase == "park":
				await _say(["park_waiter2_confession", "park_detective_silence", "park_waiter2_plea", "park_detective_backstory"], target as Node3D)
				_choose_ending()
	if phase == "investigate" and clues.has("guest") and clues.has("chef"):
		_set_objective("Investigate the courtyard")
	_update_markers()
	busy = false

func _choose_ending() -> void:
	player.controls_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var choice_layer := CanvasLayer.new()
	choice_layer.layer = 105
	add_child(choice_layer)
	menu = Control.new()
	choice_layer.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	menu.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	var back := PanelContainer.new()
	back.add_theme_stylebox_override("panel", StyleBoxFlat.new())
	back.get_theme_stylebox("panel").bg_color = Color(0, 0, 0)
	back.add_child(box)
	center.add_child(back)
	box.custom_minimum_size = Vector2(420, 0)
	box.add_theme_constant_override("separation", 16)
	var label := Label.new()
	label.text = "What will Mercier do?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)
	for entry in [["Hand over the criminal", "law"], ["Help the killer", "help"]]:
		var button := Button.new()
		button.text = entry[0]
		box.add_child(button)
		button.pressed.connect(_ending_selected.bind(entry[1]))

func _ending_selected(choice: String) -> void:
	menu.get_parent().queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if choice == "law":
		await _say(["ending1_law"])
		_show_end("The price of life")
	else:
		await _say(["ending2_sit", "ending2_waiter2_surprised", "ending2_help"])
		phase = "help_return"
		player.controls_locked = false
		_set_objective("Return to the kitchen, then speak to the waiter near the office.")
		_update_markers()

func _revenge_ending() -> void:
	_show_end("The price of revenge")

func _show_end(title: String) -> void:
	phase = "ended"
	player.controls_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_objective("")
	var end_layer := CanvasLayer.new()
	end_layer.layer = 99
	add_child(end_layer)
	var backdrop := TextureRect.new()
	if title == "The price of life":
		backdrop.texture = load("res://Sprites/arrest ending.png")
		end_layer.add_child(backdrop)
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await _say(["ending1_police_call"])
	else:
		backdrop.texture = load("res://Sprites/bury manager ending.png")
		end_layer.add_child(backdrop)
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await Dialogue.say_raw(["13:00", "16:00", "19:00", "22:00", "01:00", "A key turns. A body is dragged away. The sound of digging fades into the night."], "")
	var box := VBoxContainer.new()
	var back := PanelContainer.new()
	back.add_theme_stylebox_override("panel", StyleBoxFlat.new())
	back.get_theme_stylebox("panel").bg_color = Color(0, 0, 0)
	back.add_child(box)
	var center := CenterContainer.new()
	end_layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_child(back)
	box.custom_minimum_size = Vector2(420, 0)
	box.add_theme_constant_override("separation", 16)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	box.add_child(label)
	var button := Button.new()
	button.text = "Play again"
	box.add_child(button)
	music.stream = load("res://Sound/outro.mp3")
	music.play()
	button.pressed.connect(func(): get_tree().reload_current_scene())

extends Node3D

@export var prologue_sit_down: DialogueData
@export var tutorial_base: DialogueData

@onready var player = $Player
@onready var restaurant: Node3D = $Restaurant
var phase := "tutorial"
var busy := false
var seen_lenses := {}
var clues := {}
var actors := {}
var objective: Label
var prompt: Label
var menu: Control
var trail_visuals: Array[Node3D] = []
var waiter_home := Vector3(9.5, 0.65, 3.35)

func _ready() -> void:
	_build_hud()
	_build_world()
	player.global_position = restaurant.to_global(Vector3(5.2, 0.5, 5.5))
	player.interaction_requested.connect(_interact)
	player.lens_changed.connect(_lens_changed)
	_set_objective("Try the green (3), red (2), and blue (4) lenses.")
	busy = true
	await Dialogue.say(prologue_sit_down)
	await Dialogue.say(tutorial_base)
	await Dialogue.say_raw(["Move with WASD, look with the mouse, and press E to interact. Switch lenses with 1–4."], "")
	busy = false

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
	_update_markers()
	if phase != "tutorial" or lens == "base" or seen_lenses.has(lens) or busy:
		return
	seen_lenses[lens] = true
	busy = true
	await _say(["tutorial_" + lens])
	busy = false
	if seen_lenses.size() == 3:
		phase = "approach"
		_set_objective("Use the blue lens and speak to the waiter.")
		_update_markers()

func _say(ids: Array) -> void:
	for id in ids:
		var data = load("res://Dialogue/%s.tres" % id)
		if data:
			await Dialogue.say(data)

func _character(id: String, file: String, pos: Vector3, title: String, parent: Node3D = restaurant) -> void:
	var node: StaticBody3D = load("res://Scenes/Characters/%s.tscn" % file).instantiate()
	parent.add_child(node)
	node.position = pos
	node.set_meta("story_id", id)
	node.set_meta("label", title)
	node.set_meta("lens", "any")
	actors[id] = node

func _marker(id: String, title: String, pos: Vector3, lens: String, parent: Node3D = restaurant) -> void:
	var node := StaticBody3D.new()
	node.name = id
	node.collision_layer = 2
	node.collision_mask = 0
	node.set_meta("story_id", id)
	node.set_meta("label", title)
	node.set_meta("lens", lens)
	parent.add_child(node)
	node.position = pos
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.38, 0.38, 0.38)
	shape.shape = box
	node.add_child(shape)
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.25, 1, 0.4) if lens == "green" else Color(1, 0.2, 0.2) if lens == "red" else Color(1, 0.85, 0.3)
	mesh.material_override = mat
	node.add_child(mesh)
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
	_character("guest", "loyal_customer", Vector3(9.0, 0.65, 5.6), "Regular guest")
	_character("chef", "chef", Vector3(5.3, 0.65, 0.8), "Chef")
	_character("cook", "cook", Vector3(4.3, 0.65, 0.8), "Cook")
	_marker("office_door", "Office door", Vector3(9.95, 0.85, 2.9), "any")
	_marker("wallpaper", "Torn wallpaper", Vector3(10.15, 0.7, 1.8), "green")
	_marker("office_window", "Office window", Vector3(10.2, 1.05, 1.1), "green")
	_marker("office_computer", "Computer", Vector3(8.8, 0.65, 1.15), "green")
	_marker("office_shelves", "Personnel files", Vector3(7.85, 0.7, 0.4), "green")
	_marker("office_blood", "Blood", Vector3(9.8, 0.18, 1.75), "red")
	_marker("counter", "Counter", Vector3(3.0, 0.85, 3.75), "green")
	_marker("kitchen_stove", "Damaged stove", Vector3(4.3, 0.72, 0.15), "green")
	_marker("kitchen_blood", "Blood by the stove", Vector3(4.8, 0.2, 0.15), "red")
	_marker("back_door", "Service door to courtyard", Vector3(0.86, 0.8, -0.25), "any")
	# Separate placeholder spaces preserve the original restaurant geometry.
	_floor_at(Vector3(25, -0.1, 0), Vector3(6, 0.2, 5), Color(0.32, 0.29, 0.25))
	_floor_at(Vector3(25, 0.9, -2.4), Vector3(6, 1.8, 0.2), Color(0.4, 0.34, 0.3))
	_floor_at(Vector3(22.1, 0.9, 0), Vector3(0.2, 1.8, 5), Color(0.35, 0.29, 0.25))
	_floor_at(Vector3(27.9, 0.9, 0), Vector3(0.2, 1.8, 5), Color(0.35, 0.29, 0.25))
	_marker("closet_exit", "Return to office", Vector3(25, 0.8, 1.8), "any", self)
	_marker("safe", "Empty safe", Vector3(23.2, 0.8, -1), "green", self)
	_marker("keys", "Keys", Vector3(25.9, 0.4, -0.5), "green", self)
	_marker("storage_blood", "Blood on shelves", Vector3(26.5, 0.9, -1), "red", self)
	_character("body", "manager", Vector3(25, 0.45, -0.8), "Manager", self)
	actors.body.rotation.z = PI / 2
	_floor_at(Vector3(40, -0.1, 0), Vector3(12, 0.2, 24), Color(0.26, 0.39, 0.24))
	for tree_pos in [Vector3(36, 0.8, 3), Vector3(44, 0.8, 1), Vector3(37, 0.8, -4), Vector3(42.5, 0.8, -8)]:
		_floor_at(tree_pos, Vector3(0.5, 1.6, 0.5), Color(0.28, 0.19, 0.12))
	for z in [6.0, 3.0, 0.0, -3.0, -6.0]:
		var drop := MeshInstance3D.new()
		var drop_mesh := BoxMesh.new()
		drop_mesh.size = Vector3(0.2, 0.03, 0.35)
		drop.mesh = drop_mesh
		var drop_mat := StandardMaterial3D.new()
		drop_mat.albedo_color = Color(0.8, 0.05, 0.05)
		drop.material_override = drop_mat
		add_child(drop)
		drop.position = Vector3(40, 0.03, z)
		trail_visuals.append(drop)
	_marker("park_exit", "Return to kitchen", Vector3(40, 0.8, 9), "any", self)
	_marker("trail", "Blood trail", Vector3(40, 0.2, 4), "red", self)
	_marker("possessions", "Documents, money and knife", Vector3(41, 0.45, -7), "green", self)
	_character("waiter2", "waiter_two", Vector3(40, 0.65, -7), "Waiter #2", self)
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
		var is_character: bool = id in ["waiter1", "waiter2", "guest", "chef", "cook", "body"]
		node.visible = available and (is_character or lens == "any" or lens == player.lens)
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
				await _say(["waiter1_panic", "detective_suppose", "waiter1_thief_report", "detective_call_police", "waiter1_plea", "detective_follow"])
				phase = "lead"
				_set_objective("Follow the waiter to the office door.")
				var tween := create_tween()
				tween.tween_property(actors.waiter1, "position", waiter_home, 4.0)
			elif phase == "hall":
				await _say(["hall_waiter_asks", "hall_detective_reply", "hall_waiter_suggests", "hall_detective_thoughts"])
				phase = "investigate"
				_set_objective("Question the regular guest and the chef with the blue lens.")
			elif phase == "help_return":
				await _say(["ending2_waiter1_thief", "ending2_detective_reply", "ending2_waiter1_hesitate", "ending2_detective_responsibility"])
				await _revenge_ending()
			elif phase == "investigate":
				await _say(["waiter1_q_runner", "waiter1_a_runner"])
		"office_door":
			if phase == "lead":
				await _say(["office_door_waiter", "office_enter"])
				phase = "office"
				_set_objective("Search the office. Try the green lens on the torn wallpaper.")
				_travel(restaurant.to_global(Vector3(9.85, 0.5, 2.0)))
			elif phase == "office" and clues.has("body"):
				_travel(restaurant.to_global(Vector3(9.95, 0.5, 3.25)))
				phase = "hall"
				_set_objective("Speak to the waiter outside the office with the blue lens.")
			elif phase == "office":
				await Dialogue.say_raw(["I should search the office before leaving."], "Detective")
		"wallpaper":
			clues.wallpaper = true
			_travel(Vector3(25, 0.5, 1.0))
			await _say(["storage_body_reveal"])
			_set_objective("Search the hidden storeroom. Examine the manager with the blue lens.")
		"closet_exit":
			_travel(restaurant.to_global(Vector3(9.7, 0.5, 1.75)))
			_set_objective("Search the office, then use the office door to return to the hall.")
		"body":
			clues.body = true
			await _say(["storage_body"])
			_set_objective("Search for evidence, then return to the hall through the office door.")
		"safe", "keys", "storage_blood", "office_window", "office_computer", "office_shelves", "office_blood":
			clues[id] = true
			await _say(["storage_safe" if id == "safe" else "storage_keys" if id == "keys" else id])
		"counter":
			await Dialogue.say_raw(["The register and fittings show ordinary wear."], "Detective")
		"kitchen_stove":
			await Dialogue.say_raw(["The damage around the stove looks like the remains of an explosion."], "Detective")
		"kitchen_blood":
			await Dialogue.say_raw(["A faint streak of blood near the damaged wall."], "Detective")
		"guest":
			if phase == "investigate":
				await _say(["guest_q", "guest_a"])
				clues.guest = true
		"chef":
			if phase == "investigate":
				await _say(["chef_q", "chef_a"])
				clues.chef = true
		"cook":
			if phase == "investigate" and clues.has("chef"):
				await _say(["cook_scared", "cook_detective_pardon", "cook_reply"])
		"back_door":
			if phase == "investigate" and clues.has("guest") and clues.has("chef"):
				phase = "park"
				_travel(Vector3(40, 0.5, 8))
				_set_objective("Follow the blood trail into the park with the red lens.")
			else:
				await Dialogue.say_raw(["I should speak to the regular guest and the chef first."], "Detective")
		"park_exit":
			_travel(restaurant.to_global(Vector3(1.0, 0.5, 0.45)))
			if phase == "help_return": _set_objective("Return to the waiter by the office and speak to him.")
		"trail":
			await Dialogue.say_raw(["Blood leads from the office window into the park."], "Detective")
			_set_objective("Follow the trail, then use the blue lens to speak to the figure in the park.")
		"possessions":
			await Dialogue.say_raw(["Documents, money, and a knife. He took them from the restaurant."], "Detective")
		"waiter2":
			if phase == "park":
				await _say(["park_waiter2_confession", "park_detective_silence", "park_waiter2_plea", "park_detective_backstory"])
				await _choose_ending()
	if phase == "investigate" and clues.has("guest") and clues.has("chef"):
		_set_objective("Explore the kitchen or use the service door to reach the courtyard.")
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
	center.add_child(box)
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
		_travel(Vector3(40, 0.5, 8))
		await _say(["ending1_police_call"])
		_show_end("The price of life")
	else:
		await _say(["ending2_sit", "ending2_waiter2_surprised", "ending2_help"])
		phase = "help_return"
		player.controls_locked = false
		_set_objective("Return to the kitchen, then speak to the waiter near the office.")
		_update_markers()

func _revenge_ending() -> void:
	player.controls_locked = true
	await Dialogue.say_raw(["13:00", "16:00", "19:00", "22:00", "01:00", "A key turns. A body is dragged away. The sound of digging fades into the night."], "")
	_show_end("The price of revenge")

func _show_end(title: String) -> void:
	phase = "ended"
	player.controls_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_set_objective("")
	var end_layer := CanvasLayer.new()
	end_layer.layer = 110
	add_child(end_layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color.BLACK
	end_layer.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := VBoxContainer.new()
	var center := CenterContainer.new()
	end_layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.add_child(box)
	box.custom_minimum_size = Vector2(420, 0)
	box.add_theme_constant_override("separation", 16)
	var label := Label.new()
	label.text = "End: " + title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	box.add_child(label)
	var button := Button.new()
	button.text = "Play again"
	box.add_child(button)
	button.pressed.connect(func(): get_tree().reload_current_scene())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not player.controls_locked:
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

extends CanvasLayer

signal dialogue_started(dialogue: DialogueData)
signal dialogue_finished(dialogue: DialogueData)
signal line_started(index: int)

const CHARS_PER_SECOND := 30.0
const PUNCT_PAUSE := 0.12
const FONT_SIZE := 28

var active := false

var _current: DialogueData
var _lines: Array = []
var _index := 0
var _typing := false
var _progress := 0.0
var _pause := 0.0

var _blink_timer: Timer
var _root: Control
var _label: Label
var _name_row: HBoxContainer
var _name_label: Label
var _arrow: Control

func say(dialogue: DialogueData, speaker: String = "") -> void:
	if active or dialogue == null:
		return
	_current = dialogue
	_lines = dialogue.lines
	_index = 0
	active = true

	var who := speaker if speaker != "" else dialogue.speaker
	VoiceSynth.set_voice(who)
	_name_label.text = who
	_name_row.visible = who != ""
	_root.show()

	dialogue_started.emit(dialogue)
	_show_line()
	await dialogue_finished

func say_raw(lines: Array, speaker: String = "") -> void:
	var d := DialogueData.new()
	d.lines.assign(lines)
	d.speaker = speaker
	await say(d)

func _ready() -> void:
	layer = 100
	_build_ui()
	_root.hide()

class Arrow extends Control:
	var lit: bool = true:
		set(value):
			lit = value
			queue_redraw()

	func _draw() -> void:
		if not lit:
			return
		var w := 20.0
		var h := 14.0
		var x := size.x - w - 20.0
		var y := size.y - h - 16.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, y), Vector2(x + w, y), Vector2(x + w / 2.0, y + h)
		]), Color.WHITE)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

func _build_ui() -> void:
	_root = Control.new()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var margin := MarginContainer.new()
	_root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 30)
	margin.add_theme_constant_override("margin_top", 30)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)
	vbox.alignment = BoxContainer.ALIGNMENT_END
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", -4)

	_name_row = HBoxContainer.new()
	vbox.add_child(_name_row)
	_name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_row.z_index = 1

	var name_panel := PanelContainer.new()
	_name_row.add_child(name_panel)
	name_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var spacer := Control.new()
	_name_row.add_child(spacer)
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var name_style := StyleBoxFlat.new()
	name_style.bg_color = Color.BLACK
	name_style.border_color = Color.WHITE
	name_style.border_width_left = 4
	name_style.border_width_top = 4
	name_style.border_width_right = 4
	name_style.border_width_bottom = 0
	name_panel.add_theme_stylebox_override("panel", name_style)

	var name_pad := MarginContainer.new()
	name_panel.add_child(name_pad)
	name_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_pad.add_theme_constant_override("margin_left", 20)
	name_pad.add_theme_constant_override("margin_right", 20)
	name_pad.add_theme_constant_override("margin_top", 8)
	name_pad.add_theme_constant_override("margin_bottom", 12)

	_name_label = Label.new()
	name_pad.add_child(_name_label)
	_name_label.add_theme_font_size_override("font_size", FONT_SIZE - 4)
	_name_label.add_theme_color_override("font_color", Color.WHITE)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	vbox.add_child(panel)
	panel.custom_minimum_size = Vector2(0, 170)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style := StyleBoxFlat.new()
	style.bg_color = Color.BLACK
	style.border_color = Color.WHITE
	style.set_border_width_all(4)
	panel.add_theme_stylebox_override("panel", style)

	var pad := MarginContainer.new()
	panel.add_child(pad)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_top", 16)
	pad.add_theme_constant_override("margin_bottom", 16)

	_label = Label.new()
	pad.add_child(_label)
	_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_arrow = Arrow.new()
	panel.add_child(_arrow)
	_arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arrow.hide()

	_blink_timer = Timer.new()
	add_child(_blink_timer)
	_blink_timer.wait_time = 0.5
	_blink_timer.timeout.connect(func(): _arrow.lit = not _arrow.lit)

func _show_line() -> void:
	line_started.emit(_index)
	_label.text = str(_lines[_index])
	_label.visible_characters = 0
	_progress = 0.0
	_pause = 0.0
	_typing = true
	_arrow.hide()
	_blink_timer.stop()

func _next() -> void:
	_index += 1
	if _index >= _lines.size():
		active = false
		_root.hide()
		dialogue_finished.emit(_current)
	else:
		_show_line()

func _finish_typing() -> void:
	_label.visible_characters = -1
	_typing = false
	_arrow.lit = true
	_arrow.show()
	_blink_timer.start()

func _process(delta: float) -> void:
	if not _typing:
		return

	if _pause > 0.0:
		_pause -= delta
		return

	_progress += delta * CHARS_PER_SECOND
	var total := _label.text.length()
	var target := mini(int(_progress), total)

	while _label.visible_characters < target:
		var ch := _label.text[_label.visible_characters]
		_label.visible_characters += 1
		VoiceSynth.play_for(ch)
		if ch in ".,!?;:":
			_pause = PUNCT_PAUSE
			break

	if _label.visible_characters >= total:
		_finish_typing()

func _input(event: InputEvent) -> void:
	if not active:
		return

	var pressed: bool = event.is_action_pressed("ui_accept")

	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			pressed = true

	if not pressed:
		return

	get_viewport().set_input_as_handled()
	if _typing:
		_finish_typing()
	else:
		_next()

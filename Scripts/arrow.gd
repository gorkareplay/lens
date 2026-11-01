extends Sprite3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.set_meta("lens", "blue")
	add_to_group("blue_lens_arrows")
	visible = false

func set_blue_lens_active(active: bool) -> void:
	visible = active

extends "res://src/mob.gd"
## Ghost: floats toward the player on a sine wave, ignores gravity. HP 3, touch 2.

var _base_y := 0.0


func _ready() -> void:
	super()
	use_gravity = false
	use_slide = false
	_base_y = global_position.y


func behave(_delta: float) -> void:
	var px := player_x()
	facing = 1.0 if px > global_position.x else -1.0
	velocity.x = facing * 25.0
	# Steer toward a hover line that bobs around the player's height.
	var target_y: float = _base_y + sin(elapsed * 2.2) * 24.0 - 30.0
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		target_y = player.global_position.y - 46.0 + sin(elapsed * 2.2) * 16.0
	velocity.y = clampf((target_y - global_position.y) * 2.0, -40.0, 40.0)

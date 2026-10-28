extends "res://src/mob.gd"
## Vampire kid: patrols, then dashes a short burst when the player is near. HP 8, touch 4.

var _dash_timer := 2.0
var _dash_time := 0.0


func _ready() -> void:
	super()
	speed = 32.0
	patrol_range = 90.0


func behave(delta: float) -> void:
	_dash_timer -= delta
	if _dash_timer <= 0.0:
		_dash_timer = 3.0
		if absf(player_x() - global_position.x) < 150.0:
			_dash_time = 0.25
			facing = 1.0 if player_x() > global_position.x else -1.0
	if _dash_time > 0.0:
		_dash_time -= delta
		velocity.x = facing * 150.0
		return
	super(delta)

extends "res://src/mob.gd"
## Slime: slow goofy hops toward the player. HP 2, touch damage 2 (see rules.gd).

var _hop_timer := 0.0


func _ready() -> void:
	super()
	speed = 30.0
	patrol_range = 60.0


func behave(_delta: float) -> void:
	if is_on_floor():
		velocity.x = 0.0
		_hop_timer -= _delta
		if _hop_timer <= 0.0:
			_hop_timer = 1.2
			facing = 1.0 if player_x() > global_position.x else -1.0
			velocity.y = -140.0
			velocity.x = facing * speed
	else:
		velocity.x = facing * speed

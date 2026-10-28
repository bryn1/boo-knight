extends "res://src/mob.gd"
## Zombie: shuffles a slow patrol beat. HP 4, touch 3.

func _ready() -> void:
	super()
	speed = 18.0
	patrol_range = 80.0

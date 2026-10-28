extends "res://src/mob.gd"
## Skeleton: patrols faster than the zombie. HP 6, touch 3.

func _ready() -> void:
	super()
	speed = 45.0
	patrol_range = 100.0

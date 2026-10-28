extends "res://src/mob.gd"
## Boss: paces the arena fast. HP 10, touch 6 — dying to it is the win condition.

func _ready() -> void:
	super()
	speed = 75.0
	patrol_range = 130.0

extends "res://src/mob.gd"
## Gauntlet boss 1: paces the arena fast. T6b amendment (MC 11740): HP 6,
## touch 3; killing him no longer wins the game — the king ladder begins.

func _ready() -> void:
	super()
	speed = 75.0
	patrol_range = 130.0

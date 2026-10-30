extends "res://src/mobs/slime.gd"
## Gauntlet boss 1 (T6b, MC 11740): the Slime King moves like its mob kind —
## big squash-bounce hops toward the player (rules.gd: hp 8, touch 3).

func _ready() -> void:
	super()
	speed = 38.0
	patrol_range = 110.0

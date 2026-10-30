extends "res://src/mobs/skeleton.gd"
## Gauntlet boss 4 (T6b, MC 11740): the Skeleton King marches like its mob kind
## (rules.gd: hp 10, touch 4).

func _ready() -> void:
	super()
	speed = 55.0
	patrol_range = 120.0

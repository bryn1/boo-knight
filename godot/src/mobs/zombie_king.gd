extends "res://src/mobs/zombie.gd"
## Gauntlet boss 3 (T6b, MC 11740): the Zombie King shambles like its mob kind
## (rules.gd: hp 9, touch 4).

func _ready() -> void:
	super()
	speed = 24.0
	patrol_range = 110.0

extends Area2D
## Treasure chest: touching it upgrades the player's sword via rules.gd —
## only if the contained sword is STRICTLY better; worse/equal is ignored.
## The chest stays in the world, dimmed once looted. Gauntlet chests (T7b,
## gauntlet_depth > 0) carry the per-depth loot law instead: an enchanted
## diamond sword for depths 1..5, bread beyond that.

var chest_level := 1  # level number; rules.CHEST_SWORD maps it to a sword
var gauntlet_depth := 0  # > 0 = gauntlet chest; rules.GAUNTLET_CHEST maps it to loot


func _ready() -> void:
	collision_mask = 2  # player
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var looted := GameState.touch_gauntlet_chest(gauntlet_depth) \
		if gauntlet_depth > 0 else GameState.touch_chest(chest_level)
	if looted:
		modulate = Color(0.7, 0.7, 0.7, 1.0)

extends Area2D
## Treasure chest: touching it upgrades the player's sword via rules.gd —
## only if the contained sword is STRICTLY better; worse/equal is ignored.
## The chest stays in the world, dimmed once looted.

var chest_level := 1  # level number; rules.CHEST_SWORD maps it to a sword


func _ready() -> void:
	collision_mask = 2  # player
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if GameState.touch_chest(chest_level):
		modulate = Color(0.7, 0.7, 0.7, 1.0)

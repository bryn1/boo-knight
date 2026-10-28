extends Area2D
## Level exit portal (levels 1-2). Entering it finishes the level.

signal reached


func _ready() -> void:
	collision_mask = 2  # player
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		reached.emit()

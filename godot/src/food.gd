extends Area2D
## Food pickup: apple heals +5, bread +10 (rules.gd table), capped at 30 HP.

const Rules := preload("res://src/rules.gd")

var kind := "apple"  # set by the level builder; must be a rules.gd FOOD_HEAL key


func _ready() -> void:
	collision_mask = 2  # player
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	GameState.eat(kind)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.6, 1.6), 0.12)
	t.parallel().tween_property(self, "modulate:a", 0.0, 0.12)
	t.tween_callback(queue_free)

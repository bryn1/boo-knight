extends CharacterBody2D
## Base mob: HP and contact damage from rules.gd, white hit-flash, knockback,
## poof-out death. Movement behavior is overridden in src/mobs/*.gd subclasses
## (all contact-damage only — mobs never shoot projectiles).

signal died(mob_type: String)

const Rules := preload("res://src/rules.gd")
const Art := preload("res://src/art.gd")

const GRAVITY := 620.0
const MAX_FALL := 400.0

var mob_type := "slime"
var hp := 2
var touch_dmg := 2
var speed := 20.0
var patrol_range := 70.0
var use_gravity := true
var use_slide := true  # ghosts steer directly and check touch by radius
var facing := -1.0
var elapsed := 0.0
var patrol_home := Vector2.ZERO
var _sprite: Sprite2D
var _dead := false


func setup(type: String) -> void:
	mob_type = type
	hp = Rules.mob_hp(type)
	touch_dmg = Rules.mob_touch_damage(type)


func _enter_tree() -> void:
	patrol_home = position


func _ready() -> void:
	_sprite = get_node_or_null("Sprite2D") as Sprite2D


func _physics_process(delta: float) -> void:
	if _dead:
		return
	elapsed += delta
	behave(delta)
	if use_slide:
		if use_gravity:
			velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
		move_and_slide()
		_check_slide_touch()
	else:
		global_position += velocity * delta
		_check_radius_touch()


## Default behavior: walk a patrol beat around the spawn point.
func behave(_delta: float) -> void:
	if global_position.x > patrol_home.x + patrol_range:
		facing = -1.0
	elif global_position.x < patrol_home.x - patrol_range:
		facing = 1.0
	velocity.x = facing * speed


func take_damage(dmg: int, from_x: float) -> void:
	if _dead:
		return
	hp -= dmg
	var away := signf(global_position.x - from_x)
	if away == 0.0:
		away = -facing
	velocity = Vector2(away * 90.0, -120.0)
	_flash()
	if hp <= 0:
		_poof()


func _flash() -> void:
	if _sprite == null:
		return
	var t := create_tween()
	t.tween_property(_sprite, "modulate", Color(4, 4, 4, 1), 0.05)
	t.tween_property(_sprite, "modulate", Color(1, 1, 1, 1), 0.1)


func _poof() -> void:
	_dead = true
	set_collision_layer(0)
	set_collision_mask(0)
	died.emit(mob_type)
	if _sprite != null:
		_sprite.flip_h = false
		var t := create_tween()
		t.tween_property(self, "scale", Vector2(0.01, 0.01), 0.25)
		t.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
		t.tween_callback(queue_free)
	else:
		queue_free()


func _check_slide_touch() -> void:
	for i in get_slide_collision_count():
		var body := get_slide_collision(i).get_collider()
		if body != null and body.is_in_group("player") and body.has_method("take_hit"):
			body.take_hit(touch_dmg, global_position.x)


func _check_radius_touch() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not player.has_method("take_hit"):
		return
	var reach := (Art.display_size(mob_type).x + 20.0) * 0.5
	if global_position.distance_to(player.global_position - Vector2(0, 22)) < reach:
		player.take_hit(touch_dmg, global_position.x)


func player_x() -> float:
	var player := get_tree().get_first_node_in_group("player")
	return player.global_position.x if player != null else global_position.x

extends CharacterBody2D
## The kid knight: forgiving SMB-style movement (coyote time, jump buffering,
## variable jump height), sword swing with 0.35 s cooldown, 0.8 s i-frames +
## knockback after contact damage, and Rules.SPAWN_GRACE s of blinking contact
## immunity on every fresh spawn. Nodes are built by src/factory.gd.

const Rules := preload("res://src/rules.gd")
const Art := preload("res://src/art.gd")

const SPEED := 95.0
const JUMP_VELOCITY := -245.0
const GRAVITY := 680.0
const COYOTE_TIME := 0.10
const JUMP_BUFFER := 0.12
const ATTACK_ACTIVE := 0.12
const FALL_DAMAGE_Y := 460.0

var facing := 1.0
var attack_area: Area2D  # assigned by factory

var _coyote := 0.0
var _buffer := 0.0
var _cooldown := 0.0
var _attack_time := 0.0
var _invuln := 0.0
var _sprite: Sprite2D


func _ready() -> void:
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	_invuln = Rules.SPAWN_GRACE  # a fresh spawn (run or level start) blinks, un-hittable
	attack_area.body_entered.connect(_on_attack_hit)


## Sword arc connects with a mob: sword damage + knockback (mob flashes/poofs).
func _on_attack_hit(body: Node) -> void:
	if body.is_in_group("mob") and body.has_method("take_damage"):
		body.take_damage(Rules.sword_damage(GameState.sword), global_position.x)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		_coyote -= delta
	else:
		_coyote = COYOTE_TIME
		if velocity.y > 0.0:
			velocity.y = 0.0  # cancel landing impulse for stable feel

	var dir := Input.get_axis("move_left", "move_right")
	velocity.x = dir * SPEED
	if dir != 0.0:
		facing = signf(dir)

	_buffer -= delta
	if Input.is_action_just_pressed("jump"):
		_buffer = JUMP_BUFFER
	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_buffer = 0.0
		_coyote = 0.0
	if not Input.is_action_pressed("jump") and velocity.y < -80.0:
		velocity.y = -80.0  # short hop when the key is released early

	_cooldown -= delta
	if Input.is_action_just_pressed("attack") and _cooldown <= 0.0:
		_cooldown = Rules.ATTACK_COOLDOWN
		_attack_time = ATTACK_ACTIVE
	if _attack_time > 0.0:
		_attack_time -= delta
		attack_area.monitoring = true
		attack_area.position = Vector2(17.0 * facing, -24.0)
	else:
		attack_area.monitoring = false

	_invuln -= delta
	if _sprite != null:
		var visible_now := 1.0 if _invuln <= 0.0 or int(_invuln * 20.0) % 2 == 0 else 0.25
		_sprite.modulate.a = visible_now

	if _sprite != null:
		_sprite.flip_h = facing < 0.0

	move_and_slide()


## Called by mobs on contact (mob.gd / ghost radius check).
func take_hit(dmg: int, from_x: float) -> void:
	if _invuln > 0.0 or GameState.hearts <= 0:
		return
	_invuln = Rules.INVULN_TIME
	var away := signf(global_position.x - from_x)
	if away == 0.0:
		away = -facing
	velocity = Vector2(away * 130.0, -150.0)
	GameState.damage_player(dmg)

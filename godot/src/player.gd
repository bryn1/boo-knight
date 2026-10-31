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
const WALK_FPS := 7.0
const SWORD_FPS := 8.0  # enchanted held-sword cycle (T7b law 4, like the kings' MOVE_ANIM)

var facing := 1.0
var attack_area: Area2D  # assigned by factory

var _coyote := 0.0
var _buffer := 0.0
var _cooldown := 0.0
var _attack_time := 0.0
var _invuln := 0.0
var _sprite: Sprite2D
var _walk_frames: Array[Texture2D]
var _attack_frames: Array[Texture2D]
var _idle_tex: Texture2D
var _anim_t := 0.0
var _atk_t := 0.0
var _sword_sprite: Sprite2D
var _sword_key := "sword_wood"
var _sword_frames: Array[Texture2D] = []
var _sword_t := 0.0


func _ready() -> void:
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	_walk_frames = Art.frames_for("hero_walk")
	_attack_frames = Art.frames_for("hero_attack")
	_idle_tex = Art.texture_for("hero")
	_invuln = Rules.SPAWN_GRACE  # a fresh spawn (run or level start) blinks, un-hittable
	attack_area.body_entered.connect(_on_attack_hit)
	_sword_sprite = Art.make_sprite(String(Rules.SWORDS[GameState.sword]["icon"]))
	_sword_sprite.name = "HeldSword"  # keep "Sprite2D" unique for get_node_or_null lookups
	_sword_sprite.position = Vector2(11, -14)
	add_child(_sword_sprite)  # after the hero sprite: the blade paints in front
	_refresh_sword(GameState.sword)
	GameState.sword_changed.connect(_refresh_sword)


## Held-sword sprite follows the sword law (T7b): plain swords sit static on
## their base frame; enchanted diamond swords cycle their _a/_b element anim
## while held (~8 fps, same mechanism as the kings' MOVE_ANIM).
func _refresh_sword(sword_id: String) -> void:
	_sword_key = String(Rules.SWORDS[sword_id]["icon"])
	if Art.has_anim(_sword_key):
		_sword_frames = Art.frames_for(_sword_key)
	else:
		_sword_frames.assign([Art.texture_for(_sword_key)])  # plain swords sit static
	_sword_t = 0.0
	Art.apply_frame(_sword_sprite, _sword_key, _sword_frames[0])


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
		_atk_t = 0.0
	if _attack_time > 0.0:
		_attack_time -= delta
		# _physics_process runs inside the physics flush; toggling monitoring
		# directly errors in the web build (MC 11798). Defer both branches.
		attack_area.set_deferred("monitoring", true)
		attack_area.position = Vector2(17.0 * facing, -24.0)
	else:
		attack_area.set_deferred("monitoring", false)

	_invuln -= delta
	if _sprite != null:
		var visible_now := 1.0 if _invuln <= 0.0 or int(_invuln * 20.0) % 2 == 0 else 0.25
		_sprite.modulate.a = visible_now
		_update_frame(dir, delta)

	if _sprite != null:
		_sprite.flip_h = facing < 0.0  # art faces right; visuals only, hitbox uses facing

	_sword_sprite.flip_h = facing < 0.0
	_sword_sprite.position.x = 11.0 * facing
	if _sword_frames.size() > 1:  # enchanted: cycle the element frames while held
		_sword_t += delta
		Art.apply_frame(_sword_sprite, _sword_key,
			_sword_frames[int(_sword_t * SWORD_FPS) % _sword_frames.size()])

	move_and_slide()


## Visual only: idle frame standing, walk cycle (~WALK_FPS) grounded+moving,
## attack a->b across the existing ATTACK_ACTIVE window. Frame lists fall back
## to the single base texture when the PNGs are missing, so the look is then
## identical to pre-animation.
func _update_frame(dir: float, delta: float) -> void:
	var frames: Array[Texture2D] = _walk_frames
	var idx := 0
	if _attack_time > 0.0:
		_atk_t += delta
		frames = _attack_frames
		idx = clampi(int(_atk_t / (ATTACK_ACTIVE / float(frames.size()))), 0, frames.size() - 1)
	elif is_on_floor() and dir != 0.0:
		_anim_t += delta
		idx = int(_anim_t * WALK_FPS) % frames.size()
	else:
		_anim_t = 0.0
		frames = [_idle_tex]
	Art.apply_frame(_sprite, "hero", frames[idx])


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

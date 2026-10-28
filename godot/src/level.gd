extends Node2D
## Hand-built level assembly from a data dictionary (see LEVELS in game.gd):
## ground as a TileMapLayer using tile_ground.png as the 16 px TileSet source,
## physics platforms, parallax night background, entities, camera limits.

signal level_done
signal boss_died

const Art := preload("res://src/art.gd")

const TILE := 16
const TILE_ROWS := 4  # ground thickness below the surface row
const MOB_SCRIPTS := {
	"slime": preload("res://src/mobs/slime.gd"),
	"ghost": preload("res://src/mobs/ghost.gd"),
	"zombie": preload("res://src/mobs/zombie.gd"),
	"skeleton": preload("res://src/mobs/skeleton.gd"),
	"vampire": preload("res://src/mobs/vampire.gd"),
	"vampire_lord": preload("res://src/mobs/vampire_lord.gd"),
}

var data: Dictionary = {}
var player: CharacterBody2D


func setup(level_data: Dictionary) -> void:
	data = level_data


func _ready() -> void:
	_build_background()
	_build_ground()
	_spawn_player()
	_spawn_entities()


func _build_background() -> void:
	var bg := ParallaxBackground.new()
	var layer := ParallaxLayer.new()
	layer.motion_scale = Vector2(0.35, 0.6)
	layer.motion_mirroring = Vector2(1280, 0)
	var sp := Sprite2D.new()
	sp.texture = Art.texture_for("bg_night")
	sp.centered = false
	var s := 1280.0 / float(sp.texture.get_width())  # cover the canvas with drift room
	sp.scale = Vector2(s, s)
	layer.add_child(sp)
	bg.add_child(layer)
	add_child(bg)
	move_child(bg, 0)


func _build_ground() -> void:
	var tml := TileMapLayer.new()
	tml.tile_set = _make_tile_set()
	add_child(tml)
	for seg in data["segments"]:
		var x0 := int(seg[0])
		var x1 := int(seg[1])
		var top := int(seg[2])
		for tx in range(x0, x1 + 1):
			for ty in range(top, top + TILE_ROWS):
				tml.set_cell(Vector2i(tx, ty), 0, Vector2i.ZERO)
		_add_solid(
			Vector2((x0 + x1 + 1) * TILE * 0.5, top * TILE + TILE_ROWS * TILE * 0.5),
			Vector2((x1 - x0 + 1) * TILE, TILE_ROWS * TILE))
	for wall in data.get("walls", []):
		# wall = [tile_x, top_row]; collider spans top_row .. ground surface row 19.
		var top := float(int(wall[1]) * TILE)
		var bottom := float(19 * TILE)
		_add_solid(Vector2(int(wall[0]) * TILE + TILE * 0.5, (top + bottom) * 0.5),
			Vector2(TILE, bottom - top))


func _make_tile_set() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var src := TileSetAtlasSource.new()
	src.texture = Art.texture_for("tile_ground")
	src.texture_region_size = Vector2i(TILE, TILE)
	src.create_tile(Vector2i.ZERO)
	ts.add_source(src, 0)
	return ts


func _add_solid(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = center
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func _spawn_player() -> void:
	var p := CharacterBody2D.new()
	p.set_script(preload("res://src/player.gd"))
	p.add_to_group("player")
	p.name = "Player"
	p.collision_layer = 2
	p.collision_mask = 1 | 8
	var start: Vector2 = data["start"]
	p.position = Vector2(start.x * TILE + TILE * 0.5, start.y * TILE - 24.0)
	var sp := Art.make_sprite("hero")
	p.add_child(sp)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 46)
	shape.shape = rect
	p.add_child(shape)
	var attack := Area2D.new()
	attack.collision_layer = 0
	attack.collision_mask = 8
	attack.monitoring = false
	var ashape := CollisionShape2D.new()
	var arect := RectangleShape2D.new()
	arect.size = Vector2(26, 22)
	ashape.shape = arect
	attack.add_child(ashape)
	p.add_child(attack)
	p.attack_area = attack
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.limit_left = 0
	cam.limit_right = int(data["width_tiles"]) * TILE
	cam.limit_top = -120
	cam.limit_bottom = 480
	p.add_child(cam)
	add_child(p)
	player = p


func _spawn_entities() -> void:
	for f in data.get("foods", []):
		# food entry = [kind, tile]; they always rest on the ground row 19.
		_spawn_pickup(preload("res://src/food.gd"), "food_" + String(f[0]), String(f[0]), f[1], 19)
	var chest_tile: Variant = data.get("chest_tile", null)
	if chest_tile != null:
		var chest := _spawn_pickup(preload("res://src/chest.gd"), "chest", "", chest_tile, 19)
		chest.chest_level = int(data["index"])
	var exit_tile: Variant = data.get("exit_tile", null)
	if exit_tile != null:
		var door := Area2D.new()
		door.set_script(preload("res://src/door.gd"))
		door.position = Vector2(int(exit_tile) * TILE, 19 * TILE - 20)
		var dshape := CollisionShape2D.new()
		var drect := RectangleShape2D.new()
		drect.size = Vector2(14, 44)
		dshape.shape = drect
		door.add_child(dshape)
		var mark := Sprite2D.new()
		mark.texture = Art.texture_for("chest")  # placeholder stand-in until an art pass adds a door sprite
		mark.modulate = Color(0.4, 1.0, 0.6, 1.0)
		door.add_child(mark)
		add_child(door)
		door.reached.connect(func() -> void: level_done.emit())
	for m in data.get("mobs", []):
		var mob := _spawn_mob(String(m[0]), m[1], m[2])
		mob.died.connect(_on_mob_died)


func _spawn_mob(mtype: String, tx: int, row: int) -> CharacterBody2D:
	var mob := CharacterBody2D.new()
	mob.set_script(MOB_SCRIPTS[mtype])
	mob.add_to_group("mob")
	mob.collision_layer = 8
	mob.collision_mask = 1 | 2
	mob.position = Vector2(tx * TILE + TILE * 0.5, row * TILE)
	mob.setup(mtype)
	var size: Vector2 = Art.display_size(mtype)
	mob.position.y -= size.y * 0.5
	var sp := Art.make_sprite(mtype)
	mob.add_child(sp)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(size.x * 0.8, size.y * 0.9)
	shape.shape = rect
	mob.add_child(shape)
	add_child(mob)
	return mob


func _spawn_pickup(script: GDScript, key: String, kind: String, tx: Variant, row: int) -> Area2D:
	var node := Area2D.new()
	node.set_script(script)
	node.position = Vector2(int(tx) * TILE + TILE * 0.5, row * TILE - Art.display_size(key).y * 0.5)
	if kind != "":
		node.kind = kind
	var sp := Art.make_sprite(key)
	node.add_child(sp)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	var s: Vector2 = Art.display_size(key)
	rect.size = Vector2(s.x, s.y)
	shape.shape = rect
	node.add_child(shape)
	add_child(node)
	return node


func _on_mob_died(mtype: String) -> void:
	if mtype == "vampire_lord":
		boss_died.emit()

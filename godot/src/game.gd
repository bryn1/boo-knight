extends Node2D
## Game root (main scene): title screen -> levels 1..3 -> victory, with a
## GAME OVER screen that restarts the WHOLE game (level 1, wooden sword,
## 30 hearts) on SPACE. Levels are hand-built data, assembled by src/level.gd.

const Art := preload("res://src/art.gd")
const Rules := preload("res://src/rules.gd")
const LevelScript := preload("res://src/level.gd")
const HudScript := preload("res://src/hud.gd")

const STATE_TITLE := 0
const STATE_PLAYING := 1
const STATE_GAME_OVER := 2
const STATE_VICTORY := 3

## Hand-built side-scroller maps. Ground row 19 (y=304); segments are
## [x0, x1, top_row] tile ranges; entities are [type, tile_x, row].
const LEVELS: Array[Dictionary] = [
	{
		"width_tiles": 228,
		"start": Vector2i(2, 19),
		"segments": [[0, 57, 19], [61, 85, 19], [89, 150, 19], [154, 227, 19]],
		"foods": [["apple", 10], ["apple", 24], ["bread", 70], ["apple", 96],
			["apple", 120], ["bread", 168], ["apple", 200]],
		# Kid-friendly layout: no mob within reach of the spawn tiles (0-12).
		"mobs": [["slime", 44, 19], ["slime", 52, 19], ["slime", 66, 19],
			["ghost", 78, 16], ["slime", 95, 19], ["zombie", 110, 19],
			["slime", 130, 19], ["ghost", 142, 16], ["zombie", 162, 19],
			["slime", 184, 19]],
		"chest_tile": 172,
		"exit_tile": 222,
	},
	{
		"width_tiles": 240,
		"start": Vector2i(2, 19),
		"segments": [[0, 70, 19], [74, 110, 19], [114, 170, 19], [174, 239, 19]],
		"foods": [["apple", 12], ["apple", 40], ["bread", 88], ["apple", 118],
			["apple", 140], ["bread", 186], ["apple", 214]],
		"mobs": [["zombie", 20, 19], ["slime", 34, 19], ["ghost", 48, 16],
			["skeleton", 60, 19], ["zombie", 80, 19], ["ghost", 96, 16],
			["skeleton", 118, 19], ["zombie", 132, 19], ["skeleton", 152, 19],
			["vampire", 190, 19], ["ghost", 206, 16], ["skeleton", 220, 19]],
		"chest_tile": 200,
		"exit_tile": 235,
	},
	{
		"width_tiles": 200,
		"start": Vector2i(2, 19),
		"segments": [[0, 55, 19], [59, 100, 19], [104, 150, 19], [154, 199, 19]],
		"walls": [[197, 6]],  # arena back wall so the hero can't walk off the edge
		"foods": [["apple", 15], ["bread", 45], ["apple", 70], ["apple", 110],
			["bread", 132], ["apple", 148]],
		"mobs": [["skeleton", 25, 19], ["ghost", 40, 16], ["vampire", 62, 19],
			["skeleton", 85, 19], ["ghost", 106, 16], ["vampire", 125, 19],
			["vampire_lord", 176, 19]],
		"chest_tile": 150,
	},
]

var state := STATE_TITLE
var level_node: Node2D
var hud: CanvasLayer
var title_node: Node2D
var overlay: CanvasLayer


func _ready() -> void:
	hud = CanvasLayer.new()
	hud.set_script(HudScript)
	hud.visible = false
	add_child(hud)
	_build_overlay()
	GameState.player_died.connect(_on_player_died)
	_show_title()


func _process(_delta: float) -> void:
	var pressed := Input.is_action_just_pressed("jump")
	match state:
		STATE_TITLE:
			if pressed:
				_start_game()
		STATE_PLAYING:
			if level_node != null and level_node.player.position.y > 460.0:
				GameState.force_death()  # pit fall = death, no partial resume
		STATE_GAME_OVER:
			if pressed:
				_start_game()  # SPACE -> whole game again from level 1
		STATE_VICTORY:
			if pressed:
				_show_title()


func _show_title() -> void:
	state = STATE_TITLE
	if level_node != null:
		level_node.visible = false
	hud.visible = false
	overlay.visible = false
	if title_node == null:
		title_node = Node2D.new()
		var bg := Art.make_sprite("title")
		bg.scale = Vector2(640.0 / float(bg.texture.get_width()), 360.0 / float(bg.texture.get_height()))
		bg.centered = false
		title_node.add_child(bg)
		title_node.add_child(_make_label("BOO KNIGHT", 28, Vector2(0, 60), 640.0))
		title_node.add_child(_make_label("press SPACE", 12, Vector2(0, 250), 640.0))
		add_child(title_node)
	title_node.visible = true


func _start_game() -> void:
	GameState.start_new_game()
	_load_level(1)


func _load_level(n: int) -> void:
	state = STATE_PLAYING
	GameState.level = n
	title_node.visible = false
	if level_node != null:
		level_node.queue_free()
		level_node = null
	var data: Dictionary = LEVELS[n - 1].duplicate(true)
	data["index"] = n
	level_node = Node2D.new()
	level_node.set_script(LevelScript)
	level_node.setup(data)
	level_node.level_done.connect(_on_level_done)
	level_node.boss_died.connect(_on_boss_died)
	add_child(level_node)
	hud.visible = true
	overlay.visible = false


func _on_level_done() -> void:
	if GameState.level < LEVELS.size():
		_load_level(GameState.level + 1)


func _on_boss_died() -> void:
	state = STATE_VICTORY
	level_node.visible = false
	_show_overlay("VICTORY!", "The Vampire Lord is gone. The night is cute again.\npress SPACE")


func _on_player_died() -> void:
	if state != STATE_PLAYING:
		return
	state = STATE_GAME_OVER
	level_node.visible = false
	_show_overlay("GAME OVER", "press SPACE to start again")


func _build_overlay() -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 20
	var dim := ColorRect.new()
	dim.size = Vector2(640, 360)
	dim.color = Color(0, 0, 0, 0.72)
	overlay.add_child(dim)
	overlay.add_child(_make_label("", 24, Vector2(0, 120), 640.0, "title"))
	overlay.add_child(_make_label("", 12, Vector2(0, 200), 640.0, "body"))
	overlay.visible = false
	add_child(overlay)


func _show_overlay(title_text: String, body_text: String) -> void:
	overlay.visible = true
	for child in overlay.get_children():
		if child is Label:
			if child.name == "title":
				child.text = title_text
			else:
				child.text = body_text


func _make_label(text: String, font_size: int, pos: Vector2, width: float, node_name := "") -> Label:
	var label := Label.new()
	if node_name != "":
		label.name = node_name
	label.text = text
	label.position = pos
	label.size = Vector2(width, font_size * 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	return label

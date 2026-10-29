extends Node2D
## Headless boot smoke (sim helper): runs the REAL main scene with autoloads,
## force-starts a game and steps through all 3 levels with input held, so any
## script error in player/mob/level code surfaces in this run's output.
## The ART line reports whether the real PNGs (256px sources) or placeholder
## fallbacks are loaded — run `godot --headless --path godot --import` first
## for the real-art check to read real.
## Run: godot --headless --path godot res://tests/smoke.tscn

const Art := preload("res://src/art.gd")

func _ready() -> void:
	var game_scene: Node = load("res://scenes/main.tscn").instantiate()
	add_child(game_scene)
	await get_tree().process_frame
	game_scene._start_game()
	for lvl in range(1, 4):
		if lvl > 1:
			game_scene._load_level(lvl)
		Input.action_press("move_right")
		Input.action_press("attack")
		for i in 40:
			await get_tree().physics_frame
		Input.action_release("move_right")
		Input.action_release("attack")
		# Assembly assertion: without this the smoke prints OK even when the
		# game scene failed to compile and no level exists at all (false green).
		if game_scene.level_node == null or game_scene.level_node.player == null:
			print("SMOKE FAIL: level %d did not assemble a player" % lvl)
			get_tree().quit(1)
			return
	var hero_tex := Art.texture_for("hero")
	var tile_tex := Art.texture_for("tile_ground")
	var heart_tex := Art.texture_for("heart")
	# Placeholder fallbacks paint at display size (<=48 px); real PNGs are 256+ px.
	var art_real := hero_tex.get_width() >= 256 and tile_tex.get_width() >= 256 \
		and heart_tex.get_width() >= 256
	print("ART %s hero=%dx%d tile=%dx%d heart=%dx%d" % [
		"REAL" if art_real else "PLACEHOLDER",
		hero_tex.get_width(), hero_tex.get_height(),
		tile_tex.get_width(), tile_tex.get_height(),
		heart_tex.get_width(), heart_tex.get_height()])
	print("SMOKE OK")
	get_tree().quit(0)

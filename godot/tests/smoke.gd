extends Node2D
## Headless boot smoke (sim helper): runs the REAL main scene with autoloads,
## force-starts a game and steps through all 3 levels with input held, so any
## script error in player/mob/level code surfaces in this run's output.
## The ART line reports whether the real PNGs (256px sources) or placeholder
## fallbacks are loaded — run `godot --headless --path godot --import` first
## for the real-art check to read real.
## Run: godot --headless --path godot res://tests/smoke.tscn
## T4b (MC 11715) adds ANIM (hero_walk frame list REAL when assets imported)
## and FACING (flip_h true after left input, false after right) assertions.

const Art := preload("res://src/art.gd")
const Level := preload("res://src/level.gd")
const DebugStart := preload("res://src/debug_start.gd")

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
		# Debug start-tile assertion (MC 11612): with BOOKNIGHT_START_TILE set
		# (gate runs it as 160) the clamp must land the hero deep in level 1,
		# tile > 100 — never at the default tile 2. Skipped when the override
		# is off, so the plain smoke path is unchanged.
		if lvl == 1 and DebugStart.request_tile() >= 0:
			var tile := int(game_scene.level_node.player.position.x / float(Level.TILE))
			if tile <= 100:
				print("SMOKE FAIL: start-tile override active but player tile %d <= 100" % tile)
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
	# T4b assertions (MC 11715). 1) With real art imported, hero_walk must
	# resolve to the REAL 2-frame list — red if the loader regresses to a
	# single texture while the PNGs are there. Skipped on placeholder runs,
	# where a 1-frame fallback list is the correct behaviour.
	var walk := Art.frames_for("hero_walk")
	print("ANIM hero_walk=%d frame%s" % [walk.size(), "" if walk.size() == 1 else "s"])
	if art_real and walk.size() < 2:
		print("SMOKE FAIL: hero_walk resolved to %d frame(s) while hero art is REAL" % walk.size())
		get_tree().quit(1)
		return
	# 2) Facing: after a simulated LEFT-move the hero sprite must be flip_h,
	# after a RIGHT-move not (art defaults right; flip is visual only).
	var hero: Node = game_scene.level_node.player
	var hero_sprite: Sprite2D = hero.get_node_or_null("Sprite2D")
	if hero_sprite == null:
		print("SMOKE FAIL: hero has no Sprite2D to check facing on")
		get_tree().quit(1)
		return
	Input.action_press("move_left")
	for i in 3:
		await get_tree().physics_frame
	var left_flip := hero_sprite.flip_h
	Input.action_release("move_left")
	Input.action_press("move_right")
	for i in 3:
		await get_tree().physics_frame
	var right_flip := hero_sprite.flip_h
	Input.action_release("move_right")
	print("FACING left_flip=%s right_flip=%s" % [left_flip, right_flip])
	if left_flip != true or right_flip != false:
		print("SMOKE FAIL: facing left_flip=%s (want true) right_flip=%s (want false)" % [left_flip, right_flip])
		get_tree().quit(1)
		return
	print("SMOKE OK")
	get_tree().quit(0)

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
const Rules := preload("res://src/rules.gd")
const Mob := preload("res://src/mob.gd")
const Game := preload("res://src/game.gd")
const Level := preload("res://src/level.gd")
const DebugStart := preload("res://src/debug_start.gd")
const Gauntlet := preload("res://src/gauntlet.gd")

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
	# --- T6b BOSS-KING ladder law (MC 11740, kept) ---
	# 1) Ladder shape + cycle: 4 kings, slime first, wraps after skeleton.
	if Rules.KING_LADDER.size() != 4 or String(Rules.KING_LADDER[0]) != "slime_king" \
			or Rules.next_boss_after(4) != "skeleton_king" or Rules.next_boss_after(5) != "slime_king":
		print("SMOKE FAIL: king ladder broken (%s, after4=%s after5=%s)" % [
			Rules.KING_LADDER, Rules.next_boss_after(4), Rules.next_boss_after(5)])
		get_tree().quit(1)
		return
	print("KINGS ladder=%d first=%s cycle=slime..skeleton->slime ok" % [
		Rules.KING_LADDER.size(), Rules.KING_LADDER[0]])
	# --- T7b GAUNTLET LEVELS + x1.25 MULTIPLIER + ENCHANTED SWORDS (MC 11782) ---
	# 2) Sword table: five enchanted diamond swords, storm tops the chain at 10.
	if Rules.SWORD_ORDER.size() != 9 or Rules.sword_damage("diamond_storm") != 10 \
			or Rules.better_sword("diamond", "diamond_ice") != "diamond_ice" \
			or Rules.better_sword("diamond_storm", "diamond_lava") != "diamond_storm":
		print("SMOKE FAIL: enchanted sword chain broken (order=%d storm=%d)" % [
			Rules.SWORD_ORDER.size(), Rules.sword_damage("diamond_storm")])
		get_tree().quit(1)
		return
	print("SWORDS enchanted=5 storm=10")
	# 3) Multiplier law (uncapped, owner amendment 2026-10-31): slime hp 2 at
	# depth 6 -> roundi(2*1.25^6 = 7.629) = 8, far past any old band.
	var d6_hp := Rules.mob_hp("slime", 6)
	if d6_hp != 8 or Rules.mob_hp("skeleton", 6) != 23 or Rules.mob_hp("slime", 0) != 2:
		print("SMOKE FAIL: multiplier law broken (slime d6=%d want 8, skeleton d6=%d want 23)" % [
			d6_hp, Rules.mob_hp("skeleton", 6)])
		get_tree().quit(1)
		return
	print("MULT depth6 hp(slime)= %d uncapped ok" % d6_hp)
	# 4) Generator determinism (same depth twice, byte-identical) + fixed rotation.
	var g3 := Gauntlet.generate(3)
	if str(g3) != str(Gauntlet.generate(3)) or Array(g3["mobs"]).size() != 10:
		print("SMOKE FAIL: gauntlet generator not deterministic (mobs=%d)" % Array(g3["mobs"]).size())
		get_tree().quit(1)
		return
	print("GAUNTLET gen depth=3 mobs=%d det=ok" % Array(g3["mobs"]).size())
	# 5) Every king has its 2-frame move cycle (real art runs only, like hero_walk).
	for king in Rules.KING_LADDER:
		var kf := Art.frames_for(String(Mob.MOVE_ANIM[king]))
		print("KING_ANIM %s=%d frames" % [king, kf.size()])
		if art_real and kf.size() < 2:
			print("SMOKE FAIL: %s resolved to %d frame(s) while art is REAL" % [king, kf.size()])
			get_tree().quit(1)
			return
	# 6) Enchanted swords animate while held (T7b law 4): each _a/_b pair resolves.
	for el in ["ice", "flame", "lava", "wind", "storm"]:
		var sf := Art.frames_for("sword_diamond_" + el)
		print("SWORD_ANIM %s=%d frames" % [el, sf.size()])
		if art_real and sf.size() < 2:
			print("SMOKE FAIL: sword_diamond_%s resolved to %d frame(s) while art is REAL" % [el, sf.size()])
			get_tree().quit(1)
			return
	# 7) Runtime law: killing the lord CONTINUES the game — gauntlet DEPTH 1
	# opens first (T7b: upgraded level BEFORE the next king), and clearing its
	# exit door delivers slime_king in the arena (no victory state).
	var lord: Node = null
	for c in game_scene.level_node.get_children():
		if c.get("mob_type") == "vampire_lord":
			lord = c
	if lord == null:
		print("SMOKE FAIL: arena level assembled no vampire_lord to kill")
		get_tree().quit(1)
		return
	lord.take_damage(999, lord.global_position.x)
	for i in 3:
		await get_tree().process_frame
	if not game_scene.on_gauntlet or int(game_scene.level_node.data.get("depth", 0)) != 1 \
			or GameState.gauntlet_depth() != 1 or game_scene.state != Game.STATE_PLAYING:
		print("SMOKE FAIL: boss-kill did not open gauntlet depth 1 (on_gauntlet=%s depth=%d state=%d)" % [
			game_scene.on_gauntlet, GameState.gauntlet_depth(), game_scene.state])
		get_tree().quit(1)
		return
	game_scene.level_node.level_done.emit()  # simulated clear: hero reached the exit door
	for i in 3:
		await get_tree().process_frame
	var king_present := false
	for c in game_scene.level_node.get_children():
		if c.get("mob_type") == "slime_king":
			king_present = true
	if game_scene.on_gauntlet or not king_present or game_scene.state != Game.STATE_PLAYING \
			or game_scene.level_node.data.has("depth"):
		print("SMOKE FAIL: gauntlet clear broken (on_gauntlet=%s slime_king=%s state=%d depth-keyed=%s)" % [
			game_scene.on_gauntlet, king_present, game_scene.state, game_scene.level_node.data.has("depth")])
		get_tree().quit(1)
		return
	print("GAUNTLET lord-kill -> depth=1 gauntlet opened -> cleared -> slime_king playing ok")
	print("SMOKE OK")
	get_tree().quit(0)

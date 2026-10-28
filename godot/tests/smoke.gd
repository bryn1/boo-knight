extends Node2D
## Headless boot smoke (sim helper): runs the REAL main scene with autoloads,
## force-starts a game and steps through all 3 levels with input held, so any
## script error in player/mob/level code surfaces in this run's output.
## Run: godot --headless --path godot res://tests/smoke.tscn

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
	print("SMOKE OK")
	get_tree().quit(0)

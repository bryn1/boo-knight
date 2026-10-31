extends Node
## Autoload "GameState": the live run state (level, sword, hearts).
## All rule math is delegated to res://src/rules.gd — this node only stores
## current values and emits change signals for HUD / game flow.

const Rules := preload("res://src/rules.gd")

signal hearts_changed(hp: int)
signal sword_changed(sword_id: String)
signal player_died
signal boss_changed(boss_id: String, depth: int)

var hearts: int = Rules.MAX_HP
var sword: String = "wood"
var level: int = 1
## T7b gauntlet (MC 11782): boss kills so far; the gauntlet depth/multiplier and
## the next arena boss are pure functions of this one counter (rules.gd law).
var boss_kills: int = 0


## Gauntlet depth: 0 = the unscaled handcrafted world; 1.. = one gauntlet level
## earned per boss kill (mult = 1.25^depth, rules.gd law).
func gauntlet_depth() -> int:
	return Rules.depth_for_boss_kills(boss_kills)


## Which boss the arena holds right now (lord first, then the king ladder).
func current_boss() -> String:
	return Rules.next_boss_after(boss_kills)


func on_boss_kill() -> void:
	boss_kills += 1


## Which boss is on screen right now ("" = none); drives the HUD boss label
## and the "Harder x<mult>" depth marker.
func set_boss_on_screen(boss_id: String) -> void:
	boss_changed.emit(boss_id, gauntlet_depth())


## Full reset from initial_state()/on_death() — used at title start and after GAME OVER.
func start_new_game() -> void:
	var s := Rules.on_death({"level": level, "sword": sword, "hearts": hearts})
	level = int(s["level"])
	sword = String(s["sword"])
	hearts = int(s["hearts"])
	boss_kills = int(s["boss_kills"])  # depth + multiplier reset to 0 on death (T7b law)
	hearts_changed.emit(hearts)
	sword_changed.emit(sword)
	set_boss_on_screen("")


func damage_player(amount: int) -> void:
	if hearts <= 0:
		return
	hearts = maxi(0, hearts - amount)
	hearts_changed.emit(hearts)
	if hearts == 0:
		player_died.emit()


## A pit fall kills without any remaining hearts.
func force_death() -> void:
	if hearts <= 0:
		return
	hearts = 0
	hearts_changed.emit(0)
	player_died.emit()


func eat(food: String) -> void:
	hearts = Rules.heal(hearts, food)
	hearts_changed.emit(hearts)


## Player touched a chest in handcrafted `chest_level`; returns true when the sword upgraded.
func touch_chest(chest_level: int) -> bool:
	var next := Rules.better_sword(sword, Rules.chest_sword_for_level(chest_level))
	if next == sword:
		return false
	sword = next
	sword_changed.emit(sword)
	return true


## Player touched a chest in a gauntlet level of `depth` (T7b law 3): depths
## 1..5 hold one enchanted diamond sword each (still gated by better_sword —
## never a downgrade), deeper chests hold bread. True = something was taken.
func touch_gauntlet_chest(depth: int) -> bool:
	var loot := Rules.gauntlet_chest(depth)
	if loot == "bread":
		if hearts >= Rules.MAX_HP:
			return false
		eat("bread")
		return true
	var next := Rules.better_sword(sword, loot)
	if next == sword:
		return false
	sword = next
	sword_changed.emit(sword)
	return true

extends SceneTree
## Headless simulation test for Boo Knight (T1 gate).
## Run: Godot_v4.7.2 --headless --path godot -s res://tests/sim.gd
## Asserts the REAL rules module (res://src/rules.gd), never a copy, and prints
## one line per check plus a final SIM PASS / SIM FAIL. --plant-bad deliberately
## inverts the mob-HP assertion so the gate proves it can go RED (exit 1).

const Rules := preload("res://src/rules.gd")

## Expected hits per sword x mob, hardcoded from the owner's rule table:
## dmg wood 1 / stone 2 / iron 3 / diamond 5 vs HP 2/3/4/6/8/10.
const EXPECTED_HITS := {
	"wood": {"slime": 2, "ghost": 3, "zombie": 4, "skeleton": 6, "vampire": 8, "vampire_lord": 10},
	"stone": {"slime": 1, "ghost": 2, "zombie": 2, "skeleton": 3, "vampire": 4, "vampire_lord": 5},
	"iron": {"slime": 1, "ghost": 1, "zombie": 2, "skeleton": 2, "vampire": 3, "vampire_lord": 4},
	"diamond": {"slime": 1, "ghost": 1, "zombie": 1, "skeleton": 2, "vampire": 2, "vampire_lord": 2},
}

const EXPECTED_SWORD_DMG := {"wood": 1, "stone": 2, "iron": 3, "diamond": 5}
const EXPECTED_TOUCH_DMG := {"slime": 2, "ghost": 2, "zombie": 3, "skeleton": 3, "vampire": 4, "vampire_lord": 6}

var _fails := 0


func _initialize() -> void:
	# In -s script mode the bare `OS` name parses as the class, not the singleton.
	var os = Engine.get_singleton("OS")
	var argv: Array = os.get_cmdline_args() + os.get_cmdline_user_args()
	var plant_bad: bool = argv.has("--plant-bad")
	print("Boo Knight sim — testing res://src/rules.gd%s" % (" [PLANTED-BAD]" if plant_bad else ""))
	_check_hit_matrix()
	_check_mob_hp(plant_bad)
	_check_food()
	_check_death_resets()
	_check_chests()
	if _fails == 0:
		print("SIM PASS")
		quit(0)
	else:
		print("SIM FAIL")
		quit(1)


func _check(name: String, ok: bool) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", name])
	if not ok:
		_fails += 1


func _check_hit_matrix() -> void:
	for sword in Rules.SWORD_ORDER:
		var ok := true
		for mob_type in Rules.MOB_HP:
			ok = ok and Rules.hits_to_kill(sword, mob_type) == int(EXPECTED_HITS[sword][mob_type])
		_check("1: %s sword kill-count matrix vs all mobs" % sword, ok)
	_check("1: spot — wood vs slime = 2 hits", Rules.hits_to_kill("wood", "slime") == 2)
	_check("1: spot — diamond vs vampire_lord = 2 hits", Rules.hits_to_kill("diamond", "vampire_lord") == 2)
	var dmg_ok := true
	for s in EXPECTED_SWORD_DMG:
		dmg_ok = dmg_ok and Rules.sword_damage(s) == EXPECTED_SWORD_DMG[s]
	_check("1: sword damage table (1/2/3/5)", dmg_ok)


func _check_mob_hp(plant_bad: bool) -> void:
	# --plant-bad inverts this fixed assertion (expects a bogus slime HP=3) so the
	# gate proves it can go RED instead of being green-by-construction.
	var expected := {"slime": 2, "ghost": 3, "zombie": 4, "skeleton": 6, "vampire": 8, "vampire_lord": 10}
	if plant_bad:
		expected["slime"] = 3
	var ok := true
	for mob_type in expected:
		ok = ok and Rules.mob_hp(mob_type) == int(expected[mob_type])
	_check("2: mob HP matches table (slime 2 ghost 3 zombie 4 skeleton 6 vampire 8 lord 10)", ok)
	var in_range := true
	for mob_type in Rules.MOB_HP:
		var hp := Rules.mob_hp(mob_type)
		in_range = in_range and hp >= 2 and hp <= 10
	_check("2: every mob HP is within 2..10", in_range)
	var touch_ok := true
	for mob_type in EXPECTED_TOUCH_DMG:
		touch_ok = touch_ok and Rules.mob_touch_damage(mob_type) == EXPECTED_TOUCH_DMG[mob_type]
	_check("2: contact damage table (2/2/3/3/4/6)", touch_ok)


func _check_food() -> void:
	_check("3: apple heals +5 (20 -> 25)", Rules.heal(20, "apple") == 25)
	_check("3: bread heals +10 (15 -> 25)", Rules.heal(15, "bread") == 25)
	_check("3: heal caps at 30 (28 + bread -> 30)", Rules.heal(28, "bread") == 30)
	_check("3: heal caps at 30 (30 + apple -> 30)", Rules.heal(30, "apple") == 30)


func _check_death_resets() -> void:
	var after := Rules.on_death({"level": 3, "sword": "diamond", "hearts": 0})
	_check("4: death resets level -> 1", int(after["level"]) == 1)
	_check("4: death resets sword -> wood", String(after["sword"]) == "wood")
	_check("4: death resets hearts -> 30", int(after["hearts"]) == 30)


func _check_chests() -> void:
	_check("5: chest level 1 contains stone", Rules.chest_sword_for_level(1) == "stone")
	_check("5: chest level 2 contains iron", Rules.chest_sword_for_level(2) == "iron")
	_check("5: chest level 3 contains diamond", Rules.chest_sword_for_level(3) == "diamond")
	_check("5: wood + stone chest -> stone", Rules.better_sword("wood", "stone") == "stone")
	_check("5: equal sword (stone on stone chest) ignored", Rules.better_sword("stone", "stone") == "stone")
	_check("5: worse sword (iron player, stone chest) ignored", Rules.better_sword("iron", "stone") == "iron")
	_check("5: diamond player never downgrades", Rules.better_sword("diamond", "iron") == "diamond")

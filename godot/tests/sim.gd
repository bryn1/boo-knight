extends SceneTree
## Headless simulation test for Boo Knight (T1 gate; T7b gauntlet-level law MC 11782).
## Run: Godot_v4.7.2 --headless --path godot -s res://tests/sim.gd
## Asserts the REAL rules module (res://src/rules.gd), never a copy, and prints
## one line per check plus a final SIM PASS / SIM FAIL. --plant-bad deliberately
## inverts the mob-HP assertion so the gate proves it can go RED (exit 1).

const Rules := preload("res://src/rules.gd")
const Gauntlet := preload("res://src/gauntlet.gd")

## Expected hits per sword x mob at depth 0, from the owner's rule table:
## dmg wood 1 / stone 2 / iron 3 / diamond 5 / ice 6 / flame 7 / lava 8 /
## wind 9 / storm 10 vs HP slime 2 ghost 3 zombie 4 skeleton 6 vampire 8,
## lord 6 (T6b amendment), kings 8/8/9/10.
const EXPECTED_HITS := {
	"wood": {"slime": 2, "ghost": 3, "zombie": 4, "skeleton": 6, "vampire": 8, "vampire_lord": 6,
		"slime_king": 8, "ghost_king": 8, "zombie_king": 9, "skeleton_king": 10},
	"stone": {"slime": 1, "ghost": 2, "zombie": 2, "skeleton": 3, "vampire": 4, "vampire_lord": 3,
		"slime_king": 4, "ghost_king": 4, "zombie_king": 5, "skeleton_king": 5},
	"iron": {"slime": 1, "ghost": 1, "zombie": 2, "skeleton": 2, "vampire": 3, "vampire_lord": 2,
		"slime_king": 3, "ghost_king": 3, "zombie_king": 3, "skeleton_king": 4},
	"diamond": {"slime": 1, "ghost": 1, "zombie": 1, "skeleton": 2, "vampire": 2, "vampire_lord": 2,
		"slime_king": 2, "ghost_king": 2, "zombie_king": 2, "skeleton_king": 2},
	"diamond_ice": {"slime": 1, "ghost": 1, "zombie": 1, "skeleton": 1, "vampire": 2, "vampire_lord": 1,
		"slime_king": 2, "ghost_king": 2, "zombie_king": 2, "skeleton_king": 2},
	"diamond_flame": {"slime": 1, "ghost": 1, "zombie": 1, "skeleton": 1, "vampire": 2, "vampire_lord": 1,
		"slime_king": 2, "ghost_king": 2, "zombie_king": 2, "skeleton_king": 2},
	"diamond_lava": {"slime": 1, "ghost": 1, "zombie": 1, "skeleton": 1, "vampire": 1, "vampire_lord": 1,
		"slime_king": 1, "ghost_king": 1, "zombie_king": 2, "skeleton_king": 2},
	"diamond_wind": {"slime": 1, "ghost": 1, "zombie": 1, "skeleton": 1, "vampire": 1, "vampire_lord": 1,
		"slime_king": 1, "ghost_king": 1, "zombie_king": 1, "skeleton_king": 2},
	"diamond_storm": {"slime": 1, "ghost": 1, "zombie": 1, "skeleton": 1, "vampire": 1, "vampire_lord": 1,
		"slime_king": 1, "ghost_king": 1, "zombie_king": 1, "skeleton_king": 1},
}

const EXPECTED_SWORD_DMG := {"wood": 1, "stone": 2, "iron": 3, "diamond": 5,
	"diamond_ice": 6, "diamond_flame": 7, "diamond_lava": 8, "diamond_wind": 9, "diamond_storm": 10}
const EXPECTED_TOUCH_DMG := {"slime": 2, "ghost": 2, "zombie": 3, "skeleton": 3, "vampire": 4,
	"vampire_lord": 3, "slime_king": 3, "ghost_king": 3, "zombie_king": 4, "skeleton_king": 4}
const ENCHANTED := ["diamond_ice", "diamond_flame", "diamond_lava", "diamond_wind", "diamond_storm"]

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
	_check_gauntlet_law()
	_check_multiplier_law()
	_check_generator()
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
		_check("1: %s sword kill-count matrix vs all mobs+kings" % sword, ok)
	_check("1: spot — wood vs slime = 2 hits", Rules.hits_to_kill("wood", "slime") == 2)
	_check("1: spot — diamond vs vampire_lord = 2 hits", Rules.hits_to_kill("diamond", "vampire_lord") == 2)
	_check("1: spot — wood vs skeleton_king = 10 hits", Rules.hits_to_kill("wood", "skeleton_king") == 10)
	var dmg_ok := true
	for s in EXPECTED_SWORD_DMG:
		dmg_ok = dmg_ok and Rules.sword_damage(s) == EXPECTED_SWORD_DMG[s]
	_check("1: sword damage table (1/2/3/5 enchanted 6/7/8/9/10)", dmg_ok)
	_check("1: enchanted labels", Rules.sword_label("diamond_ice") == "Ice Diamond +1" \
		and Rules.sword_label("diamond_storm") == "Storm Diamond +5")


func _check_mob_hp(plant_bad: bool) -> void:
	# --plant-bad inverts this fixed assertion (expects a bogus slime HP=3) so the
	# gate proves it can go RED instead of being green-by-construction.
	var expected := {"slime": 2, "ghost": 3, "zombie": 4, "skeleton": 6, "vampire": 8,
		"vampire_lord": 6, "slime_king": 8, "ghost_king": 8, "zombie_king": 9, "skeleton_king": 10}
	if plant_bad:
		expected["slime"] = 3
	var ok := true
	for mob_type in expected:
		ok = ok and Rules.mob_hp(mob_type) == int(expected[mob_type])
	_check("2: base mob HP matches table (2/3/4/6/8, lord 6, kings 8/8/9/10)", ok)
	var in_band := true
	for mob_type in Rules.MOB_HP:
		var hp := Rules.mob_hp(mob_type)  # depth 0 = handcrafted world
		in_band = in_band and hp >= 2 and hp <= 10
	_check("2: handcrafted (depth-0) mob HP stays in the owner band 2..10", in_band)
	var touch_ok := true
	for mob_type in EXPECTED_TOUCH_DMG:
		touch_ok = touch_ok and Rules.mob_touch_damage(mob_type) == EXPECTED_TOUCH_DMG[mob_type]
	_check("2: contact damage table (2/2/3/3/4, lord 3, kings 3/3/4/4)", touch_ok)


func _check_food() -> void:
	_check("3: apple heals +5 (20 -> 25)", Rules.heal(20, "apple") == 25)
	_check("3: bread heals +10 (15 -> 25)", Rules.heal(15, "bread") == 25)
	_check("3: heal caps at 30 (28 + bread -> 30)", Rules.heal(28, "bread") == 30)
	_check("3: heal caps at 30 (30 + apple -> 30)", Rules.heal(30, "apple") == 30)


func _check_death_resets() -> void:
	var after := Rules.on_death({"level": 3, "sword": "diamond", "hearts": 0, "boss_kills": 2})
	_check("4: death resets level -> 1", int(after["level"]) == 1)
	_check("4: death resets sword -> wood", String(after["sword"]) == "wood")
	_check("4: death resets hearts -> 30", int(after["hearts"]) == 30)
	_check("4: death resets boss_kills -> 0 (depth back to 0)", int(after["boss_kills"]) == 0)


func _check_chests() -> void:
	_check("5: chest level 1 contains stone", Rules.chest_sword_for_level(1) == "stone")
	_check("5: chest level 2 contains iron", Rules.chest_sword_for_level(2) == "iron")
	_check("5: chest level 3 contains diamond", Rules.chest_sword_for_level(3) == "diamond")
	_check("5: wood + stone chest -> stone", Rules.better_sword("wood", "stone") == "stone")
	_check("5: equal sword (stone on stone chest) ignored", Rules.better_sword("stone", "stone") == "stone")
	_check("5: worse sword (iron player, stone chest) ignored", Rules.better_sword("iron", "stone") == "iron")
	_check("5: diamond player never downgrades", Rules.better_sword("diamond", "iron") == "diamond")
	# T7b enchanted chain (law 3): the better_sword chain extends over the new order.
	_check("5: diamond + ice chest -> ice (chain extends)", Rules.better_sword("diamond", "diamond_ice") == "diamond_ice")
	_check("5: storm never downgrades (ice candidate ignored)", Rules.better_sword("diamond_storm", "diamond_ice") == "diamond_storm")
	_check("5: storm beats every earlier sword",
		Rules.better_sword("diamond_wind", "diamond_storm") == "diamond_storm")
	# T7b law 3: one enchanted sword per gauntlet depth 1..5, bread beyond.
	var want := ["diamond_ice", "diamond_flame", "diamond_lava", "diamond_wind", "diamond_storm"]
	var chest_ok := true
	for d in range(1, 6):
		chest_ok = chest_ok and Rules.gauntlet_chest(d) == want[d - 1]
	_check("5: gauntlet chests depth 1..5 hold ice/flame/lava/wind/storm", chest_ok)
	_check("5: gauntlet depth 6+ chest holds bread (all five earned)",
		Rules.gauntlet_chest(6) == "bread" and Rules.gauntlet_chest(40) == "bread")


## T6b boss-king law (MC 11740, unchanged by T7b): ladder order + cycle and
## fixed boss stats — the cycle is the escalation.
func _check_gauntlet_law() -> void:
	_check("6: ladder is slime->ghost->zombie->skeleton",
		Rules.KING_LADDER == ["slime_king", "ghost_king", "zombie_king", "skeleton_king"])
	_check("6: first boss is the lord; after kill 1 slime_king arrives",
		Rules.next_boss_after(0) == "vampire_lord" and Rules.next_boss_after(1) == "slime_king")
	var cycle_ok := true
	for k in range(1, 9):  # two full cycles: slime ghost zombie skeleton slime ghost zombie skeleton
		var want := String(Rules.KING_LADDER[(k - 1) % 4])
		cycle_ok = cycle_ok and Rules.next_boss_after(k) == want
	_check("6: king cycle repeats (kills 1..8)", cycle_ok)
	_check("6: is_boss covers lord + all four kings",
		Rules.is_boss("vampire_lord") and Rules.is_boss("skeleton_king") \
		and not Rules.is_boss("vampire") and not Rules.is_boss("slime"))
	_check("6: HUD boss names", Rules.boss_display_name("slime_king") == "Slime King" \
		and Rules.boss_display_name("vampire_lord") == "Vampire Lord" \
		and Rules.boss_display_name("") == "")


## T7b multiplier law (MC 11782, owner ask + amendment 2026-10-31 quoted in
## rules.gd): depth = boss kills, mult = 1.25^depth, BOTH hp and contact scale
## roundi(base * mult) WITHOUT CAP, bosses never scale, handcrafted depth-0
## levels never scale, HUD marker one-decimal, death resets depth.
func _check_multiplier_law() -> void:
	_check("7: depth = boss kills, starting at 1 with the first kill",
		Rules.depth_for_boss_kills(0) == 0 and Rules.depth_for_boss_kills(1) == 1 \
		and Rules.depth_for_boss_kills(5) == 5)
	_check("7: mult = 1.25^depth (d0 1, d2 1.5625, d4 2.44140625, d6 3.814697265625)",
		is_equal_approx(Rules.mult(0), 1.0) and is_equal_approx(Rules.mult(2), 1.5625) \
		and is_equal_approx(Rules.mult(4), 2.44140625) \
		and is_equal_approx(Rules.mult(6), 3.814697265625))
	# roundi(x) = int(x + 0.5) exact (banker's rounding would give 2.5 -> 2).
	_check("7: roundi exact — slime 2 at d1 -> 3 (2*1.25=2.5 -> 3)", Rules.mob_hp("slime", 1) == 3)
	_check("7: roundi exact — gauntlet_stat(5, 6) = 19 (5*1.25^6 = 19.07 -> 19)",
		Rules.gauntlet_stat(5, 6) == 19)
	var table := {  # [mob, depth, want_hp, want_contact] — hand-computed from the law
		"slime_d1": ["slime", 1, 3, 3], "slime_d2": ["slime", 2, 3, 3],
		"ghost_d1": ["ghost", 1, 4, 3], "zombie_d1": ["zombie", 1, 5, 4],
		"skeleton_d1": ["skeleton", 1, 8, 4], "slime_d6": ["slime", 6, 8, 8],
		"vampire_d6": ["vampire", 6, 31, 15],
	}
	var rounding_ok := true
	for row in table:
		var e: Array = table[row]
		rounding_ok = rounding_ok and Rules.mob_hp(String(e[0]), int(e[1])) == int(e[2]) \
			and Rules.mob_touch_damage(String(e[0]), int(e[1])) == int(e[3])
	_check("7: hp+contact rounding table (slime/ghost/zombie/skeleton/vampire d1-d6)", rounding_ok)
	# NO-CAP law (owner amendment 2026-10-31): stats grow past every old band.
	_check("7: NO CAP — skeleton hp 5 at d6 -> 23 (6*3.8146 = 22.89 -> 23)",
		Rules.mob_hp("skeleton", 6) == 23)
	_check("7: NO CAP — contact grows unbounded too (vampire 4 at d10: 4*9.3132 = 37.25 -> 37)",
		Rules.mob_touch_damage("vampire", 10) == 37)
	_check("7: NO CAP — gauntlet_stat(8, 12) way past the old 2-10 band (8*14.553 = 116.4 -> 116)",
		Rules.gauntlet_stat(8, 12) == 116)
	_check("7: HUD marker 'Harder x<mult>' one decimal (d1 x1.3, d2 x1.6, d4 x2.4)",
		Rules.mult_display(1) == "Harder x1.3" and Rules.mult_display(2) == "Harder x1.6" \
		and Rules.mult_display(4) == "Harder x2.4")
	var kings_fixed := true
	for king in Rules.KING_LADDER:
		for d in [1, 3, 6]:
			kings_fixed = kings_fixed and Rules.mob_hp(king, d) == Rules.mob_hp(king) \
				and Rules.mob_touch_damage(king, d) == Rules.mob_touch_damage(king)
	_check("7: king stats do NOT scale at any depth (cycle IS the escalation)", kings_fixed)
	_check("7: lord stats do NOT scale (hp 6 / touch 3 at every depth)",
		Rules.mob_hp("vampire_lord", 6) == 6 and Rules.mob_touch_damage("vampire_lord", 6) == 3)
	var base_only := true
	for mob_type in Rules.MOB_HP:
		base_only = base_only and Rules.mob_hp(mob_type, 0) == Rules.mob_hp(mob_type) \
			and Rules.mob_touch_damage(mob_type, 0) == Rules.mob_touch_damage(mob_type)
	_check("7: multiplier applies ONLY inside gauntlet levels — depth-0 stats are base for every mob", base_only)
	_check("7: gauntlet levels are the ones that carry the depth key",
		int(Gauntlet.generate(2)["depth"]) == 2)
	_check("7: depth 0 = base stats (roundi law reduces to identity)",
		Rules.gauntlet_stat(2, 0) == 2 and Rules.mob_hp("vampire", 0) == 8)
	var after := Rules.on_death({"level": 3, "sword": "diamond_storm", "hearts": 0, "boss_kills": 4})
	_check("8: depth reset on death -> depth 0 and lord is the next boss again",
		Rules.depth_for_boss_kills(int(after["boss_kills"])) == 0 \
		and Rules.next_boss_after(int(after["boss_kills"])) == "vampire_lord")


## T7b law 7: deterministic seeded generator — same depth => byte-identical
## layout, safe spawn margin, pits never overlap and never exceed a hop.
func _check_generator() -> void:
	var a := Gauntlet.generate(3)
	var b := Gauntlet.generate(3)
	_check("9: same seed (depth 3) twice -> byte-identical layout", str(a) == str(b))
	_check("9: different depth -> different layout", str(a) != str(Gauntlet.generate(4)))
	_check("9: level shape matches the LEVELS data contract",
		a.has("width_tiles") and a.has("start") and a.has("segments") \
		and a.has("foods") and a.has("mobs") and a.has("chest_tile") and a.has("exit_tile") \
		and a.has("depth") and int(a["depth"]) == 3)
	var segs: Array = a["segments"]
	_check("9: ground in 3-4 segments", segs.size() >= 3 and segs.size() <= 4)
	var pits_ok := segs.size() >= 2
	for i in range(1, segs.size()):
		var gap := int(segs[i][0]) - int(segs[i - 1][1]) - 1
		pits_ok = pits_ok and gap >= 1 and gap <= 3  # never overlapping, width <= 3 (hop clears)
	_check("9: 2-3 pits, never overlapping, every width <= 3", pits_ok)
	var mobs: Array = a["mobs"]
	_check("9: 10 mobs in fixed rotation slime/ghost/zombie/skeleton/vampire x2", mobs.size() == 10)
	var rot_ok := true
	for i in mobs.size():
		rot_ok = rot_ok and String(mobs[i][0]) == String(Gauntlet.MOB_ROTATION[i % Gauntlet.MOB_ROTATION.size()])
		var y := int(mobs[i][2])
		rot_ok = rot_ok and (y == 16 if String(mobs[i][0]) == "ghost" else y == 19)
	_check("9: kind-appropriate y (ghosts float at 16, ground mobs on 19)", rot_ok)
	var margin_ok := true
	for m in mobs:
		margin_ok = margin_ok and int(m[1]) - int(Gauntlet.START_TILE) >= Gauntlet.SPAWN_MARGIN
	_check("9: no mob within 12 tiles of the spawn", margin_ok)
	_check("9: ~140 tiles wide, exit near the end",
		int(a["width_tiles"]) >= 130 and int(a["width_tiles"]) <= 150 \
		and int(a["exit_tile"]) >= int(a["width_tiles"]) - 10)
	var foods: Array = a["foods"]
	var breads := 0
	var apples := 0
	for f in foods:
		if String(f[0]) == "bread":
			breads += 1
		elif String(f[0]) == "apple":
			apples += 1
	_check("9: foods = 2 bread + 2 apples, deterministic tiles",
		breads == 2 and apples == 2 and str(foods) == str(Gauntlet.generate(3)["foods"]))

extends RefCounted
## Pure combat/rule constants and functions for Boo Knight.
## No scene or node dependencies: both the game and tests/sim.gd use THIS module,
## so a sim failure means the real game rules are wrong. Never add Node usage here.

const MAX_HP := 30
const HP_PER_HEART := 2
const HEARTS_SHOWN := 15  # 15 hearts x 2 HP = 30 HP

## Sword table: dmg + HUD label. Touching a chest with a strictly-better sword upgrades.
## T7b (MC 11782, owner ask 2026-10-31): five enchanted diamond swords (+1..+5),
## one per gauntlet depth, animated while held (art.gd ANIMS; HUD icon = base frame).
const SWORDS := {
	"wood": {"dmg": 1, "label": "Wooden Sword", "icon": "sword_wood"},
	"stone": {"dmg": 2, "label": "Stone Sword", "icon": "sword_stone"},
	"iron": {"dmg": 3, "label": "Iron Sword", "icon": "sword_iron"},
	"diamond": {"dmg": 5, "label": "Diamond Sword", "icon": "sword_diamond"},
	"diamond_ice": {"dmg": 6, "label": "Ice Diamond +1", "icon": "sword_diamond_ice"},
	"diamond_flame": {"dmg": 7, "label": "Flame Diamond +2", "icon": "sword_diamond_flame"},
	"diamond_lava": {"dmg": 8, "label": "Lava Diamond +3", "icon": "sword_diamond_lava"},
	"diamond_wind": {"dmg": 9, "label": "Wind Diamond +4", "icon": "sword_diamond_wind"},
	"diamond_storm": {"dmg": 10, "label": "Storm Diamond +5", "icon": "sword_diamond_storm"},
}
## Weakest -> strongest. "Better" means strictly later in this list.
const SWORD_ORDER := ["wood", "stone", "iron", "diamond",
	"diamond_ice", "diamond_flame", "diamond_lava", "diamond_wind", "diamond_storm"]

const MOB_HP := {
	"slime": 2, "ghost": 3, "zombie": 4,
	"skeleton": 6, "vampire": 8,
	"vampire_lord": 6,  # T6b amendment (MC 11740): gentler lord, 10 -> 6
	"slime_king": 8, "ghost_king": 8, "zombie_king": 9, "skeleton_king": 10,
}
const MOB_TOUCH_DAMAGE := {
	"slime": 2, "ghost": 2, "zombie": 3,
	"skeleton": 3, "vampire": 4,
	"vampire_lord": 3,  # T6b amendment (MC 11740): 6 -> 3
	"slime_king": 3, "ghost_king": 3, "zombie_king": 4, "skeleton_king": 4,
}

## Boss-king gauntlet (T6b, MC 11740 — owner amendment 2026-10-30: "Each bosskill
## uncreasws difficulty. Monster kung, ghost king, zombie kikng, skeletonking").
## After the lord falls, this ladder guards the arena, ever cycling: king stats
## themselves never scale (the gauntlet depths + multiplier between them, T7b
## law below, and the ladder cycle are the escalation).
const KING_LADDER := ["slime_king", "ghost_king", "zombie_king", "skeleton_king"]
const BOSS_NAMES := {
	"vampire_lord": "Vampire Lord", "slime_king": "Slime King",
	"ghost_king": "Ghost King", "zombie_king": "Zombie King",
	"skeleton_king": "Skeleton King",
}
## Gauntlet multiplier law (T7b, MC 11782 — owner ask 2026-10-31: "When ine boss
## has died, a new level with upgraded monsters come before the next boss.
## Multiplyer of 1.25 per level"). mult(depth) = 1.25^depth, and inside a
## gauntlet level BOTH normal-mob stats scale by it, uncapped:
## hp = roundi(base_hp * mult), contact = roundi(base_contact * mult).
## OWNER AMENDMENT 2026-10-31 verbatim: "Thr multiplier include hp and damage
## for hp and damage without cap of 10" — the old 2-10 hp band and every
## closer-set cap are VOID inside gauntlet levels; deep levels get genuinely
## beefy monsters, that is the point. The 2-10 band still describes the
## handcrafted depth-0 levels, which never scale. roundi(x) = int(x + 0.5).
## Kings' own stats NEVER scale (the ladder cycle is the escalation — unchanged
## from the v1.1 law). Depth resets to 0 on player death with the rest of the run.
const MULT_BASE := 1.25

const FOOD_HEAL := {"apple": 5, "bread": 10}

## Chest in handcrafted level N contains this sword (levels are 1-based).
const CHEST_SWORD := {1: "stone", 2: "iron", 3: "diamond"}
## Gauntlet-depth chest loot (T7b law 3): one enchanted diamond sword per depth
## 1..5; depth > 5 chests hold bread instead (all five already earned).
const GAUNTLET_CHEST := {1: "diamond_ice", 2: "diamond_flame", 3: "diamond_lava",
	4: "diamond_wind", 5: "diamond_storm"}

const ATTACK_COOLDOWN := 0.35  # seconds between sword swings
## Sword-reach law (T8b, MC 11810 — owner 2026-10-31 "attack ramge could be
## increased slightly"): during the attack window the attack Area2D sits
## ATTACK_REACH_X px ahead of the hero centre with ATTACK_REACH_HALF px
## half-extent along x (new 22/10, band 12..32). At rest the area is
## un-monitored, so nothing is ever hit outside the attack window. The runtime
## wires these same constants (level.gd rect, player.gd area position);
## tests/sim.gd asserts the business law through sword_hits().
const ATTACK_REACH_X := 22.0
const ATTACK_REACH_HALF := 10.0
## Forward-sweep law (T8b, MC 11810 — owner 2026-10-31 "a sword pointing
## STRAIGHT FORWARD in a sweeping motion"): across the attack window the held
## sword overlay rotation goes rest 0 -> SWEEP_RAISED (wind-up back) by 25%,
## sweeps to SWEEP_FWD by 55%, holds to 85%, returns to rest by window end.
## CLOSER GEOMETRY RULING 2026-10-31: the sword PNG's natural blade angle is
## 45.2 deg UP, so straight-forward (horizontal) is 0.79 rad (45.2 deg + 44);
## the brief's 0.15 left the blade ~36 deg UP — composites /tmp/sweep-hold
## _0p15.png vs _0p79.png prove the level thrust. player.gd mirrors the sign
## when facing left; tests/sim.gd pins the law through sweep_angle().
const SWEEP_RAISED := -1.0
const SWEEP_FWD := 0.79
const INVULN_TIME := 0.8  # seconds of player invulnerability after a hit
## Kid-friendly grace: seconds of contact-damage immunity at the start of every
## run AND every level (the player node is freshly spawned for each).
const SPAWN_GRACE := 3.0


static func sword_damage(sword: String) -> int:
	return int(SWORDS[sword]["dmg"])


## Reach law as a pure band test (tests/sim.gd business assertions): a target
## centre at `dist` px directly ahead is struck iff the attack is up and the
## distance lies inside the Area2D band [x-half, x+half]. At rest nothing is
## hit at ANY distance (the area is un-monitored outside the attack window).
static func sword_hits(dist: float, attacking: bool) -> bool:
	return attacking and dist >= ATTACK_REACH_X - ATTACK_REACH_HALF \
		and dist <= ATTACK_REACH_X + ATTACK_REACH_HALF


## Forward-sweep law as a pure function of window progress p (0..1). player.gd
## rotates the overlay by this * facing (facing mirrors the sign when flipped).
static func sweep_angle(p: float) -> float:
	if p < 0.25:
		return lerpf(0.0, SWEEP_RAISED, p / 0.25)
	if p < 0.55:
		return lerpf(SWEEP_RAISED, SWEEP_FWD, (p - 0.25) / 0.3)
	if p < 0.85:
		return SWEEP_FWD
	return lerpf(SWEEP_FWD, 0.0, (p - 0.85) / 0.15)


static func sword_label(sword: String) -> String:
	return String(SWORDS[sword]["label"])


## Gauntlet multiplier at a depth: 1.25^depth (depth 0 = the unscaled world).
static func mult(depth: int) -> float:
	return pow(MULT_BASE, float(depth))


## One gauntlet-scaled stat: round-half-up (roundi(x) = int(x + 0.5)) of
## base * mult, WITHOUT CAP (owner amendment 2026-10-31). Depth 0 (the
## handcrafted levels) always returns base exactly.
static func gauntlet_stat(base: int, depth: int) -> int:
	if depth <= 0:
		return base
	return int(float(base) * mult(depth) + 0.5)


static func mob_hp(mob_type: String, depth: int = 0) -> int:
	var base := int(MOB_HP[mob_type])
	if is_boss(mob_type):
		return base  # lord + kings are fixed law; the cycle is the escalation
	return gauntlet_stat(base, depth)


static func mob_touch_damage(mob_type: String, depth: int = 0) -> int:
	var base := int(MOB_TOUCH_DAMAGE[mob_type])
	if is_boss(mob_type):
		return base
	return gauntlet_stat(base, depth)


static func is_boss(mob_type: String) -> bool:
	return mob_type == "vampire_lord" or KING_LADDER.has(mob_type)


## Gauntlet depth after `boss_kills` boss kills (lord OR king): the first kill
## opens gauntlet depth 1, every later kill adds one (T7b law 1). boss_kills=0
## (fresh run or after death) = depth 0, the unscaled world.
static func depth_for_boss_kills(boss_kills: int) -> int:
	return maxi(0, boss_kills)


## HUD marker text for a depth: "Harder x<mult>" with one decimal (x1.3, x1.6,
## x2.0 ...). The one-decimal value is itself round-half-up of mult * 10 so the
## display is law-pinned, not printf-rounding-dependent (1.25 -> 1.3, not 1.2).
static func mult_display(depth: int) -> String:
	var one_dp := float(int(mult(depth) * 10.0 + 0.5)) / 10.0
	return "Harder x%.1f" % one_dp


## Which boss the arena holds after `boss_kills` boss kills: 0 = the lord,
## then the king ladder in order, cycling forever (kings return; their own
## stats are fixed — the gauntlet depths between them are the escalation).
static func next_boss_after(boss_kills: int) -> String:
	if boss_kills <= 0:
		return "vampire_lord"
	return String(KING_LADDER[(boss_kills - 1) % KING_LADDER.size()])


## HUD name for a boss id ("" when no boss is on screen).
static func boss_display_name(boss_id: String) -> String:
	if boss_id == "":
		return ""
	return String(BOSS_NAMES[boss_id])


## How many swings of `sword` kill one `mob_type` (ceil division, ints only).
static func hits_to_kill(sword: String, mob_type: String, depth: int = 0) -> int:
	var d := sword_damage(sword)
	return int(ceil(float(mob_hp(mob_type, depth)) / float(d)))


## Eating food heals by the food value but never past MAX_HP.
static func heal(current: int, food: String) -> int:
	return mini(MAX_HP, current + int(FOOD_HEAL[food]))


## Result of opening a chest: candidate replaces current only if strictly better.
static func better_sword(current: String, candidate: String) -> String:
	if SWORD_ORDER.find(candidate) > SWORD_ORDER.find(current):
		return candidate
	return current


static func chest_sword_for_level(level: int) -> String:
	return String(CHEST_SWORD[level])


## What a gauntlet-depth chest holds (T7b law 3): an enchanted sword id for
## depths 1..5, "bread" beyond that (one pickup per depth, never a downgrade —
## better_sword still gates it in game_state.gd).
static func gauntlet_chest(depth: int) -> String:
	return String(GAUNTLET_CHEST.get(depth, "bread"))


## The one legal game state at the start of a run. boss_kills=0 also resets
## the gauntlet depth to 0 (T7b law 6: death resets multiplier AND swords;
## the death -> level-1 law itself is untouched).
static func initial_state() -> Dictionary:
	return {"level": 1, "sword": "wood", "hearts": MAX_HP, "boss_kills": 0}


## Death has no partial resume: the whole game restarts from initial_state().
static func on_death(_state: Dictionary) -> Dictionary:
	return initial_state()

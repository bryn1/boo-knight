extends RefCounted
## Pure combat/rule constants and functions for Boo Knight.
## No scene or node dependencies: both the game and tests/sim.gd use THIS module,
## so a sim failure means the real game rules are wrong. Never add Node usage here.

const MAX_HP := 30
const HP_PER_HEART := 2
const HEARTS_SHOWN := 15  # 15 hearts x 2 HP = 30 HP

## Sword table: dmg + HUD label. Touching a chest with a strictly-better sword upgrades.
const SWORDS := {
	"wood": {"dmg": 1, "label": "Wooden Sword", "icon": "sword_wood"},
	"stone": {"dmg": 2, "label": "Stone Sword", "icon": "sword_stone"},
	"iron": {"dmg": 3, "label": "Iron Sword", "icon": "sword_iron"},
	"diamond": {"dmg": 5, "label": "Diamond Sword", "icon": "sword_diamond"},
}
## Weakest -> strongest. "Better" means strictly later in this list.
const SWORD_ORDER := ["wood", "stone", "iron", "diamond"]

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
## After the lord falls, this ladder guards the arena, ever cycling: kings
## return, harder each time through (the rising mob tier IS the escalation —
## king stats themselves never scale).
const KING_LADDER := ["slime_king", "ghost_king", "zombie_king", "skeleton_king"]
const BOSS_NAMES := {
	"vampire_lord": "Vampire Lord", "slime_king": "Slime King",
	"ghost_king": "Ghost King", "zombie_king": "Zombie King",
	"skeleton_king": "Skeleton King",
}
## Difficulty tier: +1 per boss kill (lord OR king), CAPPED at 3 (owner's kid is
## 6 — never runaway). Resets to 0 on player death with the rest of the run.
const TIER_CAP := 3
## Hard caps from the original HP law stay law: tiered mobs never exceed them.
const MOB_HP_CAP := 10
const MOB_TOUCH_CAP := 6

const FOOD_HEAL := {"apple": 5, "bread": 10}

## Chest in level N contains this sword (levels are 1-based).
const CHEST_SWORD := {1: "stone", 2: "iron", 3: "diamond"}

const ATTACK_COOLDOWN := 0.35  # seconds between sword swings
const INVULN_TIME := 0.8  # seconds of player invulnerability after a hit
## Kid-friendly grace: seconds of contact-damage immunity at the start of every
## run AND every level (the player node is freshly spawned for each).
const SPAWN_GRACE := 3.0


static func sword_damage(sword: String) -> int:
	return int(SWORDS[sword]["dmg"])


static func sword_label(sword: String) -> String:
	return String(SWORDS[sword]["label"])


static func mob_hp(mob_type: String, tier: int = 0) -> int:
	var base := int(MOB_HP[mob_type])
	if is_boss(mob_type):
		return base  # lord + kings are fixed law; the cycle is the escalation
	return mini(MOB_HP_CAP, base + tier)


static func mob_touch_damage(mob_type: String, tier: int = 0) -> int:
	var base := int(MOB_TOUCH_DAMAGE[mob_type])
	if is_boss(mob_type):
		return base
	return mini(MOB_TOUCH_CAP, base + tier)


static func is_boss(mob_type: String) -> bool:
	return mob_type == "vampire_lord" or KING_LADDER.has(mob_type)


## Difficulty tier after `boss_kills` boss kills (lord OR king): +1 each,
## capped at TIER_CAP (4 kills -> tier still 3).
static func tier_for_boss_kills(boss_kills: int) -> int:
	return mini(TIER_CAP, boss_kills)


## Which boss the arena holds after `boss_kills` boss kills: 0 = the lord,
## then the king ladder in order, cycling forever (kings return ever harder).
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
static func hits_to_kill(sword: String, mob_type: String, tier: int = 0) -> int:
	var d := sword_damage(sword)
	return int(ceil(float(mob_hp(mob_type, tier)) / float(d)))


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


## The one legal game state at the start of a run. boss_kills=0 also resets
## the difficulty tier (T6b law: tier resets to 0 on death; the death ->
## level-1 law itself is untouched).
static func initial_state() -> Dictionary:
	return {"level": 1, "sword": "wood", "hearts": MAX_HP, "boss_kills": 0}


## Death has no partial resume: the whole game restarts from initial_state().
static func on_death(_state: Dictionary) -> Dictionary:
	return initial_state()

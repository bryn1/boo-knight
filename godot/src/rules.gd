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
	"skeleton": 6, "vampire": 8, "vampire_lord": 10,
}
const MOB_TOUCH_DAMAGE := {
	"slime": 2, "ghost": 2, "zombie": 3,
	"skeleton": 3, "vampire": 4, "vampire_lord": 6,
}

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


static func mob_hp(mob_type: String) -> int:
	return int(MOB_HP[mob_type])


static func mob_touch_damage(mob_type: String) -> int:
	return int(MOB_TOUCH_DAMAGE[mob_type])


## How many swings of `sword` kill one `mob_type` (ceil division, ints only).
static func hits_to_kill(sword: String, mob_type: String) -> int:
	var d := sword_damage(sword)
	return int(ceil(float(mob_hp(mob_type)) / float(d)))


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


## The one legal game state at the start of a run.
static func initial_state() -> Dictionary:
	return {"level": 1, "sword": "wood", "hearts": MAX_HP}


## Death has no partial resume: the whole game restarts from initial_state().
static func on_death(_state: Dictionary) -> Dictionary:
	return initial_state()

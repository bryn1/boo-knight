extends RefCounted
## Procedural GAUNTLET level generator (T7b, MC 11782 — owner ask 2026-10-31:
## "When ine boss has died, a new level with upgraded monsters come before the
## next boss"). A boss death sends the player through one of these BEFORE the
## next king of the ladder arrives in the arena.
##
## Deterministic law (brief rule 7): seed = depth, so the same depth always
## yields a byte-identical layout (sim.gd generates twice and compares). The
## output is DATA in the exact same shape as the handcrafted LEVELS entries in
## game.gd — one level system, no second one. "depth" is the multiplier depth:
## level.gd hands it to rules.gd (mob stats scale) and to the chest (loot).

const WIDTH := 140            # ~140 tiles wide
const GROUND_ROW := 19        # same surface row as the handcrafted levels
const START_TILE := 2         # same spawn column as the handcrafted levels
const SPAWN_MARGIN := 12      # no mob within this many tiles of the spawn
const EXIT_TILE := 134        # exit door near the end
const CHEST_TILE := 120       # the one chest per gauntlet level
const MOB_ROTATION := ["slime", "ghost", "zombie", "skeleton", "vampire"]
const MOB_COUNT := 10         # fixed rotation: two of each kind per level
const FOOD_TILES := [24, 58, 92, 126]  # 2 bread + 2 apples, deterministic columns

## Pit columns are jittered around fixed bases 35 tiles apart; max jitter 5 +
## max pit width 3 keeps neighbouring pits >= 22 tiles apart, so pits can never
## overlap by construction, and every pit is <= 3 wide => the standard hop clears it.
const PIT_BASES := [35, 70, 105]
const PIT_JITTER := 5
const PIT_MAX_WIDTH := 3


static func generate(depth: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = depth  # same depth => byte-identical layout (law 7)
	# 3-4 ground segments with 2-3 pits between them (law 7).
	var pit_count := rng.randi_range(2, 3)
	var pit_at: Array = []
	var pit_w: Array = []
	for i in pit_count:
		pit_at.append(PIT_BASES[i] + rng.randi_range(-PIT_JITTER, PIT_JITTER))
		pit_w.append(rng.randi_range(1, PIT_MAX_WIDTH))
	var segments: Array = []
	var cursor := 0
	for i in pit_count:
		segments.append([cursor, int(pit_at[i]) - 1, GROUND_ROW])
		cursor = int(pit_at[i]) + int(pit_w[i])
	segments.append([cursor, WIDTH - 1, GROUND_ROW])
	# Mobs: fixed rotation over the five kinds at deterministic columns; ghosts
	# float at row 16, ground kinds stand on row 19. Jitter never reaches the
	# spawn safety margin (first column 16 = 14 tiles from spawn 2).
	var mobs: Array = []
	for i in MOB_COUNT:
		var kind := String(MOB_ROTATION[i % MOB_ROTATION.size()])
		var tile := _clear_of_pits(16 + i * 11 + rng.randi_range(0, 4), pit_at, pit_w)
		mobs.append([kind, tile, 16 if kind == "ghost" else GROUND_ROW])
	# Foods rest on the ground row, so their columns clear the pits too.
	var foods: Array = []
	for i in FOOD_TILES.size():
		var kind := "bread" if i % 2 == 0 else "apple"
		foods.append([kind, _clear_of_pits(FOOD_TILES[i], pit_at, pit_w)])
	return {
		"width_tiles": WIDTH,
		"start": Vector2i(START_TILE, GROUND_ROW),
		"segments": segments,
		"foods": foods,
		"mobs": mobs,
		"chest_tile": _clear_of_pits(CHEST_TILE, pit_at, pit_w),
		"exit_tile": EXIT_TILE,
		"depth": depth,  # level.gd: rules.gd mob scaling + gauntlet chest loot
	}


## Push a requested column rightwards out of any pit it landed in; pit bases
## are far enough apart that the first step out is always solid ground.
static func _clear_of_pits(tile: int, pit_at: Array, pit_w: Array) -> int:
	for i in pit_at.size():
		var a := int(pit_at[i])
		if tile >= a and tile < a + int(pit_w[i]):
			tile = a + int(pit_w[i])
	return tile

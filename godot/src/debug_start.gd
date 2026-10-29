## Gated debug start-tile hook (MC 11612): lets a tester start the hero deeper
## in a level for browser acceptance drives. Requested tile comes from the
## URL query ?start=<int> on the Web runtime (JavaScriptBridge singleton,
## guarded so non-web builds never touch it) or the BOOKNIGHT_START_TILE env
## var on desktop/headless. Unset/empty/unparseable = -1 and every caller
## keeps the level's default start, so the common path is unchanged.
## Purely additive: no rule numbers, no other behaviour.

## -1 when the override is off; any value >= 0 is the requested tile index.
static func request_tile() -> int:
	var raw := ""
	# Measured on 4.7.2 headless: Engine.has_singleton("JavaScriptBridge") is
	# TRUE on desktop too and get_eval there answers a null-ish value, so the
	# platform name gates the call — non-web builds never touch the singleton.
	var os = Engine.get_singleton("OS")
	if String(os.get_name()) == "Web" and Engine.has_singleton("JavaScriptBridge"):
		# Non-blocking get_eval form (use_async = false); the "|| ''" keeps a
		# missing query param an empty string instead of a JS null.
		raw = String(Engine.get_singleton("JavaScriptBridge").call(
			"get_eval", "new URLSearchParams(location.search).get('start') || ''", false))
	if raw == "":
		# Engine-lookup because in -s script mode bare `OS` parses as the
		# class, not the singleton (Godot 4.7 quirk, same as tests/sim.gd).
		raw = String(os.get_environment("BOOKNIGHT_START_TILE"))
	if not raw.is_valid_int():
		return -1
	var tile := int(raw)
	return tile if tile >= 0 else -1


## First tile >= tx that rests on solid ground (inside a [x0,x1] segment, so
## never a pit) and is not a wall column; the spawn row is that segment's top
## row. Returns Vector2i(-1, -1) when no safe tile remains before width_tiles,
## which the caller reads as "fall back to the default start".
static func clamp_to_ground(data: Dictionary, tx: int) -> Vector2i:
	var walls: Array = data.get("walls", [])
	for x in range(maxi(tx, 0), int(data["width_tiles"])):
		var blocked := false
		for w in walls:
			if int(w[0]) == x:
				blocked = true
		if blocked:
			continue
		for seg in data["segments"]:
			if x >= int(seg[0]) and x <= int(seg[1]):
				return Vector2i(x, int(seg[2]))
	return Vector2i(-1, -1)

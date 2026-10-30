extends RefCounted
## Art access with fallback: loads the real PNGs from assets/sprites/ (imported
## by `godot --headless --import` before run/export) and, if a PNG is missing or
## unimported, generates a distinctly colored placeholder texture at the same
## display size so the game always boots — headless and otherwise.

const DIR := "res://assets/sprites/"

## key -> {file: manifest filename, size: display size px, color: placeholder color}
## Portrait mobs/hero are 256x320 (0.8 ratio); display sizes keep that aspect
## so the real sprites are not squashed when scaled to game pixel size.
const VIS := {
	"hero": {"file": "hero.png", "size": Vector2(38, 48), "color": Color(0.2, 0.75, 0.75)},
	"slime": {"file": "slime.png", "size": Vector2(36, 36), "color": Color(0.3, 0.8, 0.25)},
	"ghost": {"file": "ghost.png", "size": Vector2(40, 40), "color": Color(0.9, 0.9, 1.0)},
	"zombie": {"file": "zombie.png", "size": Vector2(35, 44), "color": Color(0.45, 0.65, 0.35)},
	"skeleton": {"file": "skeleton.png", "size": Vector2(38, 48), "color": Color(0.85, 0.85, 0.8)},
	"vampire": {"file": "vampire.png", "size": Vector2(38, 48), "color": Color(0.55, 0.35, 0.75)},
	"vampire_lord": {"file": "vampire_lord.png", "size": Vector2(110, 110), "color": Color(0.5, 0.1, 0.35)},
	"sword_wood": {"file": "sword_wood.png", "size": Vector2(24, 24), "color": Color(0.55, 0.35, 0.2)},
	"sword_stone": {"file": "sword_stone.png", "size": Vector2(24, 24), "color": Color(0.6, 0.6, 0.6)},
	"sword_iron": {"file": "sword_iron.png", "size": Vector2(24, 24), "color": Color(0.8, 0.85, 0.9)},
	"sword_diamond": {"file": "sword_diamond.png", "size": Vector2(24, 24), "color": Color(0.4, 0.9, 0.9)},
	"heart": {"file": "heart.png", "size": Vector2(12, 12), "color": Color(0.9, 0.15, 0.25)},
	"heart_half": {"file": "heart_half.png", "size": Vector2(12, 12), "color": Color(0.55, 0.1, 0.18)},
	"food_apple": {"file": "food_apple.png", "size": Vector2(22, 22), "color": Color(0.85, 0.1, 0.1)},
	"food_bread": {"file": "food_bread.png", "size": Vector2(26, 26), "color": Color(0.8, 0.6, 0.25)},
	"chest": {"file": "chest.png", "size": Vector2(40, 40), "color": Color(0.62, 0.42, 0.16)},
	"tile_ground": {"file": "tile_ground.png", "size": Vector2(16, 16), "color": Color(0.3, 0.22, 0.35)},
	"bg_night": {"file": "bg_night.png", "size": Vector2(640, 360), "color": Color(0.05, 0.05, 0.15)},
	"title": {"file": "title.png", "size": Vector2(640, 360), "color": Color(0.1, 0.05, 0.2)},
}

## Animation keys -> frame-file pairs (T4b, see docs/SPRITES.md). All frames
## face RIGHT; code flips them for left-facing. base is the VIS key whose
## display size + placeholder apply. If any frame file is missing or
## unimported, frames_for returns the single base texture (real or
## placeholder) so callers behave exactly as before the frames landed.
const ANIMS := {
	"hero_walk": {"base": "hero", "frames": ["hero_walk_a.png", "hero_walk_b.png"]},
	"hero_attack": {"base": "hero", "frames": ["hero_attack_a.png", "hero_attack_b.png"]},
	"slime_move": {"base": "slime", "frames": ["slime_move_a.png", "slime_move_b.png"]},
	"ghost_move": {"base": "ghost", "frames": ["ghost_move_a.png", "ghost_move_b.png"]},
	"zombie_walk": {"base": "zombie", "frames": ["zombie_walk_a.png", "zombie_walk_b.png"]},
	"skeleton_walk": {"base": "skeleton", "frames": ["skeleton_walk_a.png", "skeleton_walk_b.png"]},
	"vampire_walk": {"base": "vampire", "frames": ["vampire_walk_a.png", "vampire_walk_b.png"]},
	"vampire_lord_float": {"base": "vampire_lord", "frames": ["vampire_lord_float_a.png", "vampire_lord_float_b.png"]},
}

static var _cache := {}
static var _frames_cache := {}


static func display_size(key: String) -> Vector2:
	return VIS[key]["size"]


## Frame list for an ANIMS key, cached. >1 entry only when every frame PNG
## loaded; otherwise the single base texture via texture_for (fallback path).
static func frames_for(anim: String) -> Array[Texture2D]:
	if _frames_cache.has(anim):
		return _frames_cache[anim]
	var a: Dictionary = ANIMS[anim]
	var frames: Array[Texture2D] = []
	for file in a["frames"]:
		var path := DIR + String(file)
		var tex: Texture2D = null
		if ResourceLoader.exists(path):
			var res := load(path)
			if res is Texture2D:
				tex = res
		if tex == null:
			frames = [texture_for(String(a["base"]))]
			break
		frames.append(tex)
	_frames_cache[anim] = frames
	return frames


## Paint one animation frame on an existing sprite at the base key's display
## size (same scaling rule as make_sprite). No-op when already showing it.
static func apply_frame(sprite: Sprite2D, base_key: String, tex: Texture2D) -> void:
	if sprite.texture == tex:
		return
	var want: Vector2 = VIS[base_key]["size"]
	sprite.texture = tex
	sprite.scale = Vector2(want.x / float(tex.get_width()), want.y / float(tex.get_height()))


static func texture_for(key: String) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var v: Dictionary = VIS[key]
	var path := DIR + String(v["file"])
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		var res := load(path)
		if res is Texture2D:
			tex = res
	if tex == null:
		var size: Vector2 = v["size"]
		var img := Image.create(maxi(1, int(size.x)), maxi(1, int(size.y)), false, Image.FORMAT_RGBA8)
		img.fill(v["color"])
		tex = ImageTexture.create_from_image(img)
	_cache[key] = tex
	return tex


## Sprite2D whose painted height equals the manifest display size, whether the
## real PNG landed (scaled down, nearest filter keeps the pixel look) or not.
static func make_sprite(key: String) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.name = "Sprite2D"  # runtime spawns otherwise get @-names, breaking get_node_or_null("Sprite2D") lookups
	var tex := texture_for(key)
	sp.texture = tex
	var want: Vector2 = VIS[key]["size"]
	sp.scale = Vector2(want.x / float(tex.get_width()), want.y / float(tex.get_height()))
	return sp

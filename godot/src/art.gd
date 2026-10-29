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

static var _cache := {}


static func display_size(key: String) -> Vector2:
	return VIS[key]["size"]


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
	var tex := texture_for(key)
	sp.texture = tex
	var want: Vector2 = VIS[key]["size"]
	sp.scale = Vector2(want.x / float(tex.get_width()), want.y / float(tex.get_height()))
	return sp

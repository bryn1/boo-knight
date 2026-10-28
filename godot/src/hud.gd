extends CanvasLayer
## HUD: 15-heart grid (2 HP per heart, heart.png/heart_half.png with drawn
## fallback), current sword icon + name, and a short toast when the sword changes.

const Art := preload("res://src/art.gd")
const Rules := preload("res://src/rules.gd")

var _hearts: Array[Sprite2D] = []
var _sword_icon: Sprite2D
var _sword_label: Label
var _toast: Label
var _toast_timer := 0.0


func _ready() -> void:
	layer = 10
	for i in Rules.HEARTS_SHOWN:
		var h := Art.make_sprite("heart")
		h.position = Vector2(10 + i * 14, 12)
		add_child(h)
		_hearts.append(h)
	_sword_icon = Art.make_sprite(String(Rules.SWORDS[GameState.sword]["icon"]))
	_sword_icon.position = Vector2(616, 14)
	add_child(_sword_icon)
	_sword_label = Label.new()
	_sword_label.position = Vector2(500, 30)
	_sword_label.size = Vector2(128, 12)
	_sword_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_sword_label.add_theme_font_size_override("font_size", 8)
	_sword_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	add_child(_sword_label)
	_toast = Label.new()
	_toast.position = Vector2(0, 60)
	_toast.size = Vector2(640, 16)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 10)
	_toast.modulate.a = 0.0
	add_child(_toast)
	GameState.hearts_changed.connect(_on_hearts_changed)
	GameState.sword_changed.connect(_on_sword_changed)
	_refresh(GameState.hearts)
	_show_sword(GameState.sword)


func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		_toast.modulate.a = clampf(_toast_timer, 0.0, 1.0)


func _on_hearts_changed(hp: int) -> void:
	_refresh(hp)


func _refresh(hp: int) -> void:
	for i in _hearts.size():
		var full_at := (i + 1) * Rules.HP_PER_HEART
		if hp >= full_at:
			_hearts[i].texture = Art.texture_for("heart")
			_hearts[i].modulate = Color(1, 1, 1, 1)
		elif hp >= full_at - 1:
			_hearts[i].texture = Art.texture_for("heart_half")
			_hearts[i].modulate = Color(1, 1, 1, 1)
		else:
			_hearts[i].texture = Art.texture_for("heart")
			_hearts[i].modulate = Color(1, 1, 1, 0.15)


func _on_sword_changed(sword_id: String) -> void:
	_show_sword(sword_id)
	_toast.text = Rules.sword_label(sword_id) + "!"
	_toast_timer = 2.0


func _show_sword(sword_id: String) -> void:
	_sword_icon.texture = Art.texture_for(String(Rules.SWORDS[sword_id]["icon"]))
	_sword_label.text = Rules.sword_label(sword_id)

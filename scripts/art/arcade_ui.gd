class_name ArcadeUI
extends RefCounted

const INK := Color("101a2c")
const CREAM := Color("fff3d1")
const TEAL := Color("83ece0")
const GOLD := Color("ffd55f")
const BLUE := Color("b2e8f2")
const FONT := preload("res://assets/fonts/PressStart2P-Regular.ttf")
const PANELS := preload("res://assets/arcade/ui/panel-states.png")


static func atlas(path: String, region: Rect2) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = load(path)
	result.region = region
	result.filter_clip = true
	return result


static func style(index := 0) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = atlas("res://assets/arcade/ui/panel-states.png", Rect2((index % 2) * 256, floori(index / 2.0) * 128, 256, 128))
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_texture_margin(side, 16)
		box.set_content_margin(side, 20)
	return box


static func panel(parent: Node, rect: Rect2, selected := false) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_stylebox_override("panel", style(1 if selected else 0))
	parent.add_child(node)
	return node


static func label(parent: Node, text: String, rect: Rect2, size := 24, color := CREAM, centered := false) -> Label:
	var node := Label.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_override("font", FONT)
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


static func button(parent: Node, text: String, rect: Rect2, action: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.add_theme_font_override("font", FONT)
	node.add_theme_font_size_override("font_size", 24)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		node.add_theme_stylebox_override(state, style(1 if state in ["hover", "focus"] else 2 if state == "pressed" else 3 if state == "disabled" else 0))
	node.add_theme_color_override("font_color", CREAM)
	node.add_theme_color_override("font_focus_color", GOLD)
	node.add_theme_color_override("font_hover_color", GOLD)
	node.pressed.connect(action)
	node.mouse_entered.connect(func() -> void: node.grab_focus())
	parent.add_child(node)
	return node


static func image(parent: Node, texture: Texture2D, position: Vector2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.position = position
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


static func portrait(parent: Node, color: String, position: Vector2, animation := "idle_front") -> AnimatedSprite2D:
	var node := AnimatedSprite2D.new()
	node.sprite_frames = load("res://resources/arcade/bomber_%s.tres" % color)
	node.position = position
	node.play(animation)
	parent.add_child(node)
	return node


static func backdrop(parent: Node) -> ColorRect:
	var node := ColorRect.new()
	node.color = INK
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


static func header(parent: Node, subtitle: String) -> void:
	image(parent, atlas("res://assets/arcade/ui/screen-menu.png", Rect2(0, 0, 1024, 150)), Vector2.ZERO)
	label(parent, subtitle, Rect2(0, 158, 1024, 42), 24, TEAL, true)

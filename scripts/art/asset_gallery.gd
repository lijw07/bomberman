extends Control

var records: Array
var selector: OptionButton
var animations: OptionButton
var viewport: SubViewport
var container: SubViewportContainer
var details: Label
var instance: Node
var sprite: AnimatedSprite2D


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ArcadeUI.backdrop(self)
	records = JSON.parse_string(FileAccess.get_file_as_string("res://assets/arcade/manifest.json")).scenes
	ArcadeUI.label(self, "IMPORTED ASSET GALLERY", Rect2(24, 12, 900, 48), 24)
	selector = OptionButton.new()
	selector.position = Vector2(24, 72)
	selector.size = Vector2(680, 40)
	selector.add_theme_font_override("font", ArcadeUI.FONT)
	selector.add_theme_font_size_override("font_size", 14)
	for record: Dictionary in records:
		selector.add_item(record.scene.get_file().get_basename().replace("_", " "))
	add_child(selector)
	selector.item_selected.connect(show_asset)
	animations = OptionButton.new()
	animations.position = Vector2(720, 72)
	animations.size = Vector2(280, 40)
	add_child(animations)
	animations.item_selected.connect(func(index: int) -> void:
		if is_instance_valid(sprite):
			sprite.play(animations.get_item_text(index)))
	details = ArcadeUI.label(self, "", Rect2(24, 120, 976, 56), 12, ArcadeUI.TEAL)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(24, 188)
	scroll.size = Vector2(976, 560)
	add_child(scroll)
	container = SubViewportContainer.new()
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scroll.add_child(container)
	viewport = SubViewport.new()
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	container.add_child(viewport)
	show_asset(0)


func show_asset(index: int) -> void:
	if is_instance_valid(instance):
		instance.free()
	sprite = null
	animations.clear()
	var record: Dictionary = records[index]
	instance = load(record.scene).instantiate()
	if instance.get("repeat_preview") != null:
		instance.repeat_preview = true
	var ui := instance is Control
	viewport.size = Vector2i(1100, 1120) if ui else Vector2i(976, 560)
	container.custom_minimum_size = viewport.size
	viewport.add_child(instance)
	instance.position = Vector2(24, 24) if ui else Vector2(488, 312)
	if instance.has_node("AnimatedSprite2D"):
		sprite = instance.get_node("AnimatedSprite2D")
		for animation in sprite.sprite_frames.get_animation_names():
			animations.add_item(animation)
			if animation == sprite.animation:
				animations.select(animations.item_count - 1)
		sprite.animation_finished.connect(func() -> void:
			if is_instance_valid(sprite):
				sprite.play(sprite.animation))
	var collision_text := "No world collision: decorative / UI artwork"
	if instance is CollisionObject2D:
		collision_text = "%s  |  layer %d  |  mask %d" % [instance.get_class(), instance.collision_layer, instance.collision_mask]
		var shape: CollisionShape2D = instance.get_node("CollisionShape2D")
		var outline := Line2D.new()
		outline.default_color = Color(0.3, 1.0, 0.6, 0.85)
		outline.width = 1.0
		var half: Vector2 = shape.shape.size * 0.5
		outline.points = PackedVector2Array([-half, Vector2(half.x, -half.y), half, Vector2(-half.x, half.y), -half])
		outline.position = shape.position
		instance.add_child(outline)
	details.text = record.scene + "\n" + collision_text + "  |  native pixels"

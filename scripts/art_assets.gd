class_name ArtAssets
extends RefCounted
## Native reference-image edits; original generated masters remain immutable.
const ATLAS: Texture2D = preload("res://assets/art/sprite_atlas.png")
const BACKGROUND: Texture2D = preload("res://assets/art/battle_background.png")
const REGIONS: Dictionary = {
	"ally_mech": Rect2(50,78,253,272),
	"ally_drone": Rect2(320,141,298,149),
	"ally_fighter": Rect2(655,97,279,238),
	"enemy_hound": Rect2(963,122,257,202),
	"enemy_walker": Rect2(37,476,291,310),
	"enemy_elite": Rect2(341,433,261,351),
	"portrait_mech": Rect2(642,475,280,288),
	"portrait_drone": Rect2(956,475,282,289),
	"portrait_fighter": Rect2(16,893,280,289),
	"mothership": Rect2(329,892,282,284),
	"pause": Rect2(665,916,221,228),
	"hangar": Rect2(941,919,293,240),
}
static func draw_fit(canvas: CanvasItem,key: String,box: Rect2,tint: Color=Color.WHITE) -> void:
	var source: Rect2 = REGIONS[key]
	var scale_factor: float = minf(box.size.x/source.size.x,box.size.y/source.size.y)
	var size: Vector2 = source.size*scale_factor
	canvas.draw_texture_rect_region(ATLAS,Rect2(box.position+(box.size-size)/2,size),source,tint)

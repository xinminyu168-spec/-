extends Button
const FONT: Font = preload("res://assets/fonts/ntm-ui.otf")
@export var round_shape: bool = false
@export var caption: String = ""
var golden: bool = false
func _ready() -> void:
	for key: String in ["normal","hover","pressed","disabled","focus"]: add_theme_stylebox_override(key,StyleBoxEmpty.new())
@export var art_key: String = ""
func _draw() -> void:
	if art_key.is_empty(): return
	var center: Vector2 = size/2
	var tint: Color = Color.WHITE if golden else Color(0.52,0.58,0.63)
	ArtAssets.draw_fit(self,art_key,Rect2(Vector2.ZERO,size),tint)
	if golden and not round_shape:
		var outline: PackedVector2Array = []
		for i in range(7): outline.append(center+Vector2.from_angle(PI/3*(i%6))*69)
		draw_polyline(outline,Color(1,0.85,0.3,0.8),2,true)
	# Label is below the artwork so it never hides the portrait.
	var title: String = caption.get_slice("\n",0)
	if not round_shape: title = caption.left(1)+"号 · "+caption.get_slice("\n",1)
	var width: float = FONT.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,19).x
	draw_string(FONT,Vector2(center.x-width/2,-8),title,HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("e4e8dc"))
	if round_shape and not golden:
		var second: String = caption.get_slice("\n",1)
		var w: float = FONT.get_string_size(second,HORIZONTAL_ALIGNMENT_LEFT,-1,22).x
		draw_string(FONT,center+Vector2(-w/2,8),second,HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color.WHITE)

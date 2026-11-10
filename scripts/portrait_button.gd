extends Button
const FONT: Font = preload("res://assets/fonts/ntm-ui.otf")
@export var round_shape: bool = false
@export var caption: String = ""
var golden: bool = false
func _ready() -> void:
	for key: String in ["normal","hover","pressed","disabled","focus"]: add_theme_stylebox_override(key,StyleBoxEmpty.new())
func _draw() -> void:
	var center: Vector2 = size/2
	var radius: float = minf(size.x,size.y)/2-8
	var edge: Color = Color("ffd66b") if golden else Color("7797aa")
	var fill: Color = Color("304f61") if not disabled else Color("25303b")
	if round_shape:
		draw_circle(center,radius,fill)
		draw_arc(center,radius,0,TAU,64,edge,4,true)
	else:
		var points: PackedVector2Array = []
		for i in range(6): points.append(center+Vector2.from_angle(PI/3*i)*radius)
		draw_colored_polygon(points,fill)
		var outline: PackedVector2Array = points.duplicate()
		outline.append(points[0])
		draw_polyline(outline,edge,7 if golden else 3,true)
		if golden:
			var glow: PackedVector2Array = []
			for i in range(7): glow.append(center+Vector2.from_angle(PI/3*(i%6))*(radius+6))
			draw_polyline(glow,Color(1,0.8,0.25,0.3),7,true)
	var lines: PackedStringArray = caption.split("\n")
	for i in range(lines.size()):
		var width: float = FONT.get_string_size(lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,22).x
		draw_string(FONT,center+Vector2(-width/2,-4+i*29),lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("e2eff5"))

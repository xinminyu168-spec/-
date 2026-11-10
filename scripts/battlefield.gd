extends Node2D
func _draw() -> void:
	draw_rect(Rect2(0,0,1920,1080),Color("111e2c"))
	draw_rect(Rect2(0,170,1920,610),Color("203c46"))
	draw_rect(Rect2(40,205,1840,540),Color("2b4c50"),false,3)
	draw_set_transform(Vector2(1000,560),0,Vector2(1,0.3))
	draw_circle(Vector2.ZERO,530,Color("38565a"))
	draw_arc(Vector2.ZERO,530,0,TAU,96,Color("719084"),5,true)
	draw_arc(Vector2.ZERO,440,0,TAU,96,Color("55776e"),3,true)
	draw_set_transform(Vector2.ZERO)
	for y in [430,540,650]: draw_dashed_line(Vector2(310,y),Vector2(1750,y),Color(0.6,0.7,0.7,0.12),2,18)
	draw_rect(Rect2(0,790,1920,290),Color("142430"))
	draw_line(Vector2(0,790),Vector2(1920,790),Color("536c72"),3)

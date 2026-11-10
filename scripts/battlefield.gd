extends Node2D


func _draw() -> void:
	draw_rect(Rect2(20, 145, 500, 655), Color("122333"))
	for x in [155.0, 385.0]:
		draw_rect(Rect2(x - 66.0, 154.0, 132.0, 577.0), Color("1a3041"))
		draw_dashed_line(Vector2(x, 220), Vector2(x, 700), Color("304d5d"), 2.0, 9.0)
		draw_circle(Vector2(x, 185), 8.0, Color("ff6670"))
	draw_line(Vector2(270, 150), Vector2(270, 794), Color("3d5367"), 2.0)
	draw_rect(Rect2(20, 451, 500, 42), Color("254459"))
	draw_string(ThemeDB.fallback_font, Vector2(35, 478), "交战区", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("97b8cc"))
	draw_line(Vector2(24, 795), Vector2(516, 795), Color("467b9c"), 2.0)

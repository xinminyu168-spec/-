extends Node2D
func _draw() -> void:
	draw_texture_rect(ArtAssets.BACKGROUND,Rect2(0,0,1920,1080),false)
	# Subtle dark glass keeps the counters and bottom controls readable.
	draw_rect(Rect2(0,0,1920,160),Color(0.02,0.05,0.08,0.48))
	draw_rect(Rect2(0,790,1920,290),Color(0.02,0.04,0.07,0.63))
	draw_line(Vector2(0,790),Vector2(1920,790),Color(0.8,0.65,0.36,0.5),2)

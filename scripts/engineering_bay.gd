class_name EngineeringBay
extends Node2D

const UI_FONT: Font = preload("res://assets/fonts/ntm-ui.otf")

@export var lane: int = 0
@export_range(0.5, 30.0, 0.5) var spawn_interval: float = 4.0

var game: BattleGame
var produced: int = 0
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var spawn_timer: Timer = $SpawnTimer


func setup(owner_game: BattleGame) -> void:
	game = owner_game
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	queue_redraw()


func start_production() -> void:
	spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	if not is_instance_valid(game):
		return
	var offset := Vector2(float(produced % 3 - 1) * 12.0, 0.0)
	game.spawn_unit(UnitAgent.TEAM_ALLY, lane, spawn_point.global_position + offset)
	produced += 1
	# Inspector changes while running apply to the next production cycle.
	spawn_timer.wait_time = maxf(0.5, spawn_interval)


func _draw() -> void:
	draw_rect(Rect2(-44.0, -25.0, 88.0, 50.0), Color("254b6d"))
	draw_rect(Rect2(-44.0, -25.0, 88.0, 50.0), Color("6bc8ff"), false, 2.0)
	draw_rect(Rect2(-18.0, -30.0, 36.0, 9.0), Color("8be2ff"))
	var label: String = "工程舱 L" if lane == 0 else "工程舱 R"
	draw_string(UI_FONT, Vector2(-32.0, 6.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color.WHITE)

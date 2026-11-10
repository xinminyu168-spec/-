class_name EngineeringBay
extends Node2D
const FONT: Font = preload("res://assets/fonts/ntm-ui.otf")
@export var lane: int = 0
@export var spawn_interval: float = 4.0
@export var max_hp: float = 600.0
var hp: float = 600.0
var energy: int = 0
var game: BattleGame
var produced: int = 0
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var spawn_timer: Timer = $SpawnTimer
func setup(owner_game: BattleGame) -> void:
	game = owner_game
	hp = max_hp
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
func start_production() -> void:
	if hp > 0: spawn_timer.start()
func add_energy(amount: int) -> void:
	energy = clampi(energy + amount,0,100)
	game.state_changed.emit()
func _on_spawn_timer_timeout() -> void:
	if not is_instance_valid(game) or not game.running or hp <= 0: return
	var agent: UnitAgent = game.spawn_unit(0,lane,spawn_point.global_position+Vector2(0,(produced%3-1)*15))
	agent.origin_base = self
	produced += 1
	spawn_timer.wait_time = maxf(0.5,spawn_interval)
func take_damage(amount: float) -> void:
	if hp <= 0: return
	var actual: float = minf(hp,amount)
	hp -= actual
	game.add_damage_text(global_position,actual)
	if hp <= 0: spawn_timer.stop()
	queue_redraw()
	game.state_changed.emit()
	game.check_defeat()
func _draw() -> void:
	var colors: Array[Color] = [Color("4bbcff"),Color("b395ff"),Color("68e5bd")]
	var color: Color = colors[lane] if hp > 0 else Color("49525e")
	draw_rect(Rect2(-55,-39,110,78),Color("223242"))
	draw_rect(Rect2(-55,-39,110,78),color,false,3)
	draw_rect(Rect2(45,-16,30,32),color)
	draw_rect(Rect2(-55,-55,110,7),Color("35434c"))
	draw_rect(Rect2(-55,-55,110*hp/max_hp,7),Color("79e17e"))
	draw_string(FONT,Vector2(-40,8),"工程基地 %d"%(lane+1),HORIZONTAL_ALIGNMENT_LEFT,-1,17,color)

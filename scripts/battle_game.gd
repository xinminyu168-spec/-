class_name BattleGame
extends Node2D

signal state_changed

@export var unit_scene: PackedScene = preload("res://scenes/unit.tscn")
@export var auto_start: bool = true

var energy: int = 0
var kills: int = 0
var notice: String = "蓝方每 4 秒产兵。能量满后手动选择技能。"
var simulation_time: float = 0.0
var running: bool = false
var hit_effects: Array[Dictionary] = []

@onready var units_root: Node2D = $Units
@onready var wave_manager: WaveManager = $WaveManager
@onready var left_bay: EngineeringBay = $EngineeringBays/LeftBay
@onready var right_bay: EngineeringBay = $EngineeringBays/RightBay
@onready var hud: BattleHUD = $UI/HUD


func _ready() -> void:
	left_bay.setup(self)
	right_bay.setup(self)
	wave_manager.setup(self, $EnemySpawnPoints/LeftSpawn, $EnemySpawnPoints/RightSpawn)
	hud.setup(self)
	if auto_start:
		start_run()


func start_run() -> void:
	if running:
		return
	running = true
	left_bay.start_production()
	right_bay.start_production()
	wave_manager.start_next_wave()


func _physics_process(delta: float) -> void:
	if not running:
		return
	simulation_time += delta
	# Advance a previously scheduled wait before attacks; the death frame is not counted.
	wave_manager.tick(delta)
	for unit: UnitAgent in get_live_units():
		unit.tick(delta)
	for effect: Dictionary in hit_effects:
		effect["remaining"] = float(effect["remaining"]) - delta
	hit_effects = hit_effects.filter(func(effect: Dictionary) -> bool: return float(effect["remaining"]) > 0.0)
	queue_redraw()


func spawn_unit(side: int, route: int, location: Vector2, elite: bool = false) -> UnitAgent:
	var unit: UnitAgent = unit_scene.instantiate() as UnitAgent
	units_root.add_child(unit)
	unit.global_position = location
	unit.configure(self, side, route, elite)
	state_changed.emit()
	return unit


func get_live_units(side: int = -1) -> Array[UnitAgent]:
	var result: Array[UnitAgent] = []
	for child: Node in units_root.get_children():
		if child is UnitAgent and child.alive and (side == -1 or child.team == side):
			result.append(child)
	return result


func find_target(attacker: UnitAgent) -> UnitAgent:
	var best: UnitAgent = null
	var best_distance: float = INF
	for other: UnitAgent in get_live_units():
		if other.team == attacker.team or other.lane != attacker.lane:
			continue
		var distance: float = attacker.global_position.distance_squared_to(other.global_position)
		if distance <= attacker.attack_range * attacker.attack_range and distance < best_distance:
			best = other
			best_distance = distance
	return best


func add_energy(amount: int) -> void:
	energy = clampi(energy + amount, 0, 100)
	state_changed.emit()


func deal_damage(target: UnitAgent, amount: float, _source: UnitAgent = null, kill_energy: int = 20) -> bool:
	if not is_instance_valid(target) or not target.alive:
		return false
	var killed: bool = target.take_damage(amount)
	if killed and target.team == UnitAgent.TEAM_ENEMY:
		kills += 1
		add_energy(kill_energy)
		wave_manager.notify_enemy_died(target)
	state_changed.emit()
	return killed


func perform_basic_attack(attacker: UnitAgent, target: UnitAgent) -> void:
	if not attacker.alive or not target.alive:
		return
	var reward: int = 0
	if attacker.team == UnitAgent.TEAM_ALLY:
		add_energy(2)
		reward = 20
	add_hit_effect(attacker.global_position, target.global_position, Color("b1e6ff"))
	deal_damage(target, attacker.attack_damage, attacker, reward)


func perform_elite_burst(elite: UnitAgent) -> void:
	add_hit_effect(elite.global_position, elite.global_position, Color("ff796b"), elite.elite_burst_radius)
	for unit: UnitAgent in get_live_units(UnitAgent.TEAM_ALLY):
		if unit.global_position.distance_to(elite.global_position) <= elite.elite_burst_radius:
			deal_damage(unit, elite.elite_burst_damage, elite)
	show_notice("精英大招已释放：红圈附近己方单位受到伤害。")


func can_cast() -> bool:
	return running and energy >= 100 and not get_tree().paused


func spend_energy() -> bool:
	if not can_cast():
		return false
	energy -= 100
	state_changed.emit()
	return true


func show_notice(text: String) -> void:
	notice = text
	state_changed.emit()


func add_hit_effect(from: Vector2, to: Vector2, color: Color, radius: float = 0.0) -> void:
	hit_effects.append({"from": from, "to": to, "color": color, "radius": radius, "remaining": 0.3})


func _draw() -> void:
	for effect: Dictionary in hit_effects:
		if float(effect["radius"]) > 0.0:
			draw_arc(effect["to"], effect["radius"], 0.0, TAU, 48, effect["color"], 3.0, true)
		else:
			draw_line(effect["from"], effect["to"], effect["color"], 2.0, true)

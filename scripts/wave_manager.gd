class_name WaveManager
extends Node
## Transitions never reset the battle, allies, production timers or energy.

@export_range(0.0, 10.0, 0.5) var inter_wave_delay: float = 2.0
@export_range(1, 10, 1) var initial_enemies_per_lane: int = 2
@export_range(0, 5, 1) var additional_per_wave: int = 1
@export_range(1, 10, 1) var max_enemies_per_lane: int = 6
@export_range(1, 99, 1) var elite_from_wave: int = 2

var game: BattleGame
var spawn_points: Array[Marker2D] = []
var wave_number: int = 0
var remaining_enemies: int = 0
var waiting: bool = false
var wait_remaining: float = 0.0
var active: bool = false
var enemy_ids: Dictionary = {}


func setup(owner_game: BattleGame, left: Marker2D, right: Marker2D) -> void:
	game = owner_game
	spawn_points = [left, right]


func start_next_wave() -> void:
	if active or not is_instance_valid(game):
		return
	wave_number += 1
	waiting = false
	wait_remaining = 0.0
	active = true
	enemy_ids.clear()
	var count: int = mini(max_enemies_per_lane, initial_enemies_per_lane + (wave_number - 1) * additional_per_wave)
	for route in range(2):
		for index in range(count):
			var elite: bool = wave_number >= elite_from_wave and index == count - 1
			var offset := Vector2(float(index % 3 - 1) * 30.0, -floorf(float(index) / 3.0) * 34.0)
			var unit: UnitAgent = game.spawn_unit(UnitAgent.TEAM_ENEMY, route, spawn_points[route].global_position + offset, elite)
			unit.wave_number = wave_number
			enemy_ids[unit.get_instance_id()] = true
	remaining_enemies = enemy_ids.size()
	game.show_notice("第 %d 波：%d 个敌人从上方两路进场。" % [wave_number, remaining_enemies])
	game.state_changed.emit()


func notify_enemy_died(unit: UnitAgent) -> void:
	var id: int = unit.get_instance_id()
	if not active or not enemy_ids.has(id):
		return
	enemy_ids.erase(id)
	remaining_enemies = enemy_ids.size()
	if remaining_enemies == 0:
		active = false
		waiting = true
		wait_remaining = inter_wave_delay
		game.show_notice("本波清空！保留己方机甲与能量，%.1f 秒后下一波。" % inter_wave_delay)
	game.state_changed.emit()


func tick(delta: float) -> void:
	if not waiting:
		return
	wait_remaining = maxf(0.0, wait_remaining - delta)
	if wait_remaining <= 0.00001:
		start_next_wave()

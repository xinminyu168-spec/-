class_name WaveManager
extends Node
@export var total_waves: int = 3
@export var inter_wave_delay: float = 2.0
var game: BattleGame
var wave_number: int = 0
var remaining_enemies: int = 0
var waiting: bool = false
var wait_remaining: float = 0.0
var active: bool = false
var enemy_ids: Dictionary = {}
func start_next_wave() -> void:
	if active or not game.running or wave_number >= total_waves: return
	wave_number += 1
	waiting = false
	active = true
	enemy_ids.clear()
	for route in range(3):
		for index in range(wave_number+1):
			var elite: bool = wave_number>=2 and index==wave_number
			var agent: UnitAgent = game.spawn_unit(1,route,Vector2(1590+index*55,430+route*110),elite)
			agent.wave_number = wave_number
			enemy_ids[agent.get_instance_id()] = true
	remaining_enemies = enemy_ids.size()
	game.show_notice("第 %d / %d 波敌军来袭"%[wave_number,total_waves])
func notify_enemy_died(agent: UnitAgent) -> void:
	if not active or not enemy_ids.has(agent.get_instance_id()): return
	enemy_ids.erase(agent.get_instance_id())
	remaining_enemies = enemy_ids.size()
	if remaining_enemies==0:
		active = false
		if wave_number==total_waves:
			game.finish("胜利：三波敌军已全部击破",true)
		else:
			waiting = true
			wait_remaining = inter_wave_delay
			game.show_notice("本波清空，保留单位、基地血量与能量，2 秒后继续")
	game.state_changed.emit()
func tick(delta: float) -> void:
	if waiting:
		wait_remaining = maxf(0,wait_remaining-delta)
		if wait_remaining<=0.00001: start_next_wave()

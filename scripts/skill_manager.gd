class_name SkillManager
extends Node
## These three public functions can be connected directly to Button.pressed.

@export var bombard_damage: float = 120.0
@export var bombard_kill_refund: int = 5
@export var strike_damage: float = 300.0
@export var stun_duration: float = 2.0
@export var shield_amount: float = 150.0
@export var shield_duration: float = 5.0

var game: BattleGame


func get_charging_elite() -> UnitAgent:
	var best: UnitAgent = null
	for enemy: UnitAgent in game.get_live_units(UnitAgent.TEAM_ENEMY):
		if not enemy.is_elite or enemy.charge_remaining <= 0.0 or enemy.stun_remaining > 0.0:
			continue
		if not is_instance_valid(best) or enemy.charge_remaining < best.charge_remaining:
			best = enemy
	return best


func cast_luanniao_bombardment() -> bool:
	var enemies: Array[UnitAgent] = game.get_live_units(UnitAgent.TEAM_ENEMY)
	if enemies.is_empty() or not game.spend_energy(0):
		return false
	var defeated: int = 0
	for enemy: UnitAgent in enemies:
		game.add_hit_effect(Vector2(enemy.global_position.x, 150.0), enemy.global_position, Color("ffcc86"))
		# The new brief says +20 per kill, with an EXTRA +5 for bombardment.
		if game.deal_damage(enemy, bombard_damage, null, 20 + bombard_kill_refund, game.bases[0]):
			defeated += 1
	game.show_notice("鸾鸟轰炸：击杀 %d 个敌人，每个回能 20 + %d（上限100）。" % [defeated, bombard_kill_refund])
	return true


func cast_xuannv_strike() -> bool:
	var target: UnitAgent = get_charging_elite()
	if not is_instance_valid(target) or not game.spend_energy(1):
		return false
	game.add_hit_effect(Vector2(target.global_position.x, 140.0), target.global_position, Color("cfb7ff"))
	game.deal_damage(target, strike_damage, null, 25, game.bases[1])
	if target.alive:
		target.interrupt_and_stun(stun_duration)
	game.show_notice("玄女点杀：300 伤害，取消蓄力；存活目标眩晕 2 秒。")
	return true


func cast_chengying_shield() -> bool:
	var allies: Array[UnitAgent] = game.get_live_units(UnitAgent.TEAM_ALLY)
	if allies.is_empty() or not game.spend_energy(2):
		return false
	for unit: UnitAgent in allies:
		unit.apply_shield(shield_amount, shield_duration)
	game.show_notice("承影护盾：%d 台己方机甲获得护盾，持续 5 秒。" % allies.size())
	return true

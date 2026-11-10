class_name UnitAgent
extends Node2D
## A whitebox unit. BattleGame calls tick(); no collision or navigation is needed.

const TEAM_ALLY := 0
const TEAM_ENEMY := 1

@export var move_speed: float = 48.0
@export var attack_range: float = 76.0
@export var attack_damage: float = 10.0
@export var attack_interval: float = 1.0
@export var elite_charge_interval: float = 8.0
@export var elite_charge_duration: float = 3.0
@export var elite_burst_damage: float = 60.0
@export var elite_burst_radius: float = 145.0

var game: BattleGame
var team: int = TEAM_ALLY
var lane: int = 0
var is_elite: bool = false
var alive: bool = true
var max_hp: float = 100.0
var hp: float = 100.0
var shield: float = 0.0
var max_shield: float = 150.0
var shield_remaining: float = 0.0
var stun_remaining: float = 0.0
var charge_remaining: float = 0.0
var special_clock: float = 8.0
var attack_clock: float = 0.0
var state: String = "moving"
var wave_number: int = 0


func configure(owner_game: BattleGame, side: int, route: int, elite: bool = false) -> void:
	game = owner_game
	team = side
	lane = route
	is_elite = elite and side == TEAM_ENEMY
	max_hp = 400.0 if is_elite else 100.0
	hp = max_hp
	if is_elite:
		move_speed = 30.0
	special_clock = elite_charge_interval
	queue_redraw()


func tick(delta: float) -> void:
	if not alive:
		return
	# Status durations use game time and naturally pause with the scene tree.
	shield_remaining = maxf(0.0, shield_remaining - delta)
	if shield_remaining <= 0.0:
		shield = 0.0
	attack_clock = maxf(0.0, attack_clock - delta)
	if is_elite:
		special_clock = maxf(0.0, special_clock - delta)
	if stun_remaining > 0.0:
		stun_remaining = maxf(0.0, stun_remaining - delta)
		state = "stunned"
		queue_redraw()
		return
	if charge_remaining > 0.0:
		charge_remaining = maxf(0.0, charge_remaining - delta)
		state = "charging"
		if charge_remaining <= 0.00001:
			charge_remaining = 0.0
			game.perform_elite_burst(self)
			state = "moving"
		queue_redraw()
		return
	if is_elite and special_clock <= 0.00001:
		# Charge begins every eight seconds, including the three charge seconds.
		special_clock = elite_charge_interval
		charge_remaining = elite_charge_duration
		state = "charging"
		game.show_notice("敌方精英蓄力！点击「玄女」打断红圈。")
		queue_redraw()
		return
	var target: UnitAgent = game.find_target(self)
	if is_instance_valid(target):
		state = "attacking"
		if attack_clock <= 0.00001:
			attack_clock = attack_interval
			game.perform_basic_attack(self, target)
	else:
		state = "moving"
		var direction: float = -1.0 if team == TEAM_ALLY else 1.0
		position.y += direction * move_speed * delta
		# Staging lines keep surviving units visible between waves.
		if team == TEAM_ALLY:
			position.y = maxf(position.y, 210.0)
		else:
			position.y = minf(position.y, 710.0)
	queue_redraw()


func take_damage(amount: float) -> bool:
	if not alive or amount <= 0.0:
		return false
	var absorbed: float = minf(shield, amount)
	shield -= absorbed
	hp = maxf(0.0, hp - (amount - absorbed))
	queue_redraw()
	if hp > 0.0:
		return false
	alive = false
	charge_remaining = 0.0
	hide()
	queue_free()
	return true


func interrupt_and_stun(duration: float) -> void:
	if not alive:
		return
	charge_remaining = 0.0
	stun_remaining = maxf(stun_remaining, duration)
	state = "stunned"
	# The interrupted burst is cancelled, not released when the stun wears off.
	queue_redraw()


func apply_shield(amount: float, duration: float) -> void:
	if not alive:
		return
	shield = amount
	max_shield = maxf(1.0, amount)
	shield_remaining = duration
	queue_redraw()


func _draw() -> void:
	if not alive:
		return
	var half: float = 18.0 if is_elite else 12.0
	var body_color := Color("47b5ff") if team == TEAM_ALLY else Color("fa616c")
	if is_elite:
		body_color = Color("d83d58")
	if charge_remaining > 0.0:
		var progress: float = 1.0 - charge_remaining / elite_charge_duration
		draw_circle(Vector2.ZERO, 31.0 + progress * 8.0, Color(1.0, 0.1, 0.12, 0.12 + progress * 0.55))
		draw_arc(Vector2.ZERO, 37.0, -PI / 2.0, -PI / 2.0 + TAU * progress, 48, Color("ffb1a2"), 3.0, true)
	draw_rect(Rect2(-half, -half, half * 2.0, half * 2.0), body_color)
	var direction: float = -1.0 if team == TEAM_ALLY else 1.0
	draw_line(Vector2(-5.0, direction * 6.0), Vector2(0.0, direction * 10.0), Color.WHITE, 2.0)
	draw_line(Vector2(0.0, direction * 10.0), Vector2(5.0, direction * 6.0), Color.WHITE, 2.0)
	draw_rect(Rect2(-20.0, -half - 9.0, 40.0, 4.0), Color("243147"))
	draw_rect(Rect2(-20.0, -half - 9.0, 40.0 * hp / max_hp, 4.0), Color("b2f487"))
	if shield > 0.0:
		draw_arc(Vector2.ZERO, half + 8.0, 0.0, TAU, 32, Color("89f5ef"), 2.0, true)
		draw_rect(Rect2(-20.0, -half - 15.0, 40.0 * shield / max_shield, 3.0), Color("89f5ef"))
	if stun_remaining > 0.0:
		draw_line(Vector2(-8.0, -8.0), Vector2(8.0, 8.0), Color("f1ddff"), 3.0)
		draw_line(Vector2(-8.0, 8.0), Vector2(8.0, -8.0), Color("f1ddff"), 3.0)

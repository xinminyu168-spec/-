class_name UnitAgent
extends Node2D
## Rendered sprite and independent combat state. BattleGame calls tick().

const TEAM_ALLY := 0
const TEAM_ENEMY := 1

@export var move_speed: float = 110.0
@export var attack_range: float = 115.0
@export var attack_damage: float = 10.0
@export var attack_interval: float = 1.0
@export var elite_charge_interval: float = 8.0
@export var elite_charge_duration: float = 3.0
@export var elite_burst_damage: float = 60.0
@export var elite_burst_radius: float = 220.0

var game: BattleGame
var origin_base: EngineeringBay
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
		move_speed = 75.0
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
		if team == TEAM_ENEMY and game.can_attack_base(self):
			state = "attacking"
			if attack_clock <= 0.00001:
				attack_clock = attack_interval
				game.attack_base(self)
		else:
			state = "moving"
			var direction: float = 1.0 if team == TEAM_ALLY else -1.0
			position.x = clampf(position.x + direction * move_speed * delta, 210.0, 1580.0)
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


func art_key() -> String:
	if team == TEAM_ALLY:
		return ["ally_mech","ally_drone","ally_fighter"][lane]
	if is_elite: return "enemy_elite"
	return "enemy_walker" if wave_number >= 2 else "enemy_hound"

func visual_height() -> float:
	if is_elite: return 175.0
	if team==TEAM_ALLY: return [125.0,78.0,105.0][lane]
	return 125.0 if wave_number>=2 else 85.0

func _draw() -> void:
	if not alive: return
	var height: float = visual_height()
	var ground: float = 24.0
	var width: float = height * ArtAssets.REGIONS[art_key()].size.x / ArtAssets.REGIONS[art_key()].size.y
	var bob: float = sin(game.simulation_time*8.0+get_instance_id()%7)*2.0 if state=="moving" else 0.0
	draw_set_transform(Vector2(0,ground),0,Vector2(1,0.22))
	draw_circle(Vector2.ZERO,width*0.38,Color(0,0,0,0.25))
	draw_set_transform(Vector2.ZERO)
	if charge_remaining>0:
		var progress: float = 1.0-charge_remaining/elite_charge_duration
		draw_circle(Vector2(0,ground),55,Color(1,0.05,0.08,0.12+0.35*progress))
		draw_arc(Vector2(0,ground),58,-PI/2,-PI/2+TAU*progress,48,Color("ff8173"),4,true)
		draw_rect(Rect2(-42,-height-18,84,7),Color("422b28"))
		draw_rect(Rect2(-42,-height-18,84*progress,7),Color("ffaa57"))
	var tint: Color = Color(0.72,0.67,1) if stun_remaining>0 else Color.WHITE
	ArtAssets.draw_fit(self,art_key(),Rect2(-width/2,-height+ground+bob,width,height),tint)
	# Health/status overlays stay independent of the artwork.
	draw_rect(Rect2(-32,-height+9,64,5),Color("243147"))
	draw_rect(Rect2(-32,-height+9,64*hp/max_hp,5),Color("b2f487"))
	if shield>0:
		draw_arc(Vector2(0,-height*0.32),height*0.65,0,TAU,48,Color("89f5ef"),2,true)
		draw_rect(Rect2(-32,-height,64*shield/max_shield,4),Color("89f5ef"))
	if stun_remaining>0:
		draw_line(Vector2(-10,-height-8),Vector2(10,-height+8),Color("e8dcff"),4)
		draw_line(Vector2(-10,-height+8),Vector2(10,-height-8),Color("e8dcff"),4)

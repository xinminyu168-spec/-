class_name BattleGame
extends Node2D
signal state_changed
const FONT: Font = preload("res://assets/fonts/ntm-ui.otf")
@export var unit_scene: PackedScene = preload("res://scenes/unit.tscn")
@export var auto_start: bool = true
@export var time_limit: float = 90.0
var kills: int = 0
var coins: int = 0
var chests: int = 0
var notice: String = "能量独立积累，点击金色头像释放技能"
var simulation_time: float = 0
var remaining_time: float = 90
var running: bool = false
var auto_battle: bool = false
var result: String = ""
var ship_cooldown: float = 0
var auto_clock: float = 0
var hit_effects: Array[Dictionary] = []
var damage_texts: Array[Dictionary] = []
var bases: Array[EngineeringBay] = []
@onready var units_root: Node2D = $Units
@onready var wave_manager: WaveManager = $WaveManager
@onready var skills: SkillManager = $SkillManager
@onready var hud: BattleHUD = $UI/HUD
func _ready() -> void:
	for base: EngineeringBay in $EngineeringBays.get_children():
		bases.append(base)
		base.setup(self)
	wave_manager.game = self
	skills.game = self
	remaining_time = time_limit
	hud.setup(self)
	if auto_start: start_run()
func start_run() -> void:
	if running or not result.is_empty(): return
	running = true
	for base: EngineeringBay in bases: base.start_production()
	wave_manager.start_next_wave()
func _physics_process(delta: float) -> void:
	if not running: return
	simulation_time += delta
	remaining_time = maxf(0,remaining_time-delta)
	if remaining_time<=0:
		finish("失败：90 秒倒计时结束",false)
		return
	ship_cooldown = maxf(0,ship_cooldown-delta)
	wave_manager.tick(delta)
	for agent: UnitAgent in get_live_units():
		if not running: break
		agent.tick(delta)
	if auto_battle and running and wave_manager.active:
		auto_clock -= delta
		if auto_clock<=0:
			auto_clock = 0.25
			skills.cast_xuannv_strike()
			skills.cast_chengying_shield()
			skills.cast_luanniao_bombardment()
	for e: Dictionary in hit_effects: e["remaining"]-=delta
	hit_effects = hit_effects.filter(func(e: Dictionary) -> bool: return e["remaining"]>0)
	for e: Dictionary in damage_texts: e["remaining"]-=delta
	damage_texts = damage_texts.filter(func(e: Dictionary) -> bool: return e["remaining"]>0)
	queue_redraw()
func spawn_unit(side: int,route: int,location: Vector2,elite: bool=false) -> UnitAgent:
	var agent: UnitAgent = unit_scene.instantiate() as UnitAgent
	units_root.add_child(agent)
	agent.global_position = location
	agent.configure(self,side,route,elite)
	return agent
func get_live_units(side: int=-1) -> Array[UnitAgent]:
	var items: Array[UnitAgent] = []
	for child: Node in units_root.get_children():
		if child is UnitAgent and child.alive and (side==-1 or child.team==side): items.append(child)
	return items
func find_target(attacker: UnitAgent) -> UnitAgent:
	var best: UnitAgent
	var closest: float = INF
	for other: UnitAgent in get_live_units():
		if other.team==attacker.team or other.lane!=attacker.lane: continue
		var distance: float = other.global_position.distance_squared_to(attacker.global_position)
		if distance<=attacker.attack_range*attacker.attack_range and distance<closest:
			best = other
			closest = distance
	return best
func can_attack_base(enemy: UnitAgent) -> bool:
	return bases[enemy.lane].hp>0 and enemy.position.x<=bases[enemy.lane].position.x+enemy.attack_range
func attack_base(enemy: UnitAgent) -> void:
	bases[enemy.lane].take_damage(enemy.attack_damage)
func check_defeat() -> void:
	for base: EngineeringBay in bases:
		if base.hp>0: return
	finish("失败：所有工程基地已被摧毁",false)
func deal_damage(target: UnitAgent,amount: float,source: UnitAgent=null,kill_energy: int=20,skill_owner: EngineeringBay=null) -> bool:
	if not is_instance_valid(target) or not target.alive: return false
	var before: float = target.hp
	var killed: bool = target.take_damage(amount)
	add_damage_text(target.global_position+Vector2(0,-target.visual_height()+45),before-target.hp)
	if killed and target.team==1:
		kills += 1
		coins += 10
		var owner: EngineeringBay = skill_owner
		if is_instance_valid(source): owner = source.origin_base
		if is_instance_valid(owner): owner.add_energy(kill_energy)
		wave_manager.notify_enemy_died(target)
	state_changed.emit()
	return killed
func perform_basic_attack(attacker: UnitAgent,target: UnitAgent) -> void:
	if not attacker.alive or not target.alive: return
	if attacker.team==0 and is_instance_valid(attacker.origin_base): attacker.origin_base.add_energy(2)
	add_hit_effect(attacker.global_position,target.global_position,Color("b1e6ff"))
	deal_damage(target,attacker.attack_damage,attacker)
func perform_elite_burst(elite: UnitAgent) -> void:
	add_hit_effect(elite.global_position,elite.global_position,Color("ff796b"),elite.elite_burst_radius)
	for agent: UnitAgent in get_live_units(0):
		if agent.global_position.distance_to(elite.global_position)<=elite.elite_burst_radius: deal_damage(agent,elite.elite_burst_damage,elite)
	for base: EngineeringBay in bases:
		if base.global_position.distance_to(elite.global_position)<=elite.elite_burst_radius: base.take_damage(elite.elite_burst_damage)
func can_cast(index: int) -> bool:
	return running and not get_tree().paused and bases[index].hp>0 and bases[index].energy>=100
func spend_energy(index: int) -> bool:
	if not can_cast(index): return false
	bases[index].energy -= 100
	state_changed.emit()
	return true
func cast_mothership() -> bool:
	if not running or get_tree().paused or ship_cooldown>0 or get_live_units(1).is_empty(): return false
	ship_cooldown = 20
	for enemy: UnitAgent in get_live_units(1): deal_damage(enemy,60,null,0)
	show_notice("母舰法宝：全场 60 伤害，独立冷却 20 秒")
	return true
func finish(message: String,victory: bool) -> void:
	if not running: return
	running = false
	result = message
	if victory: chests += 1
	for base: EngineeringBay in bases: base.spawn_timer.stop()
	state_changed.emit()
func show_notice(text: String) -> void:
	notice = text
	state_changed.emit()
func add_hit_effect(from: Vector2,to: Vector2,color: Color,radius: float=0) -> void:
	hit_effects.append({"from":from,"to":to,"color":color,"radius":radius,"remaining":0.3})
func add_damage_text(at: Vector2,amount: float) -> void:
	damage_texts.append({"at":at,"text":"-%d"%roundi(amount),"remaining":0.85})
func _draw() -> void:
	for e: Dictionary in hit_effects:
		if e["radius"]>0: draw_arc(e["to"],e["radius"],0,TAU,48,e["color"],3,true)
		else: draw_line(e["from"],e["to"],e["color"],3,true)
	for e: Dictionary in damage_texts:
		var point: Vector2 = e["at"]+Vector2(-25,-40-(0.85-e["remaining"])*85)
		draw_string(FONT,point+Vector2(2,2),e["text"],HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color.BLACK)
		draw_string(FONT,point,e["text"],HORIZONTAL_ALIGNMENT_LEFT,-1,32,Color(1,0.25,0.26,minf(1,e["remaining"]*3)))

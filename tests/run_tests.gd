extends SceneTree
var checks: int = 0
var failures: int = 0
var packed: PackedScene = preload("res://scenes/main.tscn")
func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func make_game() -> BattleGame:
	var game: BattleGame = packed.instantiate()
	game.auto_start = false
	root.add_child(game)
	game.set_physics_process(false)
	game.running = true
	return game
func agent(game: BattleGame,team: int,x: float,base: int=0,elite: bool=false) -> UnitAgent:
	var item: UnitAgent = game.spawn_unit(team,base,Vector2(x,430+base*110),elite)
	if team==0: item.origin_base=game.bases[base]
	return item
func run() -> void:
	test_layout_and_combat()
	test_skills()
	test_waves()
	test_auto_and_end()
	test_complete_match()
	await test_real_production()
	print("NANTIANMEN TESTS: %d checks, %d failures"%[checks,failures])
	quit(0 if failures==0 else 1)
func test_layout_and_combat() -> void:
	var g: BattleGame = make_game()
	check(g.bases.size()==3,"three engineering bases")
	check(not g.auto_battle and g.remaining_time==90,"manual mode and 90 seconds")
	check(ProjectSettings.get_setting("display/window/size/viewport_width")==1920,"landscape width")
	check(ProjectSettings.get_setting("display/window/size/viewport_height")==1080,"landscape height")
	for i in range(3):
		g.bases[i]._on_spawn_timer_timeout()
		check(g.bases[i].spawn_timer.wait_time==4,"independent four-second timers")
	var allies: Array[UnitAgent] = g.get_live_units(0)
	check(allies.size()==3,"three bases each produce a unit")
	for i in range(3): check(allies[i].origin_base==g.bases[i],"unit remembers its birth base")
	var blue: UnitAgent = agent(g,0,800,1)
	var red: UnitAgent = agent(g,1,880,1)
	blue.tick(0.01)
	check(blue.position.x==800 and red.hp==90,"stop in range and hit ten")
	check(g.bases[1].energy==2 and g.bases[0].energy==0 and g.bases[2].energy==0,"energy goes only to the owner")
	blue.tick(0.9)
	check(red.hp==90,"no extra hit before one second")
	blue.tick(0.1)
	check(red.hp==80,"next basic after one second")
	red.hp=10
	g.perform_basic_attack(blue,red)
	check(g.bases[1].energy==26 and g.kills==1 and g.coins==10,"kill rewards owner and coins")
	g.deal_damage(red,10,blue)
	check(g.kills==1,"no duplicate kill rewards")
	blue.tick(0.1)
	check(blue.position.x>800,"survivor resumes rightward movement")
	check(not g.damage_texts.is_empty() and g.damage_texts[0]["text"]=="-10","actual red damage popup")
	g.bases[1].add_energy(999)
	check(g.bases[1].energy==100,"energy capped")
	var enemy: UnitAgent = agent(g,1,600,2)
	enemy.tick(0.5)
	check(enemy.position.x<600,"enemy advances left")
	g.attack_base(enemy)
	check(g.bases[2].hp==590 and g.bases[0].hp==600,"enemy damages corresponding base")
	g.free()
func test_skills() -> void:
	var g: BattleGame = make_game()
	var blue: UnitAgent = agent(g,0,900)
	var a: UnitAgent = agent(g,1,1050)
	var b: UnitAgent = agent(g,1,1100,2)
	g.bases[0].energy=100
	g.hud.refresh()
	check(g.hud.portraits[0].golden and g.bases[0].energy==100 and a.hp==100,"gold highlight never auto casts")
	g.hud.get_node("Portrait1").pressed.emit()
	check(not a.alive and not b.alive and blue.hp==100,"AOE targets all enemies only")
	check(g.bases[0].energy==50 and g.bases[1].energy==0,"AOE refunds 25 per kill to base one")
	var elite: UnitAgent = agent(g,1,1080,0,true)
	elite.move_speed=0
	elite.tick(7.9)
	check(elite.charge_remaining==0,"elite waits eight seconds")
	elite.tick(0.1)
	check(elite.charge_remaining==3,"three-second telegraph")
	g.bases[1].energy=100
	g.skills.cast_xuannv_strike()
	check(elite.hp==100 and elite.stun_remaining==2 and elite.charge_remaining==0,"strike damages and cancels burst")
	check(g.bases[1].energy==0,"strike spends its own energy")
	var x: float = elite.position.x
	elite.tick(1.9)
	check(elite.position.x==x and blue.hp==100,"stun suppresses motion and burst")
	g.bases[1].energy=100
	check(not g.skills.cast_xuannv_strike() and g.bases[1].energy==100,"no charging target means no cost")
	g.bases[2].energy=100
	g.skills.cast_chengying_shield()
	check(blue.shield==150 and g.bases[2].energy==0,"shield uses base three energy")
	g.deal_damage(blue,170,elite)
	check(blue.shield==0 and blue.hp==80,"shield absorbs before HP")
	blue.apply_shield(150,5)
	blue.tick(5.01)
	check(blue.shield==0,"five-second shield expires")
	g.free()
func test_waves() -> void:
	var g: BattleGame = make_game()
	var survivor: UnitAgent = agent(g,0,700)
	survivor.hp=53
	g.bases[0].hp=431
	g.bases[0].energy=47
	g.bases[1].energy=82
	g.bases[2].energy=19
	g.wave_manager.start_next_wave()
	check(g.wave_manager.wave_number==1 and g.wave_manager.remaining_enemies==6,"first of three waves")
	for enemy: UnitAgent in g.get_live_units(1): g.deal_damage(enemy,10000,null,0)
	check(g.wave_manager.waiting and g.running,"clearing wave schedules a transition")
	g.wave_manager.tick(1.99)
	check(g.wave_manager.wave_number==1,"full two-second gap required")
	g.wave_manager.tick(0.01)
	check(g.wave_manager.wave_number==2 and g.get_live_units(1).size()==9,"second wave includes three formations")
	check(survivor.alive and survivor.hp==53 and g.bases[0].hp==431,"survivor and base HP retained")
	check(g.bases[0].energy==47 and g.bases[1].energy==82 and g.bases[2].energy==19,"all independent energy values retained")
	for enemy: UnitAgent in g.get_live_units(1): g.deal_damage(enemy,10000,null,0)
	g.wave_manager.tick(2)
	check(g.wave_manager.wave_number==3 and g.get_live_units(1).size()==12,"third wave spawns")
	for enemy: UnitAgent in g.get_live_units(1): g.deal_damage(enemy,10000,null,0)
	check(not g.running and g.chests==1 and g.result.begins_with("胜利"),"third clear awards one chest and victory")
	g.wave_manager.tick(10)
	g.wave_manager.start_next_wave()
	check(g.wave_manager.wave_number==3,"no fourth wave")
	g.free()
func test_auto_and_end() -> void:
	var g: BattleGame = make_game()
	g.wave_manager.start_next_wave()
	g.bases[0].energy=100
	g._physics_process(0.1)
	check(g.bases[0].energy==100,"manual mode retains full energy")
	g.hud.get_node("AutoButton").button_pressed=true
	g._physics_process(0.25)
	check(g.auto_battle and g.kills==6,"autoplay explicitly enables skill casting")
	g.hud.get_node("AutoButton").button_pressed=false
	check(not g.auto_battle,"autoplay can be disabled")
	g.remaining_time=0.01
	g._physics_process(0.02)
	check(not g.running and g.result.begins_with("失败"),"timeout ends the match")
	g.free()
	g=make_game()
	for base: EngineeringBay in g.bases: base.take_damage(600)
	check(not g.running,"destroying every base causes defeat")
	g.free()
func test_real_production() -> void:
	var g: BattleGame = make_game()
	for base: EngineeringBay in g.bases: base.start_production()
	await create_timer(3.8,true).timeout
	check(g.get_live_units(0).is_empty(),"real Timer does not spawn early")
	await create_timer(0.4,true).timeout
	check(g.get_live_units(0).size()==3,"three real four-second Timers produce independently")
	g.set_physics_process(true)
	var before: float = g.remaining_time
	paused=true
	await create_timer(0.15,true).timeout
	check(g.remaining_time==before,"pause freezes match timer")
	paused=false
	await create_timer(0.15,true).timeout
	check(g.remaining_time<before,"resume advances timer")
	g.free()

func test_complete_match() -> void:
	var g: BattleGame = make_game()
	g.auto_battle=true
	g.wave_manager.start_next_wave()
	for frame in range(5401):
		if not g.running: break
		if frame>0 and frame%240==0:
			for base: EngineeringBay in g.bases: base._on_spawn_timer_timeout()
		g._physics_process(1.0/60)
	print("SIMULATION: ",g.result," wave=",g.wave_manager.wave_number," time=",g.simulation_time)
	check(g.result.begins_with("胜利"),"default auto battle can finish all three waves within 90 seconds")
	g.free()

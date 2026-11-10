extends SceneTree
## Run after importing: godot --headless --path . --script res://tests/run_tests.gd

var checks: int = 0
var failures: int = 0
var packed: PackedScene = preload("res://scenes/main.tscn")


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + description)


func make_game() -> BattleGame:
	var game: BattleGame = packed.instantiate() as BattleGame
	game.auto_start = false
	root.add_child(game)
	game.set_physics_process(false)
	game.running = true
	return game


func unit(game: BattleGame, team: int, y: float, elite: bool = false) -> UnitAgent:
	return game.spawn_unit(team, 0, Vector2(155, y), elite)


func _run() -> void:
	test_scene_and_production()
	test_basic_combat()
	test_elite_charge()
	test_bombardment()
	test_interrupt()
	test_shield()
	test_waves()
	test_button_guards()
	test_long_run()
	await test_real_timers_and_pause()
	print("NANTIANMEN TESTS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func test_scene_and_production() -> void:
	var game: BattleGame = make_game()
	check(game.left_bay.position == Vector2(155, 760), "left bay position")
	check(game.right_bay.position == Vector2(385, 760), "right bay position")
	check(game.left_bay.spawn_timer.wait_time == 4.0, "left production interval")
	check(game.right_bay.spawn_timer.wait_time == 4.0, "right production interval")
	game.left_bay.start_production()
	check(not game.left_bay.spawn_timer.is_stopped(), "production timer starts")
	game.left_bay.spawn_timer.timeout.emit()
	game.right_bay.spawn_timer.timeout.emit()
	var allies: Array[UnitAgent] = game.get_live_units(0)
	check(allies.size() == 2, "two independent bays each create one unit")
	check(allies[0].lane == 0 and allies[1].lane == 1, "bay lane ownership")
	var before: float = allies[0].position.y
	allies[0].tick(0.5)
	check(allies[0].position.y < before, "allies move up")
	var red: UnitAgent = unit(game, 1, 300)
	red.tick(0.5)
	check(red.position.y > 300, "enemies move down")
	game.free()


func test_real_timers_and_pause() -> void:
	var game: BattleGame = make_game()
	game.set_physics_process(true)
	game.left_bay.start_production()
	game.right_bay.start_production()
	await create_timer(3.8, true).timeout
	check(game.get_live_units(0).is_empty(), "real timers do not produce early")
	await create_timer(0.4, true).timeout
	check(game.get_live_units(0).size() == 2, "real timers produce two units after four seconds")
	game.wave_manager.start_next_wave()
	for enemy: UnitAgent in game.get_live_units(1):
		game.deal_damage(enemy, 1000, null, 0)
	var remaining: float = game.wave_manager.wait_remaining
	var before: float = game.simulation_time
	paused = true
	await create_timer(0.15, true).timeout
	check(game.wave_manager.wait_remaining == remaining and game.simulation_time == before, "real scene pause freezes wave and game clocks")
	paused = false
	await create_timer(0.15, true).timeout
	check(game.wave_manager.wait_remaining < remaining and game.simulation_time > before, "resume advances only the remaining countdown")
	game.free()


func test_basic_combat() -> void:
	var game: BattleGame = make_game()
	var blue: UnitAgent = unit(game, 0, 400)
	var red: UnitAgent = unit(game, 1, 350)
	blue.tick(0.01)
	check(blue.position.y == 400, "stop within attack range")
	check(red.hp == 90 and game.energy == 2, "basic hit deals ten and gives two energy")
	blue.tick(0.9)
	check(red.hp == 90, "no attack before one second")
	blue.tick(0.1)
	check(red.hp == 80 and game.energy == 4, "attack after one second")
	red.hp = 10
	game.perform_basic_attack(blue, red)
	check(game.energy == 26 and game.kills == 1, "lethal hit gives two plus twenty")
	game.deal_damage(red, 10, blue)
	check(game.energy == 26 and game.kills == 1, "dead targets do not reward twice")
	var before: float = blue.position.y
	blue.tick(0.1)
	check(blue.position.y < before, "resume moving after target death")
	var other_lane: UnitAgent = unit(game, 1, blue.position.y - 20)
	other_lane.lane = 1
	check(game.find_target(blue) == null, "lanes do not target each other")
	game.energy = 99
	game.add_energy(25)
	check(game.energy == 100, "energy capped at one hundred")
	game.free()


func test_elite_charge() -> void:
	var game: BattleGame = make_game()
	var elite: UnitAgent = unit(game, 1, 350, true)
	var blue: UnitAgent = unit(game, 0, 450)
	elite.move_speed = 0
	elite.tick(7.9)
	check(elite.charge_remaining == 0, "no special before eight seconds")
	elite.tick(0.1)
	check(elite.charge_remaining == 3 and elite.state == "charging", "eight seconds starts three-second charge")
	elite.tick(2.9)
	check(blue.hp == 100, "warning circle precedes burst damage")
	elite.tick(0.1)
	check(blue.hp == 40, "burst hits nearby ally for sixty")
	elite.tick(5.0)
	check(elite.charge_remaining == 3, "next charge begins eight seconds after previous charge began")
	game.free()


func test_bombardment() -> void:
	var game: BattleGame = make_game()
	var skills: SkillManager = game.get_node("SkillManager")
	var blue: UnitAgent = unit(game, 0, 600)
	var a: UnitAgent = unit(game, 1, 250)
	var b: UnitAgent = game.spawn_unit(1, 1, Vector2(385, 250))
	var elite: UnitAgent = unit(game, 1, 350, true)
	game.energy = 100
	check(skills.cast_luanniao_bombardment(), "bombardment casts manually")
	check(not a.alive and not b.alive, "AOE hits enemies in both lanes")
	check(elite.hp == 280 and blue.hp == 100, "AOE spares allies and deals 120")
	check(game.energy == 50, "each skill kill returns twenty plus extra five")
	check(not skills.cast_luanniao_bombardment(), "insufficient energy blocks another cast")
	game.free()


func test_interrupt() -> void:
	var game: BattleGame = make_game()
	var skills: SkillManager = game.get_node("SkillManager")
	var blue: UnitAgent = unit(game, 0, 450)
	var elite: UnitAgent = unit(game, 1, 350, true)
	game.energy = 100
	check(not skills.cast_xuannv_strike() and game.energy == 100, "no charging target means no spending")
	elite.charge_remaining = 1.0
	elite.state = "charging"
	check(skills.cast_xuannv_strike(), "strike accepts a charging elite")
	check(elite.hp == 100 and elite.charge_remaining == 0, "strike deals 300 and cancels pending burst")
	check(elite.stun_remaining == 2 and game.energy == 0, "strike costs 100 and stuns for two seconds")
	var before: Vector2 = elite.position
	elite.tick(1.9)
	check(elite.position == before and blue.hp == 100, "stun blocks movement and damage")
	elite.tick(0.11)
	elite.tick(0.01)
	check(elite.charge_remaining == 0 and blue.hp == 100, "cancelled burst is never released after stun")
	game.free()


func test_shield() -> void:
	var game: BattleGame = make_game()
	var skills: SkillManager = game.get_node("SkillManager")
	var blue: UnitAgent = unit(game, 0, 600)
	var blue_right: UnitAgent = game.spawn_unit(0, 1, Vector2(385, 600))
	var red: UnitAgent = unit(game, 1, 200)
	game.energy = 100
	check(skills.cast_chengying_shield(), "shield casts")
	check(blue.shield == 150 and blue_right.shield == 150 and red.shield == 0, "shield covers all current allies only")
	game.deal_damage(blue, 170, red)
	check(blue.shield == 0 and blue.hp == 80, "shield absorbs first and excess reaches HP")
	var newborn: UnitAgent = unit(game, 0, 700)
	check(newborn.shield == 0, "new units do not inherit an old cast")
	blue_right.tick(4.9)
	check(blue_right.shield == 150, "shield remains before five seconds")
	blue_right.tick(0.11)
	check(blue_right.shield == 0, "shield expires after five seconds")
	game.free()


func test_waves() -> void:
	var game: BattleGame = make_game()
	var waves: WaveManager = game.wave_manager
	waves.initial_enemies_per_lane = 1
	waves.additional_per_wave = 0
	waves.elite_from_wave = 99
	var survivor: UnitAgent = unit(game, 0, 500)
	survivor.hp = 53
	game.energy = 47
	waves.start_next_wave()
	check(waves.wave_number == 1 and waves.remaining_enemies == 2, "first wave spawns both top lanes")
	var enemies: Array[UnitAgent] = game.get_live_units(1)
	game.deal_damage(enemies[0], 1000, survivor, 0)
	check(waves.active and not waves.waiting, "partial clear does not progress")
	game.deal_damage(enemies[1], 1000, survivor, 0)
	check(waves.waiting and waves.wait_remaining == 2, "last death starts two-second interval")
	waves.notify_enemy_died(enemies[1])
	check(waves.wait_remaining == 2, "duplicate death does not reschedule countdown")
	waves.tick(1.99)
	check(waves.wave_number == 1, "no early next wave")
	waves.tick(0.01)
	check(waves.wave_number == 2 and waves.remaining_enemies == 2, "next wave after full delay")
	check(survivor.alive and survivor.hp == 53 and survivor.position.y == 500, "same survivor and HP persist")
	check(game.energy == 47, "stored energy persists")
	waves.start_next_wave()
	check(waves.wave_number == 2, "active wave cannot spawn twice")
	game.free()


func test_button_guards() -> void:
	var game: BattleGame = make_game()
	var skills: SkillManager = game.get_node("SkillManager")
	var elite: UnitAgent = unit(game, 1, 300, true)
	unit(game, 0, 600)
	elite.charge_remaining = 3
	game.energy = 100
	game.hud.refresh()
	check(not game.hud.skill_one.disabled and not game.hud.skill_two.disabled and not game.hud.skill_three.disabled, "full energy lights valid skill buttons")
	check(game.energy == 100 and elite.hp == 400, "refresh never auto-casts")
	game.hud.skill_two.pressed.emit()
	check(game.energy == 0 and elite.hp == 100, "button signal calls the actual independent skill function")
	game.energy = 100
	root.get_tree().paused = true
	check(not skills.cast_chengying_shield(), "skills cannot cast while paused")
	game.hud.refresh()
	check(game.hud.skill_one.disabled and game.hud.skill_three.disabled, "pause disables skill UI")
	root.get_tree().paused = false
	game.free()


func test_long_run() -> void:
	var game: BattleGame = make_game()
	game.wave_manager.start_next_wave()
	var skills: SkillManager = game.get_node("SkillManager")
	for frame: int in range(7200):
		if frame > 0 and frame % 240 == 0:
			game.left_bay.spawn_timer.timeout.emit()
			game.right_bay.spawn_timer.timeout.emit()
		game._physics_process(1.0 / 60.0)
		if game.energy == 100:
			if is_instance_valid(skills.get_charging_elite()):
				skills.cast_xuannv_strike()
			else:
				skills.cast_luanniao_bombardment()
	check(game.wave_manager.wave_number >= 2, "full simulation progresses beyond the first wave")
	check(game.kills > 0 and game.energy >= 0 and game.energy <= 100, "long-run kills and energy remain valid")
	for agent: UnitAgent in game.get_live_units():
		check(agent.hp > 0 and agent.hp <= agent.max_hp and agent.position.is_finite(), "live unit state valid")
	game.free()

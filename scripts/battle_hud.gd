class_name BattleHUD
extends Control
const FONT: Font = preload("res://assets/fonts/ntm-ui.otf")
var game: BattleGame
@onready var portraits: Array[Button] = [$Portrait1,$Portrait2,$Portrait3]
func setup(owner_game: BattleGame) -> void:
	game = owner_game
	process_mode = Node.PROCESS_MODE_ALWAYS
	$ShipButton.pressed.connect(game.cast_mothership)
	$Portrait1.pressed.connect(game.skills.cast_luanniao_bombardment)
	$Portrait2.pressed.connect(game.skills.cast_xuannv_strike)
	$Portrait3.pressed.connect(game.skills.cast_chengying_shield)
	$AutoButton.toggled.connect(func(enabled: bool) -> void: game.auto_battle=enabled)
	$PauseButton.pressed.connect(func() -> void: get_tree().paused=not get_tree().paused)
	$RestartButton.pressed.connect(func() -> void: get_tree().paused=false; get_tree().reload_current_scene())
	refresh()
func _process(_delta: float) -> void:
	if is_instance_valid(game): refresh()
func refresh() -> void:
	var wave: WaveManager = game.wave_manager
	$WaveLabel.text = "%d / %d"%[wave.wave_number,wave.total_waves]
	var seconds: int = ceili(game.remaining_time)
	$TimerLabel.text = "%02d:%02d"%[seconds/60,seconds%60]
	$ResourcesLabel.text = "金币  %d     宝箱  %d"%[game.coins,game.chests]
	$NoticeLabel.text = ("下一波 %.1f 秒  ·  " % wave.wait_remaining if wave.waiting else "")+game.notice
	$ResultLabel.text = game.result
	$ResultLabel.visible = not game.result.is_empty()
	$PauseButton.text = "继续" if get_tree().paused else "暂停"
	$AutoButton.text = "托管：开" if game.auto_battle else "托管：关"
	$AutoButton.disabled = not game.running
	for i in range(3):
		portraits[i].golden = game.bases[i].energy==100 and game.bases[i].hp>0
		portraits[i].disabled = not game.can_cast(i)
		portraits[i].queue_redraw()
	$Portrait1.disabled = $Portrait1.disabled or game.get_live_units(1).is_empty()
	$Portrait2.disabled = $Portrait2.disabled or not is_instance_valid(game.skills.get_charging_elite())
	$Portrait3.disabled = $Portrait3.disabled or game.get_live_units(0).is_empty()
	$ShipButton.disabled = not game.running or get_tree().paused or game.ship_cooldown>0 or game.get_live_units(1).is_empty()
	$ShipButton.caption = "母舰法宝\n"+("就绪" if game.ship_cooldown<=0 else "%.0f 秒"%ceilf(game.ship_cooldown))
	$ShipButton.golden = not $ShipButton.disabled
	$ShipButton.queue_redraw()
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(game): return
	for i in range(3):
		var x: float = 785+i*220
		var base: EngineeringBay = game.bases[i]
		draw_rect(Rect2(x,992,150,16),Color("17222a"))
		draw_rect(Rect2(x,992,150*base.hp/base.max_hp,16),Color("63d775"))
		draw_rect(Rect2(x,1017,150,16),Color("17222a"))
		draw_rect(Rect2(x,1017,150*base.energy/100.0,16),Color("f6ce4c"))
		draw_string(FONT,Vector2(x,1060),"HP %d · 能量 %d"%[roundi(base.hp),base.energy],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("c0d0da"))

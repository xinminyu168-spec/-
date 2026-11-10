class_name BattleHUD
extends Control

var game: BattleGame
@onready var energy_label: Label = $EnergyLabel
@onready var energy_bar: ProgressBar = $EnergyBar
@onready var wave_label: Label = $WaveLabel
@onready var notice_label: Label = $NoticeLabel
@onready var unit_label: Label = $UnitLabel
@onready var skill_one: Button = $SkillButtons/LuanniaoButton
@onready var skill_two: Button = $SkillButtons/XuannvButton
@onready var skill_three: Button = $SkillButtons/ChengyingButton
@onready var pause_button: Button = $PauseButton
@onready var restart_button: Button = $RestartButton
@onready var skills: SkillManager = $"../../SkillManager"


func setup(owner_game: BattleGame) -> void:
	game = owner_game
	process_mode = Node.PROCESS_MODE_ALWAYS
	skills.game = game
	# Connect in code OR using the Signals panel, never both.
	skill_one.pressed.connect(skills.cast_luanniao_bombardment)
	skill_two.pressed.connect(skills.cast_xuannv_strike)
	skill_three.pressed.connect(skills.cast_chengying_shield)
	pause_button.pressed.connect(_on_pause_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	game.state_changed.connect(refresh)
	refresh()


func _process(_delta: float) -> void:
	if is_instance_valid(game):
		refresh()


func refresh() -> void:
	energy_label.text = "能量 %d / 100" % game.energy
	energy_bar.value = game.energy
	var wave: WaveManager = game.wave_manager
	wave_label.text = "第 %d 波 · 剩余 %d" % [wave.wave_number, wave.remaining_enemies]
	if wave.waiting:
		wave_label.text = "第 %d 波已清空 · 下一波 %.1f 秒" % [wave.wave_number, wave.wait_remaining]
	notice_label.text = game.notice
	unit_label.text = "己方 %d 台  |  敌方 %d 台  |  击杀 %d" % [game.get_live_units(0).size(), game.get_live_units(1).size(), game.kills]
	var ready: bool = game.can_cast()
	skill_one.disabled = not ready or game.get_live_units(UnitAgent.TEAM_ENEMY).is_empty()
	skill_two.disabled = not ready or not is_instance_valid(skills.get_charging_elite())
	skill_three.disabled = not ready or game.get_live_units(UnitAgent.TEAM_ALLY).is_empty()
	for button: Button in [skill_one, skill_two, skill_three]:
		button.modulate = Color("a3edff") if not button.disabled else Color("7d8a9d")
	pause_button.text = "继续" if get_tree().paused else "暂停"


func _on_pause_pressed() -> void:
	get_tree().paused = not get_tree().paused
	refresh()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

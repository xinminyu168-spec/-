# 南天门计划：Godot 4 竖屏双路白盒原型

这是独立的 **Godot 4 / GDScript** 项目，不是之前的 H5 版本。没有外部插件、收费资源或美术依赖。

**在线试玩： https://xinminyu168-spec.github.io/nantianmen-godot/**

**源码仓库： https://github.com/xinminyu168-spec/nantianmen-godot**

GitHub Actions 会自动测试、导出 Godot Web 并发布。部署说明见 `docs/GitHub云端部署.md`。

## 先运行

1. 使用 Godot **4.6.x 标准版**（不需要 .NET 版）。本项目在 **Godot 4.6.3** 验证。
2. 在项目管理器点「导入」，选择本目录的 `project.godot`。
3. 进入编辑器，按 **F6** 运行打开的场景，或按 **F5** 运行整个项目。主场景是 `scenes/main.tscn`。
4. 完整逐步搭建教程位于 **`docs/零基础搭建教程.md`**。

## 本阶段规则

| 项目 | 默认值 |
| --- | --- |
| 逻辑分辨率 | 540 × 960，竖屏，保持比例 |
| 己方工程舱 | 左右各一座，各自每 4 秒生成 1 台蓝色机甲 |
| 普通单位 | 100 血、每秒普攻一次、每次 10 伤害 |
| 移动方向 | 蓝方向上，红方向下；单位只攻击自己所在路线的敌人 |
| 精英 | 400 血；从生成起第 8 秒开始蓄力，蓄力 3 秒；范围 145 内造成 60 伤害 |
| 精英大招周期 | 蓄力开始时刻相隔 8 秒：第 8 秒开始、第 11 秒释放、第 16 秒再次开始 |
| 普攻能量 | 己方每次普攻 +2；敌方攻击不给玩家能量 |
| 击杀能量 | 每击杀一个敌人 +20；所有能量最高 100 |
| 鸾鸟 | 消耗 100，对两路所有存活敌人造成 120 伤害；每个击杀 **额外 +5**，即合计 +25 |
| 玄女 | 消耗 100，只锁定正在蓄力的敌方精英；300 伤害，存活目标取消蓄力并眩晕 2 秒；没有目标不扣能量 |
| 承影 | 消耗 100，为释放瞬间所有存活己方机甲施加 150 护盾，持续 5 秒 |
| 波次 | 第 1 波每路 2 台普通敌人；从第 2 波起每路最后一台为精英；每波每路 +1，最多每路 6 台 |
| 换波 | 当前波敌人全部死亡后，等待 2 秒；继承己方存活机甲、实际血量、剩余护盾时间、产兵进度、能量 |

三个技能 **绝不自动释放**。达到 100 能量后，只有存在合法目标的按钮才会点亮。多个精英同时蓄力时，玄女优先选择距离释放最近的一个。

护盾先承受伤害，超出的部分再扣血；重放刷新、不叠加，新产出的机甲不追补旧护盾。眩晕会彻底取消那次大招，不会等到解除眩晕后突然补放。所有计时跟随游戏时间，点击暂停时一起冻结。

注意：本次按照完整新需求中「击杀 +20，轰炸**额外** +5」计算，因此与之前 H5 中「轰炸只返 5」的原型不同。

## 文件职责

| 文件 | 挂载位置 / 职责 |
| --- | --- |
| `scripts/battle_game.gd` | 主场景根节点 `Game`，协调战斗、能量、伤害和单位生成 |
| `scripts/unit_agent.gd` | `unit.tscn` 根节点 `Unit`，移动、自动攻击、精英蓄力、眩晕、护盾与白盒绘制 |
| `scripts/engineering_bay.gd` | `engineering_bay.tscn` 根节点，工程舱产兵与绘制 |
| `scripts/wave_manager.gd` | 主场景 `WaveManager`，按波刷怪与清波检测 |
| `scripts/skill_manager.gd` | 主场景 `SkillManager`，三个独立技能函数 |
| `scripts/battle_hud.gd` | `UI/HUD`，按钮绑定与信息显示 |
| `scripts/battlefield.gd` | `Battlefield`，纯色路线、分界线与背景 |

**不需要 Autoload。** 场景节点名称和层级必须保持与教程一致。技能信号已通过代码连接，不要在编辑器里重复连接。

## 调整参数

- 选择 `EngineeringBays/LeftBay` 或 `RightBay`：Inspector 中修改 `Spawn Interval`，默认 4。
- 选择 `WaveManager`：修改 `Inter Wave Delay`、`Initial Enemies Per Lane`、`Elite From Wave` 等。
- 选择 `SkillManager`：修改三个技能的伤害、返能、护盾数值和持续时间。
- 打开 `scenes/unit.tscn`：选择 `Unit`，可修改 `Move Speed`、`Attack Range`、`Attack Damage`、`Elite Charge Interval` 等导出字段。
- 普通与精英血量、精英移动速度，目前在 `unit_agent.gd` 的 `configure()` 里设置。

## 当前边界

这是用于确认机制的第一阶段，不含美术资源、寻路避让、建筑受击、基地胜负、存档、网络对战或安装包。单位允许重叠。己方到达上方备战线、敌方到达下方备战线后会留在场内等待战斗，因此存活单位不会走出画面。左右路线固定，技能可以作用于两路。

手机适配采用固定逻辑画布并保持比例；不同长宽比设备可能出现留边。项目支持触摸模拟鼠标点击和单线程 Web 导出，但尚未在真实手机上验证或导出 APK。

## 自动检查

在终端进入此目录：

```sh
godot --headless --editor --import --quit
godot --headless --path . --script res://tests/run_tests.gd
```

测试会加载真实场景和脚本，验证技能按钮绑定、双路产兵、单位战斗、精英 8 秒 / 3 秒计时、打断、护盾、继承状态、长时间战斗及实际 Timer 和暂停。包含约 4 秒的真实计时等待。

## 后续替换美术

本阶段只使用纯色方块、线条、血条和红圈。后续可在 `unit.tscn` 和工程舱场景里增加 `Sprite2D`，保留逻辑脚本，再逐项关闭白盒绘制。

生成参考图时可以沿用统一透视：`top-down 45 degree view, clash royale style, sci-fi mech or carrier base, isolated on white background`。正式使用时再去除白底、统一透明边界与单位尺寸；对称无人机或悬浮单位可复用贴图旋转 180°。红色蓄力圈独立绘制，替换角色贴图后仍可保留。

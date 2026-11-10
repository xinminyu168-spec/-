# 南天门计划：Godot 4 横屏三基地白盒

**在线试玩：https://xinminyu168-spec.github.io/-/**

**源码：https://github.com/xinminyu168-spec/-**

1920×1080，16:9 横屏。左侧三个工程基地各自每4秒产兵向右推进，右侧共三波敌军向左推进。顶部显示波次、全局90秒倒计时和金币/宝箱。底部是圆形母舰按钮和三个六边形基地头像，配独立绿色血量条、黄色能量条与满能量金色边框。

## 打开工程

使用 Godot 4.6.x 标准版导入 project.godot，按 F5。完整逐步节点搭建、坐标表和脚本说明：**[横屏白盒搭建教程](docs/横屏白盒搭建教程.md)**。

## 主要规则

- 小兵普攻给出生基地+2能量；击杀+20；大招击杀额外+5。每座基地独立，上限100。
- 满能量只高亮；默认手动点击释放。托管默认关闭，开启后才尝试自动释放合法的基地技能。
- 1号全屏120伤害，2号对蓄力精英300伤害并打断眩晕2秒，3号对当前己方小兵施加150护盾持续5秒；每次花费对应基地100能量。
- 母舰原型默认全屏60伤害、20秒独立冷却、不耗基地能量、不返能、始终手动。
- 普通单位100血，精英400血。精英每8秒开始3秒蓄力，未打断则范围伤害60。
- 清波2秒后进入下一波，完整保留基地血量、能量、存活小兵和生产进度。第三波清空胜利；时间耗尽或三基地全毁失败。
- 伤害跳字显示真实HP扣除值；金币每杀+10，宝箱通关+1，重开归零。

## 脚本与节点

| 脚本 | 挂载节点 |
| --- | --- |
| battle_game.gd | Game，战斗与归属结算、倒计时、跳字 |
| unit_agent.gd | unit.tscn根节点，左右移动、攻击与状态 |
| engineering_bay.gd | engineering_bay.tscn根节点，血量、能量、产兵 |
| wave_manager.gd | WaveManager，固定三波 |
| skill_manager.gd | SkillManager，三个独立技能函数 |
| battle_hud.gd | UI/HUD，界面与按钮连接 |
| portrait_button.gd | 四个底部Button，几何外框与高亮 |
| battlefield.gd | Battlefield，白盒场地 |

不使用 Autoload。节点英文名称必须与场景一致。已有代码已连接按钮和Timer信号，不要重复连接。

## 验证与云端部署

```sh
godot --headless --editor --import --quit
godot --headless --path . --script res://tests/run_tests.gd
```

推送 main 后由 GitHub Actions 运行检查、真实Godot Web导出，再发布GitHub Pages。Web单线程，不需要跨源隔离头。包含开源中文字体子集，许可见 assets/fonts/OFL-Noto-CJK.txt。

这是第一版白盒，不包含原作角色、美术素材、网络对战、存档、商业经济系统或寻路避让。未完成手机真机与浏览器视觉验收。其他比例屏幕会留边，单位允许重叠。

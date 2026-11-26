# 🌾 《田间风云》（Field Chronicles）

卡牌驱动 × 种田经营的轻量策略小游戏。借鉴 itch.io 独立游戏 **[Cardwork Cycle](https://honey-pony.itch.io/cardwork-cycle)** 的核心玩法，把重心放在"体验真实种地的艰辛"：虫害、旱情、体力极限与岁赋压力。

- 单局 = 二十四候一年：四季各 6 候（春耕 / 夏耘 / 秋收 / 冬藏），大寒结束完税
- 五档官品：九品·丰年祥和 → 一品·神农绝境（岁赋 18 / 24 / 24 / 24 / 32 两；虫潮强度、虫王与旱期按品级差异）
- 田垄种植 + 害虫侵袭：用攻击 / 防御 / 水系卡牌护苗，每候体力 3 点、摸 5 张牌
- 收获二选一：挑粮入市换存银，或选优留种收卡牌
- 种成【百年月华·金稻】即触发传奇胜利

---

## 仓库结构

| 路径 | 说明 |
| :--- | :--- |
| [`GameIame/`](GameIame/) | Godot 3.5.3 游戏工程（GDScript，主场景 `MainMenu.tscn`，分辨率 1080×800） |
| [`demo.html`](demo.html) | 独立 HTML5 可玩原型，规则与工程对齐：24 候、5 官品、虫害护苗、收获二选一 |
| [`game-design-document.md`](game-design-document.md) | v2.2 策划文档（早期设计：16 回合、三档难度），部分数值已被工程迭代覆盖，实际以 `GameIame/` 为准 |
| [`simulate_game.py`](simulate_game.py) | 早期三难度、16 回合的平衡模拟脚本，用于验证旧经济模型，尚未跟随工程迭代 |
| [`_tools/`](_tools/) | Python 工具脚本：资源生成（贴图/音效）、场景批量修改、数值扫描 |
| `Bin/` | 本地导出的 Windows 包与 `.pck`（构建产物，未纳入版本库） |

`GameIame/` 内部按领域分目录：`cards` 卡牌、`farm` 田地、`plants` 作物、`bugs` 虫害、`seasons` 季节表现、`energy` 体力、`shop` 商店、`ui` 界面、`tutorial` 引导、`sfx`/`music` 音频，`_devtest` 为自动测试场景。

## 运行方式

**1. 运行 Godot 游戏**

用 [Godot 3.5.3](https://godotengine.org/download/3.x/) 打开 `GameIame/project.godot`；Windows 下也可直接双击 `GameIame/运行游戏.bat`（脚本内写有本机引擎路径，换机器需自行修改）。

**2. 玩 HTML 原型**

双击 [`demo.html`](demo.html)，用 Chrome / Edge 等浏览器打开即可。

**3. 跑平衡模拟**

```bash
python simulate_game.py
```

## 技术信息

| 项目 | 内容 |
| :--- | :--- |
| 引擎 | Godot 3.5.3（GLES2） |
| 语言 | GDScript |
| 导出 | HTML5 / Windows Desktop（见 `GameIame/export_presets.cfg`） |
| 架构 | 事件/状态脚本以 Autoload 常驻：`SeasonManager`、`DifficultyManager`、`GS`、`CardCreation`、`TutorialSteps`、`Flags` 等 |

仓库忽略项（见 [`.gitignore`](.gitignore)）：`Bin/` 导出产物、`GameIame/.import/` 缓存、`*.aup3` 音频工程源文件、`_archive/`、`_shots/`、Python 缓存与日志。

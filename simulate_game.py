"""
田间风云 - 三难度模拟测试
模拟 16 回合（春6+夏6+秋4）的完整对局，验证经济系统是否可行
"""
import random

def simulate_game(difficulty, seed_val=None):
    if seed_val is not None:
        random.seed(seed_val)
    
    # 难度参数
    configs = {
        "悠闲": {"stamina": 4, "gold": 10, "fields": 8, "hand_size": 6, "tax": 10,
                 "disaster_rate": 0.1, "price_crash_prob": 0.2, "rot_grace": 3},
        "普通": {"stamina": 3, "gold": 5, "fields": 6, "hand_size": 5, "tax": 15,
                 "disaster_rate": 0.25, "price_crash_prob": 0.5, "rot_grace": 2},
        "困难": {"stamina": 2, "gold": 0, "fields": 4, "hand_size": 4, "tax": 20,
                 "disaster_rate": 0.4, "price_crash_prob": 0.8, "rot_grace": 1},
    }
    cfg = configs[difficulty]
    
    # 游戏状态
    gold = cfg["gold"]
    water_pool = 3  # 初始水池
    max_fields = cfg["fields"]
    tax = cfg["tax"]
    
    # 牌组 (简化为类型计数)
    deck = ["播种"]*3 + ["浇水"]*5 + ["施肥"]*2 + ["除草"]*2 + ["收获"]*2
    discard = []
    
    # 田地: list of {crop, growth, max_growth, sell_price, water, status, mature_turns}
    fields = [None] * max_fields
    
    # 作物定义
    crops = {
        "白菜": {"max_growth": 2, "sell_price": 3, "water_need": 1},
        "水稻": {"max_growth": 3, "sell_price": 5, "water_need": 2},
        "玉米": {"max_growth": 3, "sell_price": 6, "water_need": 1},
    }
    
    # 天气牌堆
    spring_weather = ["晴天"]*3 + ["多云"]*2 + ["小雨"]*2 + ["大风"]*1
    summer_weather = ["晴天"]*3 + ["暴雨"]*1 + ["干旱"]*1 + ["多云"]*1
    autumn_weather = ["晴天"]*2 + ["小雨"]*1 + ["大风"]*1
    
    seasons = [
        ("🌸春", 6, list(spring_weather)),
        ("☀️夏", 6, list(summer_weather)),
        ("🍂秋", 4, list(autumn_weather)),
    ]
    
    log = []
    total_harvested = 0
    total_earned = 0
    price_crashed = False
    
    def draw_hand():
        nonlocal deck, discard
        hand = []
        for _ in range(cfg["hand_size"]):
            if not deck:
                deck = list(discard)
                random.shuffle(deck)
                discard.clear()
            if deck:
                hand.append(deck.pop())
        return hand
    
    turn_num = 0
    for season_name, num_turns, weather_deck in seasons:
        random.shuffle(weather_deck)
        
        for t in range(num_turns):
            turn_num += 1
            stamina = cfg["stamina"]
            hand = draw_hand()
            actions = []
            
            # === 玩家行动阶段（简单AI策略）===
            # 优先级：除虫/除草 > 收获成熟 > 浇水缺水 > 播种空地 > 施肥
            
            # 1. 收获成熟作物
            while stamina > 0 and "收获" in hand:
                mature_idx = None
                for i, f in enumerate(fields):
                    if f and f["growth"] >= f["max_growth"]:
                        mature_idx = i
                        break
                if mature_idx is not None:
                    hand.remove("收获")
                    stamina -= 1
                    crop = fields[mature_idx]
                    sell = crop["sell_price"]
                    if crop.get("quality", 0) > 0:
                        sell += crop["quality"] * 2
                    gold += sell
                    total_earned += sell
                    total_harvested += 1
                    actions.append(f"收获{crop['name']}(+{sell}🪙)")
                    fields[mature_idx] = None
                else:
                    break
            
            # 2. 除草
            while stamina > 0 and "除草" in hand:
                weed_idx = None
                for i, f in enumerate(fields):
                    if f and f.get("status") == "杂草":
                        weed_idx = i
                        break
                if weed_idx is not None:
                    hand.remove("除草")
                    stamina -= 1
                    fields[weed_idx]["status"] = None
                    actions.append("除草")
                else:
                    break
            
            # 3. 浇水（优先缺水的作物）
            while stamina > 0 and "浇水" in hand:
                thirsty_idx = None
                for i, f in enumerate(fields):
                    if f and f["water"] < f["water_need"] and f["growth"] < f["max_growth"]:
                        thirsty_idx = i
                        break
                if thirsty_idx is not None:
                    hand.remove("浇水")
                    stamina -= 1
                    fields[thirsty_idx]["water"] += 2
                    water_pool = max(0, water_pool)
                    actions.append(f"浇水田{thirsty_idx+1}")
                else:
                    break
            
            # 4. 播种空地
            while stamina > 0 and "播种" in hand:
                empty_idx = None
                for i, f in enumerate(fields):
                    if f is None:
                        empty_idx = i
                        break
                if empty_idx is not None:
                    hand.remove("播种")
                    stamina -= 1
                    # 选作物：春种白菜，夏种玉米，秋紧急种白菜
                    if "春" in season_name:
                        c = random.choice(["白菜", "水稻"])
                    elif "夏" in season_name:
                        c = random.choice(["玉米", "水稻"])
                    else:
                        c = "白菜"  # 秋季种快熟的
                    crop_def = crops[c]
                    fields[empty_idx] = {
                        "name": c,
                        "growth": 0,
                        "max_growth": crop_def["max_growth"],
                        "sell_price": crop_def["sell_price"],
                        "water_need": crop_def["water_need"],
                        "water": 0,
                        "status": None,
                        "quality": 0,
                        "mature_turns": 0,
                    }
                    actions.append(f"播种{c}(田{empty_idx+1})")
                else:
                    break
            
            # 5. 施肥
            while stamina > 0 and "施肥" in hand:
                fert_idx = None
                for i, f in enumerate(fields):
                    if f and f["growth"] < f["max_growth"] and f.get("quality", 0) < 2:
                        fert_idx = i
                        break
                if fert_idx is not None:
                    hand.remove("施肥")
                    stamina -= 1
                    fields[fert_idx]["quality"] = fields[fert_idx].get("quality", 0) + 1
                    actions.append(f"施肥田{fert_idx+1}")
                else:
                    break
            
            # 弃牌
            discard.extend(hand)
            
            # === 天气翻牌 ===
            weather = weather_deck.pop() if weather_deck else "多云"
            weather_effect = ""
            
            if weather == "晴天":
                weather_effect = "所有作物+1生长"
            elif weather == "小雨":
                water_pool += 1
                weather_effect = "水池+1"
                for f in fields:
                    if f:
                        f["water"] += 1
            elif weather == "暴雨":
                water_pool += 3
                weather_effect = "水池+3"
                for f in fields:
                    if f:
                        f["water"] += 2
                # 涝灾风险
                if random.random() < 0.3:
                    for i, f in enumerate(fields):
                        if f and random.random() < 0.3:
                            fields[i] = None
                            weather_effect += f" 涝灾！田{i+1}被淹"
                            break
            elif weather == "大风":
                victim = [i for i, f in enumerate(fields) if f and f["name"] != "玉米"]
                if victim:
                    idx = random.choice(victim)
                    fields[idx]["growth"] = max(0, fields[idx]["growth"] - 1)
                    weather_effect = f"田{idx+1}受损"
            elif weather == "干旱":
                water_pool = max(0, water_pool - 2)
                for f in fields:
                    if f:
                        f["water"] = max(0, f["water"] - 1)
                weather_effect = "全体水位-1！"
            elif weather == "多云":
                weather_effect = "无事发生"
            
            # === 障碍事件 ===
            disaster_msg = ""
            if random.random() < cfg["disaster_rate"]:
                disaster_type = random.choice(["蚜虫", "杂草", "野猪", "腰酸背痛"])
                if disaster_type == "蚜虫":
                    planted = [i for i, f in enumerate(fields) if f and f.get("status") != "虫害"]
                    if planted:
                        idx = random.choice(planted)
                        fields[idx]["status"] = "虫害"
                        fields[idx]["growth"] = max(0, fields[idx]["growth"] - 1)
                        disaster_msg = f"🐛蚜虫入侵田{idx+1}！"
                elif disaster_type == "杂草":
                    planted = [i for i, f in enumerate(fields) if f and f.get("status") is None]
                    if planted:
                        idx = random.choice(planted)
                        fields[idx]["status"] = "杂草"
                        disaster_msg = f"🌿杂草丛生田{idx+1}！"
                elif disaster_type == "野猪" and "秋" in season_name:
                    mature = [i for i, f in enumerate(fields) if f and f["growth"] >= f["max_growth"]]
                    if mature:
                        idx = random.choice(mature)
                        disaster_msg = f"🐗野猪毁掉了田{idx+1}的{fields[idx]['name']}！"
                        fields[idx] = None
                elif disaster_type == "腰酸背痛":
                    disaster_msg = "💪腰酸背痛，本回合少干了活"
            
            # === 生长结算 ===
            for f in fields:
                if f and f.get("status") != "杂草":
                    if f["water"] >= f["water_need"]:
                        f["growth"] += 1
                        f["water"] -= f["water_need"]
                    else:
                        # 缺水伤害
                        f["growth"] = max(0, f["growth"] - 0)  # 不倒退，但不生长
                    
                    # 成熟后腐烂计时
                    if f["growth"] >= f["max_growth"]:
                        f["mature_turns"] = f.get("mature_turns", 0) + 1
            
            # 腐烂检查
            for i, f in enumerate(fields):
                if f and f.get("mature_turns", 0) > cfg["rot_grace"]:
                    disaster_msg += f" 🥀田{i+1}{f['name']}腐烂了！"
                    fields[i] = None
            
            # 记录日志
            field_summary = []
            for i, f in enumerate(fields):
                if f:
                    status = ""
                    if f.get("status"):
                        status = f"({f['status']})"
                    if f["growth"] >= f["max_growth"]:
                        status += "✅熟"
                    field_summary.append(f"田{i+1}:{f['name']}{f['growth']}/{f['max_growth']}{status}")
            
            log.append({
                "turn": turn_num,
                "season": season_name,
                "stamina_used": cfg["stamina"] - stamina,
                "actions": " | ".join(actions) if actions else "无行动",
                "weather": f"{weather}→{weather_effect}",
                "disaster": disaster_msg,
                "gold": gold,
                "fields": " ".join(field_summary) if field_summary else "空",
            })
    
    # === 秋收结算 ===
    # 收获所有还没收的成熟作物
    for i, f in enumerate(fields):
        if f and f["growth"] >= f["max_growth"]:
            sell = f["sell_price"] + f.get("quality", 0) * 2
            gold += sell
            total_earned += sell
            total_harvested += 1
    
    # 粮价暴跌检查
    if random.random() < cfg["price_crash_prob"]:
        crash_loss = int(total_earned * 0.3)
        gold -= crash_loss
        price_crashed = True
    
    # 判定结果
    if gold >= tax * 2:
        result = "⭐ 富裕胜利"
    elif gold >= tax:
        result = "✅ 基础胜利"
    else:
        result = "❌ 破产失败"
    
    return {
        "difficulty": difficulty,
        "result": result,
        "gold": gold,
        "tax": tax,
        "total_harvested": total_harvested,
        "total_earned": total_earned,
        "price_crashed": price_crashed,
        "log": log,
    }


def run_batch(difficulty, runs=200):
    """批量跑200局统计通关率"""
    results = {"⭐ 富裕胜利": 0, "✅ 基础胜利": 0, "❌ 破产失败": 0}
    golds = []
    for i in range(runs):
        r = simulate_game(difficulty, seed_val=i)
        results[r["result"]] += 1
        golds.append(r["gold"])
    return results, sum(golds)/len(golds), min(golds), max(golds)


# ========== 运行模拟 ==========
print("=" * 60)
print("《田间风云》经济系统模拟测试")
print("=" * 60)

# 1. 每个难度跑一局详细日志
for diff in ["悠闲", "普通", "困难"]:
    print(f"\n{'='*60}")
    print(f"📋 【{diff}模式】详细对局记录 (seed=42)")
    print(f"{'='*60}")
    
    r = simulate_game(diff, seed_val=42)
    
    for entry in r["log"]:
        print(f"\n--- {entry['season']} 第{entry['turn']}回合 ---")
        print(f"  行动: {entry['actions']}")
        print(f"  天气: {entry['weather']}")
        if entry['disaster']:
            print(f"  ⚠️ 障碍: {entry['disaster']}")
        print(f"  💰金币: {entry['gold']}  田地: {entry['fields']}")
    
    print(f"\n{'─'*40}")
    print(f"结算: 金币={r['gold']} / 税金={r['tax']} / 收获={r['total_harvested']}次 / 总收入={r['total_earned']}🪙")
    if r['price_crashed']:
        print(f"⚠️ 粮价暴跌！收入被扣减")
    print(f"🎯 结果: {r['result']}")

# 2. 批量统计
print(f"\n\n{'='*60}")
print("📊 200 局批量统计")
print(f"{'='*60}")

for diff in ["悠闲", "普通", "困难"]:
    results, avg_gold, min_gold, max_gold = run_batch(diff)
    total = sum(results.values())
    win_rate = (results["⭐ 富裕胜利"] + results["✅ 基础胜利"]) / total * 100
    
    print(f"\n【{diff}模式】200局统计:")
    print(f"  ⭐ 富裕胜利: {results['⭐ 富裕胜利']}局 ({results['⭐ 富裕胜利']/total*100:.0f}%)")
    print(f"  ✅ 基础胜利: {results['✅ 基础胜利']}局 ({results['✅ 基础胜利']/total*100:.0f}%)")
    print(f"  ❌ 破产失败: {results['❌ 破产失败']}局 ({results['❌ 破产失败']/total*100:.0f}%)")
    print(f"  📈 总通关率: {win_rate:.0f}%")
    print(f"  💰 平均金币: {avg_gold:.1f} | 最低: {min_gold} | 最高: {max_gold}")

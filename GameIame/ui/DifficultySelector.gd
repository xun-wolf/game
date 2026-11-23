extends Control

onready var prev_btn = $PrevButton
onready var next_btn = $NextButton
onready var tier_label = $TierLabel
onready var desc_label = $DescLabel
onready var status_label = $StatusLabel

func _ready():
	prev_btn.connect("pressed", self, "_on_prev_pressed")
	next_btn.connect("pressed", self, "_on_next_pressed")
	update_display()

func update_display():
	var cur = DifficultyManager.current_tier
	tier_label.text = DifficultyManager.get_tier_title(cur)
	desc_label.text = DifficultyManager.get_tier_desc(cur)
	
	if DifficultyManager.is_tier_cleared(cur):
		status_label.text = "【已通关 · 榜上有名】"
		status_label.add_color_override("font_color", Color(1.0, 0.85, 0.2))
	else:
		status_label.text = "【待攻坚 · 耕耘挑战】"
		status_label.add_color_override("font_color", Color(0.8, 0.85, 0.9))

func _on_prev_pressed():
	DifficultyManager.cycle_tier(-1)
	update_display()
	SFX.rand_card()

func _on_next_pressed():
	DifficultyManager.cycle_tier(1)
	update_display()
	SFX.rand_card()

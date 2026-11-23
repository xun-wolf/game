extends Panel

var timer = 0.0
var target_alpha = 0.0

func _ready():
	modulate.a = 0.0
	visible = false

func display_banner(msg: String):
	$Label.text = msg
	# 教程卷轴占据顶部居中区域，此时把横幅挪到卷轴下方；
	# 但如果正开着选卡/结算弹窗，就回到顶部，免得压在弹窗文字上。
	var top = 20.0
	if GS.tutorial and not GS.waiting_for_card_selection:
		top = 236.0
	margin_top = top
	margin_bottom = top + 66.0
	visible = true
	timer = 3.8
	target_alpha = 1.0

func hide_now():
	timer = 0.0
	target_alpha = 0.0
	modulate.a = 0.0
	visible = false

func _process(delta):
	if timer > 0.0:
		timer -= delta
		if timer <= 0.0:
			target_alpha = 0.0
	
	modulate.a = lerp(modulate.a, target_alpha, clamp(6.0 * delta, 0.0, 1.0))
	if modulate.a < 0.01 and target_alpha == 0.0:
		visible = false

func _gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		timer = 0.0
		target_alpha = 0.0

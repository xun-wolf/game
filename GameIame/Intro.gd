extends Control

# 开场卷轴：逐字书写 + 墨迹显影。
# 点击一次补全当前段，已补全时再点击推进到下一段。
const CHARS_PER_SEC = 26.0
const PUNCT_STOP = 0.10
const PUNCTUATION = ["，", "。", "：", "；", "！", "？", "、", "…", "”"]

const INK_REVEAL_TIME = 1.15

var active_label = null
var shown = 0.0
var pause_left = 0.0

func _on_Button_pressed():
	SceneTransitions.change_scene_to(GS.Game)

func _ready():
	if Flags.skip_tutorial:
		$L4.text = "环顾你的新农场，你发现一块模样古怪的石头。石头下面藏着一卷落满灰尘的卷轴，还有一副落灰更厚的卡组。"
	for label in [$L1, $L2, $L3, $L4]:
		label.visible_characters = 0
	$AnimationPlayer.connect("animation_started", self, "_on_animation_started")
	_play_ink_reveal()
	# 自动播放的 Start 可能在 _ready 之前就已经开始，这里补一次初始化
	if $AnimationPlayer.current_animation != "":
		_on_animation_started($AnimationPlayer.current_animation)

func _play_ink_reveal():
	var mat = $InkOverlay.material
	if mat == null or not (mat is ShaderMaterial):
		$InkOverlay.visible = false
		return
	$InkOverlay.visible = true
	mat.set_shader_param("progress", 1.0)
	$Tween.interpolate_method(self, "_set_ink", 1.0, 0.0, INK_REVEAL_TIME,
		Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.interpolate_callback(self, INK_REVEAL_TIME + 0.05, "_hide_ink")
	$Tween.start()

func _set_ink(value):
	$InkOverlay.material.set_shader_param("progress", value)

func _hide_ink():
	$InkOverlay.visible = false

func _on_animation_started(name):
	var map = {"Start": $L1, "Second": $L2, "Third": $L3, "Fourth": $L4}
	active_label = map.get(name, null)
	shown = 0.0
	pause_left = 0.0
	if active_label != null:
		active_label.visible_characters = 0

func _process(delta):
	_tick_typewriter(delta)
	if Input.is_action_just_pressed("mouse"):
		if _is_text_complete():
			var anim = $AnimationPlayer
			anim.seek(anim.current_animation_length)
		else:
			_complete_text()

func _tick_typewriter(delta):
	if active_label == null:
		return
	var total = active_label.text.length()
	if int(shown) >= total:
		return
	if pause_left > 0.0:
		pause_left -= delta
		return
	shown = min(shown + CHARS_PER_SEC * delta, float(total))
	var idx = int(shown)
	active_label.visible_characters = idx
	if idx > 0:
		var ch = active_label.text.substr(idx - 1, 1)
		if PUNCTUATION.has(ch):
			pause_left = PUNCT_STOP

func _is_text_complete():
	if active_label == null:
		return true
	return int(shown) >= active_label.text.length()

func _complete_text():
	if active_label == null:
		return
	shown = active_label.text.length()
	active_label.visible_characters = -1

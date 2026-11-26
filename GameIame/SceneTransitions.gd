extends CanvasLayer

const INK_IN = 0.30
const INK_OUT = 0.34

var next = null

onready var overlay = $ColorRect
onready var tween = $Tween

func change_scene_to(scene: PackedScene):
	next = scene
	if _has_ink_shader():
		_ink_transition()
	else:
		# 兜底：Shader 不可用时沿用原来的黑场淡入淡出
		$AnimationPlayer.stop()
		$AnimationPlayer.play("FadeOutIn")

func _has_ink_shader() -> bool:
	if overlay.material == null:
		return false
	return overlay.material is ShaderMaterial

func _ink_transition():
	overlay.visible = true
	overlay.material.set_shader_param("progress", 0.0)
	tween.stop_all()
	tween.interpolate_method(self, "_set_ink", 0.0, 1.0, INK_IN,
		Tween.TRANS_SINE, Tween.EASE_IN)
	tween.interpolate_callback(self, INK_IN, "faded")
	tween.interpolate_method(self, "_set_ink", 1.0, 0.0, INK_OUT,
		Tween.TRANS_SINE, Tween.EASE_OUT, INK_IN + 0.04)
	tween.interpolate_callback(self, INK_IN + INK_OUT + 0.06, "_finish_ink")
	tween.start()

func _set_ink(value: float):
	if overlay.material != null:
		overlay.material.set_shader_param("progress", value)

func _finish_ink():
	overlay.visible = false

func faded():
	if next == null:
		return
	get_tree().change_scene_to(next)

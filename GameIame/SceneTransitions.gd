extends CanvasLayer

var next = null

func change_scene_to(scene: PackedScene):
	next = scene
	# 连续切换时先 stop，否则动画可能停在上次结束帧，faded() 不会被再次调用
	$AnimationPlayer.stop()
	$AnimationPlayer.play("FadeOutIn")

func faded():
	if next == null:
		return
	get_tree().change_scene_to(next)

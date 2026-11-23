extends Control

func _on_Button_pressed():
	SceneTransitions.change_scene_to(GS.Game)
	
func _ready():
	if Flags.skip_tutorial:
		$L4.text = "环顾你的新农场，你发现一块模样古怪的石头。石头下面藏着一卷落满灰尘的卷轴，还有一副落灰更厚的卡组。"
	
func _process(delta):
	if Input.is_action_just_pressed("mouse"):
		var anim = $AnimationPlayer
		anim.seek(anim.current_animation_length)

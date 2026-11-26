extends CheckBox

export var item = 1

func _ready():
	if item == 1:
		pressed = Flags.skip_tutorial
	if item == 2:
		pressed = Flags.hard_mode
	if item == 3:
		pressed = Flags.quick_intro_on_revisit

func _process(delta):
	if item == 1:
		Flags.skip_tutorial = pressed
	if item == 2:
		Flags.hard_mode = pressed
	if item == 3 and Flags.quick_intro_on_revisit != pressed:
		Flags.quick_intro_on_revisit = pressed
		Flags.save_settings()

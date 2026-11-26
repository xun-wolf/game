extends Node

var skip_tutorial = false
var hard_mode = false
# 回访时是否播放 2.4 秒极简开场（菜单开关，默认关闭）
var quick_intro_on_revisit = false

const SETTINGS_PATH = "user://settings.json"

func _ready():
	_load_settings()

func save_settings():
	var f = File.new()
	if f.open(SETTINGS_PATH, File.WRITE) == OK:
		f.store_string(to_json({"quick_intro_on_revisit": quick_intro_on_revisit}))
		f.close()

func _load_settings():
	var f = File.new()
	if not f.file_exists(SETTINGS_PATH):
		return
	if f.open(SETTINGS_PATH, File.READ) != OK:
		return
	var data = parse_json(f.get_as_text())
	f.close()
	if typeof(data) == TYPE_DICTIONARY:
		quick_intro_on_revisit = bool(data.get("quick_intro_on_revisit", false))

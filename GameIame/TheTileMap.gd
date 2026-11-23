extends TileMap


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	GS.tilemap = self
	setup_farmland_tiles()
	convert_plant_spots()
	var decor = get_node_or_null("Decor")
	var modulate = get_node_or_null("../WorldModulate")
	var banner = get_node_or_null("../CanvasLayer/SeasonBanner")
	SeasonManager.bind_game_elements(self, decor, modulate, banner)

	# 开局补偿（一品·神农绝境）：乡邻接济的存银，用横幅讲明白。
	# 必须延后一帧：本节点 _ready 早于 SeasonBanner._ready，直接弹会被它的隐藏逻辑抹掉。
	call_deferred("_show_start_bonus_banner")

func _show_start_bonus_banner():
	var start_gold = DifficultyManager.get_start_gold()
	if start_gold <= 0:
		return
	# 跳过教程时会立刻播一条「立春」季节横幅，先等它播完（3.8s）再弹这条，
	# 否则会被覆盖掉。
	yield(get_tree().create_timer(4.2), "timeout")
	SeasonManager.show_banner("【乡邻接济】乡亲送来 " + str(start_gold) + " 两存银，撑过这大旱之年！")

# The four seamless farmland tiles are guaranteed to exist at runtime even if
# the scene file was saved with the old tileset, so the farm plot always uses
# the tilled-soil art instead of the rounded placeholder patches.
func setup_farmland_tiles():
	var ids = tile_set.get_tiles_ids()
	for i in range(4):
		var id = 7 + i
		if id in ids:
			continue
		tile_set.create_tile(id)
		tile_set.tile_set_texture(id, load("res://farm/farmland_%d.png" % (i + 1)))
		tile_set.tile_set_region(id, Rect2(0, 0, 128, 128))
		tile_set.tile_set_tile_mode(id, TileSet.TILE_MODE_SINGLE)
		tile_set.tile_set_texture_offset(id, Vector2.ZERO)

# Legacy plantable cells used tile id 3; swap them for the seamless soil.
func convert_plant_spots():
	for cell in get_used_cells():
		if get_cellv(cell) == 3:
			set_cellv(cell, farmland_variant(cell))

func up1():
	for t in $Up1.get_used_cells():
		set_cellv(t, farmland_variant(t))

func up2():
	for t in $Up2.get_used_cells():
		set_cellv(t, farmland_variant(t))

# Pick one of the four seamless farmland tiles (7-10) deterministically so the
# plot keeps its variation after unlocking.
func farmland_variant(cell):
	return 7 + posmod(cell.x * 7 + cell.y * 13, 4)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

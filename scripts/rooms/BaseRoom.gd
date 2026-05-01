extends Node2D
class_name BaseRoom

const ROOM_W    := 1280
const ROOM_H    := 720
const BORDER    := 64
const DOOR_W    := 128

var room_def: RoomDef = null
var _door_delay  := 1.2
var _doors_live  := false
var _door_triggers: Dictionary = {}   # dir -> Area2D
var _door_blockers: Dictionary = {}   # dir -> StaticBody2D

func _ready() -> void:
	room_def = RunManager.get_current_room_def()
	if room_def == null:
		return
	_build_room()
	_spawn_player()
	_on_room_ready()

func _build_room() -> void:
	var active_dirs := room_def.connections.keys()
	_build_floor_visual()
	_build_walls(active_dirs)
	_build_navigation(active_dirs)

func _build_floor_visual() -> void:
	var floor_poly := Polygon2D.new()
	floor_poly.polygon = PackedVector2Array([
		Vector2(BORDER, BORDER),
		Vector2(ROOM_W - BORDER, BORDER),
		Vector2(ROOM_W - BORDER, ROOM_H - BORDER),
		Vector2(BORDER, ROOM_H - BORDER),
	])
	floor_poly.color = Color(0.06, 0.06, 0.10)
	add_child(floor_poly)

func _build_walls(active_dirs: Array) -> void:
	var cx := ROOM_W / 2.0
	var cy := ROOM_H / 2.0
	var hw := DOOR_W / 2.0
	var B  := float(BORDER)

	# NORTH
	if RoomDef.NORTH in active_dirs:
		_add_wall(Vector2((cx - hw) / 2.0, B / 2.0), Vector2(cx - hw, B))
		_add_wall(Vector2(cx + hw + (ROOM_W - cx - hw) / 2.0, B / 2.0), Vector2(ROOM_W - cx - hw, B))
	else:
		_add_wall(Vector2(cx, B / 2.0), Vector2(ROOM_W, B))

	# SOUTH
	if RoomDef.SOUTH in active_dirs:
		_add_wall(Vector2((cx - hw) / 2.0, ROOM_H - B / 2.0), Vector2(cx - hw, B))
		_add_wall(Vector2(cx + hw + (ROOM_W - cx - hw) / 2.0, ROOM_H - B / 2.0), Vector2(ROOM_W - cx - hw, B))
	else:
		_add_wall(Vector2(cx, ROOM_H - B / 2.0), Vector2(ROOM_W, B))

	# WEST
	if RoomDef.WEST in active_dirs:
		_add_wall(Vector2(B / 2.0, (cy - hw) / 2.0), Vector2(B, cy - hw))
		_add_wall(Vector2(B / 2.0, cy + hw + (ROOM_H - cy - hw) / 2.0), Vector2(B, ROOM_H - cy - hw))
	else:
		_add_wall(Vector2(B / 2.0, cy), Vector2(B, ROOM_H))

	# EAST
	if RoomDef.EAST in active_dirs:
		_add_wall(Vector2(ROOM_W - B / 2.0, (cy - hw) / 2.0), Vector2(B, cy - hw))
		_add_wall(Vector2(ROOM_W - B / 2.0, cy + hw + (ROOM_H - cy - hw) / 2.0), Vector2(B, ROOM_H - cy - hw))
	else:
		_add_wall(Vector2(ROOM_W - B / 2.0, cy), Vector2(B, ROOM_H))

func _add_wall(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask  = 0
	body.position = pos

	var cs    := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape   = shape
	body.add_child(cs)

	var vis := Polygon2D.new()
	var hw2 := size.x * 0.5; var hh2 := size.y * 0.5
	vis.polygon = PackedVector2Array([
		Vector2(-hw2, -hh2), Vector2(hw2, -hh2),
		Vector2(hw2,  hh2),  Vector2(-hw2,  hh2),
	])
	vis.color = Color(0.13, 0.13, 0.20)
	body.add_child(vis)
	add_child(body)

func _build_navigation(active_dirs: Array) -> void:
	var region := NavigationRegion2D.new()
	var poly   := NavigationPolygon.new()
	poly.add_outline(PackedVector2Array([
		Vector2(BORDER + 2, BORDER + 2),
		Vector2(ROOM_W - BORDER - 2, BORDER + 2),
		Vector2(ROOM_W - BORDER - 2, ROOM_H - BORDER - 2),
		Vector2(BORDER + 2, ROOM_H - BORDER - 2),
	]))
	poly.make_polygons_from_outlines()
	region.navigation_polygon = poly
	add_child(region)

	# Patch a nav region for each door opening so pathfinding extends through the gap
	var cx   := ROOM_W / 2.0
	var cy   := ROOM_H / 2.0
	var hw   := DOOR_W / 2.0
	var outlines: Dictionary = {
		RoomDef.NORTH: PackedVector2Array([Vector2(cx-hw,0),     Vector2(cx+hw,0),     Vector2(cx+hw,BORDER),    Vector2(cx-hw,BORDER)]),
		RoomDef.SOUTH: PackedVector2Array([Vector2(cx-hw,ROOM_H-BORDER), Vector2(cx+hw,ROOM_H-BORDER), Vector2(cx+hw,ROOM_H), Vector2(cx-hw,ROOM_H)]),
		RoomDef.EAST:  PackedVector2Array([Vector2(ROOM_W-BORDER,cy-hw), Vector2(ROOM_W,cy-hw), Vector2(ROOM_W,cy+hw), Vector2(ROOM_W-BORDER,cy+hw)]),
		RoomDef.WEST:  PackedVector2Array([Vector2(0,cy-hw), Vector2(BORDER,cy-hw), Vector2(BORDER,cy+hw), Vector2(0,cy+hw)]),
	}
	for dir in active_dirs:
		var patch_region := NavigationRegion2D.new()
		var patch_poly   := NavigationPolygon.new()
		patch_poly.add_outline(outlines[dir])
		patch_poly.make_polygons_from_outlines()
		patch_region.navigation_polygon = patch_poly
		add_child(patch_region)

func _spawn_player() -> void:
	var player_scene := load("res://scenes/player/Player.tscn") as PackedScene
	var player := player_scene.instantiate()
	player.stats = RunManager.player_stats
	player.died.connect(RunManager.show_death_screen)
	player.position = _player_spawn_pos()
	add_child(player)

func _player_spawn_pos() -> Vector2:
	var pad := 48.0
	match RunManager.get_entry_direction():
		RoomDef.NORTH: return Vector2(ROOM_W / 2.0, ROOM_H - BORDER - pad)
		RoomDef.SOUTH: return Vector2(ROOM_W / 2.0, BORDER + pad)
		RoomDef.EAST:  return Vector2(BORDER + pad, ROOM_H / 2.0)
		RoomDef.WEST:  return Vector2(ROOM_W - BORDER - pad, ROOM_H / 2.0)
	return Vector2(200, ROOM_H / 2.0)

func _on_room_ready() -> void:
	pass  # subclasses override

func _process(delta: float) -> void:
	if not _doors_live:
		_door_delay -= delta
		if _door_delay <= 0.0:
			_doors_live = true
			_setup_door_triggers()

func _setup_door_triggers() -> void:
	var cx := ROOM_W / 2.0
	var cy := ROOM_H / 2.0
	var hw := DOOR_W / 2.0
	var trigger_data: Dictionary = {
		RoomDef.NORTH: [Vector2(cx, 4),          Vector2(DOOR_W, 8)],
		RoomDef.SOUTH: [Vector2(cx, ROOM_H - 4), Vector2(DOOR_W, 8)],
		RoomDef.EAST:  [Vector2(ROOM_W - 4, cy), Vector2(8, DOOR_W)],
		RoomDef.WEST:  [Vector2(4, cy),           Vector2(8, DOOR_W)],
	}
	for dir in room_def.connections.keys():
		if _door_blockers.has(dir):
			continue  # door still locked
		_create_door_trigger(dir, trigger_data[dir][0], trigger_data[dir][1])

func _create_door_trigger(dir: int, pos: Vector2, sz: Vector2) -> void:
	var area  := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 2  # player layer
	var cs    := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = sz
	cs.shape   = shape
	area.add_child(cs)
	area.position = pos
	area.body_entered.connect(func(body): _on_door_body(body, dir))
	add_child(area)
	_door_triggers[dir] = area

func _on_door_body(body: Node2D, dir: int) -> void:
	if not body.is_in_group("player"):
		return
	var target_id: int = room_def.connections.get(dir, -1)
	if target_id < 0:
		return
	RunManager.travel_to_room(target_id, _opposite(dir))

func _add_door_blocker(dir: int) -> void:
	var cx    := ROOM_W / 2.0
	var cy    := ROOM_H / 2.0
	var body  := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask  = 0
	var cs    := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	match dir:
		RoomDef.NORTH: body.position = Vector2(cx, BORDER - 2); shape.size = Vector2(DOOR_W, 4)
		RoomDef.SOUTH: body.position = Vector2(cx, ROOM_H - BORDER + 2); shape.size = Vector2(DOOR_W, 4)
		RoomDef.EAST:  body.position = Vector2(ROOM_W - BORDER + 2, cy); shape.size = Vector2(4, DOOR_W)
		RoomDef.WEST:  body.position = Vector2(BORDER - 2, cy); shape.size = Vector2(4, DOOR_W)
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	_door_blockers[dir] = body

func unlock_all_doors() -> void:
	for dir in _door_blockers.keys():
		_door_blockers[dir].queue_free()
	_door_blockers.clear()
	if _doors_live:
		for dir in room_def.connections.keys():
			if not _door_triggers.has(dir):
				var cx := ROOM_W / 2.0
				var cy := ROOM_H / 2.0
				var trigger_data: Dictionary = {
					RoomDef.NORTH: [Vector2(cx, 4),          Vector2(DOOR_W, 8)],
					RoomDef.SOUTH: [Vector2(cx, ROOM_H - 4), Vector2(DOOR_W, 8)],
					RoomDef.EAST:  [Vector2(ROOM_W - 4, cy), Vector2(8, DOOR_W)],
					RoomDef.WEST:  [Vector2(4, cy),           Vector2(8, DOOR_W)],
				}
				_create_door_trigger(dir, trigger_data[dir][0], trigger_data[dir][1])

func _opposite(dir: int) -> int:
	match dir:
		RoomDef.NORTH: return RoomDef.SOUTH
		RoomDef.SOUTH: return RoomDef.NORTH
		RoomDef.EAST:  return RoomDef.WEST
		RoomDef.WEST:  return RoomDef.EAST
	return RoomDef.NORTH

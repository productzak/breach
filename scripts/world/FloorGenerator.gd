class_name FloorGenerator

static func generate(floor_num: int) -> Dictionary:
	var rooms: Dictionary = {}

	var hub := RoomDef.new()
	hub.id = 0
	hub.type = RoomDef.Type.HUB
	hub.map_pos = Vector2i(2, 2)
	hub.floor_num = floor_num
	hub.cleared = true
	rooms[0] = hub

	var spoke_count := randi_range(3, 4)
	var all_dirs: Array[int] = [RoomDef.NORTH, RoomDef.EAST, RoomDef.SOUTH, RoomDef.WEST]
	all_dirs.shuffle()
	var active_dirs := all_dirs.slice(0, spoke_count)

	var spoke_types := _get_spoke_types(spoke_count, floor_num)

	for i in spoke_count:
		var dir: int = active_dirs[i]
		var opp := _opposite(dir)
		var spoke := RoomDef.new()
		spoke.id = i + 1
		spoke.type = spoke_types[i]
		spoke.map_pos = hub.map_pos + _dir_offset(dir)
		spoke.floor_num = floor_num
		spoke.connections[opp] = 0
		rooms[i + 1] = spoke
		hub.connections[dir] = i + 1

	return rooms

static func _get_spoke_types(count: int, floor_num: int) -> Array:
	var combat_count := clampi(floor_num, 1, count - 1)
	var pool: Array = []
	for _i in combat_count:
		pool.append(RoomDef.Type.COMBAT)
	var fillers: Array = [RoomDef.Type.HACK, RoomDef.Type.LOOT, RoomDef.Type.BLACK_MARKET]
	if floor_num >= 2:
		fillers.append(RoomDef.Type.COMBAT)
	while pool.size() < count:
		pool.append(fillers[randi() % fillers.size()])
	pool.shuffle()
	return pool.slice(0, count)

static func _opposite(dir: int) -> int:
	match dir:
		RoomDef.NORTH: return RoomDef.SOUTH
		RoomDef.SOUTH: return RoomDef.NORTH
		RoomDef.EAST:  return RoomDef.WEST
		RoomDef.WEST:  return RoomDef.EAST
	return RoomDef.NORTH

static func _dir_offset(dir: int) -> Vector2i:
	match dir:
		RoomDef.NORTH: return Vector2i(0, -1)
		RoomDef.EAST:  return Vector2i(1, 0)
		RoomDef.SOUTH: return Vector2i(0, 1)
		RoomDef.WEST:  return Vector2i(-1, 0)
	return Vector2i.ZERO

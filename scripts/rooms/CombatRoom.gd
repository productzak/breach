extends BaseRoom

const ENEMY_SCENES := {
	"drone": "res://scenes/enemies/Drone.tscn",
	"gang":  "res://scenes/enemies/GangMember.tscn",
	"bot":   "res://scenes/enemies/SecurityBot.tscn",
}

var _enemies_spawned := false
var _room_cleared    := false
var _check_delay     := 2.0

func _on_room_ready() -> void:
	# Lock all doors until enemies are dead
	for dir in room_def.connections.keys():
		_add_door_blocker(dir)

	# Small spawn delay so nav map is ready
	call_deferred("_spawn_enemies")

var _spawned_count := 0

func _spawn_enemies() -> void:
	var spawn_list := _enemy_list(room_def.floor_num)
	var positions  := _spread_positions(spawn_list.size())
	for i in spawn_list.size():
		var scene := load(ENEMY_SCENES[spawn_list[i]]) as PackedScene
		var e     := scene.instantiate()
		if spawn_list[i] == "bot":
			e.bullet_scene = load("res://scenes/projectiles/EnemyBullet.tscn")
		e.position = positions[i]
		add_child(e)
	_spawned_count   = spawn_list.size()
	_enemies_spawned = true

func _enemy_list(floor_num: int) -> Array:
	var list: Array = []
	match floor_num:
		1:
			for _i in randi_range(3, 4): list.append("drone")
			for _i in randi_range(1, 2): list.append("gang")
		2:
			for _i in randi_range(3, 5): list.append("drone")
			for _i in randi_range(2, 3): list.append("gang")
			list.append("bot")
		_:
			for _i in randi_range(2, 4): list.append("drone")
			for _i in randi_range(3, 4): list.append("gang")
			for _i in randi_range(1, 2): list.append("bot")
	list.shuffle()
	return list

func _spread_positions(count: int) -> Array:
	var zone_left   := BORDER + 200.0
	var zone_right  := ROOM_W - BORDER - 60.0
	var zone_top    := BORDER + 60.0
	var zone_bottom := ROOM_H - BORDER - 60.0
	var positions: Array = []
	var attempts := 0
	while positions.size() < count and attempts < 200:
		attempts += 1
		var p := Vector2(
			randf_range(zone_left, zone_right),
			randf_range(zone_top, zone_bottom)
		)
		var ok := true
		for existing in positions:
			if p.distance_to(existing) < 100.0:
				ok = false; break
		# Keep away from player spawn (left side)
		if p.x < zone_left + 100:
			ok = false
		if ok:
			positions.append(p)
	return positions

func _process(delta: float) -> void:
	super._process(delta)
	if _room_cleared or not _enemies_spawned:
		return
	if _check_delay > 0.0:
		_check_delay -= delta
		return
	if get_tree().get_nodes_in_group("enemies").is_empty():
		_room_cleared = true
		RunManager.on_enemies_killed(_spawned_count)
		unlock_all_doors()
		RunManager.on_room_cleared(room_def.id)

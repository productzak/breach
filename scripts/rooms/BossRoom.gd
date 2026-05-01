extends BaseRoom

var _enemies_spawned := false
var _room_cleared    := false
var _check_delay     := 2.5

func _on_room_ready() -> void:
	_add_boss_arena_visuals()
	call_deferred("_spawn_boss")

func _add_boss_arena_visuals() -> void:
	# Warning ring in center
	var ring := Polygon2D.new()
	var pts: PackedVector2Array = PackedVector2Array()
	var segments := 32
	var inner_r  := 180.0
	for i in segments:
		var a := TAU * i / float(segments)
		pts.append(Vector2(cos(a) * inner_r, sin(a) * inner_r))
	ring.polygon  = pts
	ring.color    = Color(0.9, 0.15, 0.1, 0.12)
	ring.position = Vector2(ROOM_W / 2.0, ROOM_H / 2.0)
	add_child(ring)

	var floor_lbl := Label.new()
	floor_lbl.text = "BOSS ENCOUNTER"
	floor_lbl.add_theme_font_size_override("font_size", 14)
	floor_lbl.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 0.5))
	floor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floor_lbl.position = Vector2(ROOM_W / 2.0 - 120, 80)
	floor_lbl.size     = Vector2(240, 20)
	add_child(floor_lbl)

func _spawn_boss() -> void:
	var cx := ROOM_W / 2.0
	var cy := ROOM_H / 2.0

	# Main boss: souped-up SecurityBot
	var secbot_scene := load("res://scenes/enemies/SecurityBot.tscn") as PackedScene
	var boss := secbot_scene.instantiate()
	boss.health           = 350
	boss.move_speed       = 130.0
	boss.shoot_rate       = 1.0
	boss.bullet_damage    = 22
	boss.detection_radius = 9999.0
	boss.currency_drop    = 80
	boss.bullet_scene     = load("res://scenes/projectiles/EnemyBullet.tscn")
	boss.position         = Vector2(cx + 200, cy)
	add_child(boss)

	# Minion drones
	var drone_scene := load("res://scenes/enemies/Drone.tscn") as PackedScene
	var minion_positions := [
		Vector2(cx + 100, cy - 180),
		Vector2(cx + 100, cy + 180),
		Vector2(cx + 360, cy - 120),
		Vector2(cx + 360, cy + 120),
	]
	for pos in minion_positions:
		var drone := drone_scene.instantiate()
		drone.health     = 50
		drone.move_speed = 130.0
		drone.position   = pos
		add_child(drone)

	# Gang member flankers
	var gang_scene := load("res://scenes/enemies/GangMember.tscn") as PackedScene
	for pos in [Vector2(cx + 280, cy - 200), Vector2(cx + 280, cy + 200)]:
		var g := gang_scene.instantiate()
		g.health   = 50
		g.position = pos
		add_child(g)

	_enemies_spawned = true

func _process(delta: float) -> void:
	super._process(delta)
	if _room_cleared or not _enemies_spawned:
		return
	if _check_delay > 0.0:
		_check_delay -= delta
		return
	if get_tree().get_nodes_in_group("enemies").is_empty():
		_room_cleared = true
		RunManager.on_boss_defeated()

extends BaseRoom

var _floor_exit: Area2D = null
var _exit_label: Label = null

func _on_room_ready() -> void:
	_build_floor_exit()
	RunManager.floor_cleared.connect(_on_floor_cleared)
	if _is_floor_done():
		_show_exit()

func _build_floor_exit() -> void:
	# Central portal that appears when all spokes are cleared
	var cx := ROOM_W / 2.0
	var cy := ROOM_H / 2.0

	# Visual indicator (initially hidden)
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(-40, -28), Vector2(40, -28),
		Vector2(40, 28),   Vector2(-40, 28),
	])
	vis.color   = Color(0.1, 0.8, 0.4, 0.0)
	vis.position = Vector2(cx, cy)
	vis.name    = "ExitVis"
	add_child(vis)

	_exit_label = Label.new()
	_exit_label.text = "▶  NEXT FLOOR  ◀"
	_exit_label.add_theme_font_size_override("font_size", 13)
	_exit_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
	_exit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_exit_label.position = Vector2(cx - 100, cy - 10)
	_exit_label.size     = Vector2(200, 20)
	_exit_label.visible  = false
	add_child(_exit_label)

	_floor_exit = Area2D.new()
	_floor_exit.collision_layer = 0
	_floor_exit.collision_mask  = 2
	var cs    := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(80, 56)
	cs.shape   = shape
	_floor_exit.add_child(cs)
	_floor_exit.position = Vector2(cx, cy)
	_floor_exit.monitorable = false
	_floor_exit.body_entered.connect(_on_exit_entered)
	_floor_exit.set_deferred("monitoring", false)
	add_child(_floor_exit)

func _show_exit() -> void:
	if not is_instance_valid(_floor_exit):
		return
	_floor_exit.set_deferred("monitoring", true)
	_exit_label.visible = true
	var vis := get_node_or_null("ExitVis") as Polygon2D
	if vis:
		vis.color = Color(0.1, 0.8, 0.4, 0.55)
	var t := create_tween().set_loops()
	t.tween_property(_exit_label, "modulate:a", 0.3, 0.7)
	t.tween_property(_exit_label, "modulate:a", 1.0, 0.7)

func _is_floor_done() -> bool:
	for id in RunManager.rooms:
		var def: RoomDef = RunManager.rooms[id]
		if def.type == RoomDef.Type.HUB:
			continue
		if not def.cleared:
			return false
	return true

func _on_floor_cleared() -> void:
	_show_exit()

func _on_exit_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		RunManager.advance_floor()

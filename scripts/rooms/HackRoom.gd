extends BaseRoom

var _terminal: Node2D = null
var _reward_given := false

func _on_room_ready() -> void:
	_build_terminal()

func _build_terminal() -> void:
	var cx := ROOM_W / 2.0
	var cy := ROOM_H / 2.0

	_terminal = Node2D.new()
	_terminal.set_script(load("res://scripts/interactables/HackTerminal.gd"))
	_terminal.position = Vector2(cx, cy)
	_terminal.add_to_group("hackable")

	# Body visual (dark panel)
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(-28, -36), Vector2(28, -36),
		Vector2(28, 36),   Vector2(-28, 36),
	])
	vis.color = Color(0.08, 0.12, 0.22)
	vis.name  = "Visual"
	_terminal.add_child(vis)

	# Screen glow
	var screen := Polygon2D.new()
	screen.polygon = PackedVector2Array([
		Vector2(-18, -24), Vector2(18, -24),
		Vector2(18, 10),   Vector2(-18, 10),
	])
	screen.color = Color(0.1, 0.7, 1.0, 0.8)
	_terminal.add_child(screen)

	# Static body collision (so player can't walk through it)
	var body  := StaticBody2D.new()
	body.collision_layer = 1
	var cs    := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(56, 72)
	cs.shape   = shape
	body.add_child(cs)
	_terminal.add_child(body)

	var hint := Label.new()
	hint.text = "[ USE BREACH ]"
	hint.add_theme_font_size_override("font_size", 10)
	hint.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(-60, 46)
	hint.size     = Vector2(120, 16)
	_terminal.add_child(hint)

	_terminal.breached.connect(_on_terminal_breached)
	add_child(_terminal)

func _on_terminal_breached() -> void:
	if _reward_given:
		return
	_reward_given = true
	_give_reward()
	RunManager.on_room_cleared(room_def.id)

func _give_reward() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player := players[0]
	# Award currency bonus
	if player.get("stats") != null:
		player.stats.currency += 30
	# Spawn a loot pickup too
	_spawn_card_cache(player.global_position + Vector2(80, 0))

func _spawn_card_cache(pos: Vector2) -> void:
	var pickup := _make_pickup(pos, Color(0.6, 0.1, 0.9), "CARD\nCACHE")
	pickup.body_entered.connect(func(body):
		if body.is_in_group("player"):
			var dm = body.get_node_or_null("DeckManager")
			if dm != null:
				var pool := dm.get_draft_pool(1)
				if pool.size() > 0:
					dm.add_card(pool[0])
			pickup.queue_free()
	)
	add_child(pickup)

func _make_pickup(pos: Vector2, col: Color, lbl_text: String) -> Area2D:
	var area   := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 2
	area.position        = pos

	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(-16, -16), Vector2(16, -16),
		Vector2(16, 16),   Vector2(-16, 16),
	])
	vis.color = col
	area.add_child(vis)

	var cs    := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	cs.shape     = shape
	area.add_child(cs)

	var lbl := Label.new()
	lbl.text = lbl_text
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-20, -32)
	lbl.size     = Vector2(40, 28)
	area.add_child(lbl)

	return area

extends BaseRoom

func _on_room_ready() -> void:
	# Mark cleared immediately — loot rooms have no obstacle
	RunManager.on_room_cleared(room_def.id)
	_spawn_loot()

func _spawn_loot() -> void:
	var cx := ROOM_W / 2.0
	var cy := ROOM_H / 2.0

	var loot_types := ["health", "card", "currency"]
	loot_types.shuffle()
	var pick := loot_types[0]

	match pick:
		"health":
			_add_pickup(Vector2(cx, cy), Color(0.1, 0.85, 0.3), "MEDKIT\n+40 HP",
				func(body):
					if body.get("stats") != null:
						body.stats.current_health = mini(
							body.stats.current_health + 40, body.stats.max_health)
			)
		"card":
			_add_pickup(Vector2(cx, cy), Color(0.5, 0.1, 0.9), "CARD\nUPGRADE",
				func(body):
					var dm = body.get_node_or_null("DeckManager")
					if dm != null and dm.deck.size() > 0:
						dm.upgrade_card(dm.deck[randi() % dm.deck.size()])
			)
		"currency":
			_add_pickup(Vector2(cx, cy), Color(0.9, 0.75, 0.1), "CR\n+50",
				func(body):
					if body.get("stats") != null:
						body.stats.currency += 50
			)

	# Always also drop a second small pickup
	_add_pickup(Vector2(cx + 120, cy), Color(0.1, 0.65, 0.85), "CR\n+20",
		func(body):
			if body.get("stats") != null:
				body.stats.currency += 20
	)

func _add_pickup(pos: Vector2, col: Color, label_text: String, on_collect: Callable) -> void:
	var area   := Area2D.new()
	area.collision_layer = 0
	area.collision_mask  = 2
	area.position        = pos

	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(-18, -18), Vector2(18, -18),
		Vector2(18, 18),   Vector2(-18, 18),
	])
	vis.color = col
	area.add_child(vis)

	var cs    := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 20.0
	cs.shape     = shape
	area.add_child(cs)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-24, -40)
	lbl.size     = Vector2(48, 36)
	area.add_child(lbl)

	var already_collected := false
	area.body_entered.connect(func(body):
		if already_collected or not body.is_in_group("player"):
			return
		already_collected = true
		on_collect.call(body)
		area.queue_free()
	)
	add_child(area)

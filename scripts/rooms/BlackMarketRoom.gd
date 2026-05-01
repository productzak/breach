extends BaseRoom

func _on_room_ready() -> void:
	RunManager.on_room_cleared(room_def.id)
	_build_market()

func _build_market() -> void:
	var cx := ROOM_W / 2.0
	var cy := ROOM_H / 2.0

	# Counter
	var counter := Polygon2D.new()
	counter.polygon = PackedVector2Array([
		Vector2(-160, -20), Vector2(160, -20),
		Vector2(160, 20),   Vector2(-160, 20),
	])
	counter.color    = Color(0.18, 0.14, 0.10)
	counter.position = Vector2(cx, cy + 40)
	add_child(counter)

	# Counter top highlight
	var top := Polygon2D.new()
	top.polygon = PackedVector2Array([
		Vector2(-160, -20), Vector2(160, -20),
		Vector2(160, -14),  Vector2(-160, -14),
	])
	top.color    = Color(0.55, 0.42, 0.22)
	top.position = Vector2(cx, cy + 40)
	add_child(top)

	# Sign
	var sign_bg := Polygon2D.new()
	sign_bg.polygon = PackedVector2Array([
		Vector2(-120, -30), Vector2(120, -30),
		Vector2(120, 30),   Vector2(-120, 30),
	])
	sign_bg.color    = Color(0.12, 0.10, 0.06)
	sign_bg.position = Vector2(cx, cy - 60)
	add_child(sign_bg)

	var sign_lbl := Label.new()
	sign_lbl.text = "BLACK MARKET"
	sign_lbl.add_theme_font_size_override("font_size", 18)
	sign_lbl.add_theme_color_override("font_color", Color(0.95, 0.80, 0.2))
	sign_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sign_lbl.position = Vector2(cx - 120, cy - 74)
	sign_lbl.size     = Vector2(240, 28)
	add_child(sign_lbl)

	var coming_lbl := Label.new()
	coming_lbl.text = "COMING SOON"
	coming_lbl.add_theme_font_size_override("font_size", 10)
	coming_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	coming_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coming_lbl.position = Vector2(cx - 80, cy - 46)
	coming_lbl.size     = Vector2(160, 16)
	add_child(coming_lbl)

	# Ambient decoration: two crates on the sides
	for x_off in [-200.0, 200.0]:
		var crate := Polygon2D.new()
		crate.polygon = PackedVector2Array([
			Vector2(-22, -22), Vector2(22, -22),
			Vector2(22, 22),   Vector2(-22, 22),
		])
		crate.color    = Color(0.22, 0.18, 0.12)
		crate.position = Vector2(cx + x_off, cy + 20)
		add_child(crate)

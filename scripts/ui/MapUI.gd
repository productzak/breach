extends CanvasLayer

var _rooms: Dictionary = {}
var _current_id: int   = 0
var _nodes: Array      = []

const CELL    := 110.0
const R_SIZE  := Vector2(74, 46)
const ORIGIN  := Vector2(640, 300)

const TYPE_NAMES := ["HUB", "FIGHT", "HACK", "LOOT", "SHOP", "BOSS"]
const TYPE_COLS  := [
	Color(0.12, 0.50, 1.00),   # HUB
	Color(0.90, 0.20, 0.20),   # COMBAT
	Color(0.60, 0.10, 0.90),   # HACK
	Color(0.10, 0.75, 0.30),   # LOOT
	Color(0.90, 0.75, 0.10),   # BLACK_MARKET
	Color(1.00, 0.40, 0.00),   # BOSS
]

func _ready() -> void:
	visible = false
	# Build persistent dark overlay background
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.82)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Control.add_child(overlay)

	var title := Label.new()
	title.text = "MAP  [M]  —  FLOOR %d" % RunManager.current_floor
	title.name = "Title"
	title.add_theme_font_size_override("font_size", 15)
	title.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0))
	title.position = Vector2(20, 18)
	$Control.add_child(title)

func refresh(rooms: Dictionary, current_id: int) -> void:
	_rooms      = rooms
	_current_id = current_id
	if visible:
		_rebuild()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			visible = not visible
			if visible:
				_rebuild()

func _rebuild() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()

	# Update floor title
	var title := $Control.get_node_or_null("Title")
	if title:
		title.text = "MAP  [M]  —  FLOOR %d" % RunManager.current_floor

	if _rooms.is_empty():
		return

	# Draw connection lines first (behind room boxes)
	for id in _rooms:
		var def: RoomDef = _rooms[id]
		var from_center := ORIGIN + Vector2(def.map_pos.x * CELL, def.map_pos.y * CELL)
		for dir in def.connections:
			var target_id: int = def.connections[dir]
			if target_id <= id:
				continue
			var tdef: RoomDef = _rooms[target_id]
			var to_center := ORIGIN + Vector2(tdef.map_pos.x * CELL, tdef.map_pos.y * CELL)
			# Approximate a line with a thin rotated ColorRect
			var diff := to_center - from_center
			var mid  := (from_center + to_center) * 0.5
			var line := ColorRect.new()
			line.color               = Color(0.4, 0.4, 0.5, 0.7)
			line.size                = Vector2(diff.length(), 3)
			line.pivot_offset        = Vector2(diff.length() * 0.5, 1.5)
			line.position            = mid - line.pivot_offset
			line.rotation            = diff.angle()
			$Control.add_child(line)
			_nodes.append(line)

	# Draw room boxes on top
	for id in _rooms:
		var def: RoomDef = _rooms[id]
		var center := ORIGIN + Vector2(def.map_pos.x * CELL, def.map_pos.y * CELL)
		var rpos   := center - R_SIZE * 0.5

		# Highlight border for current room
		if id == _current_id:
			var border := ColorRect.new()
			border.position = rpos - Vector2(3, 3)
			border.size     = R_SIZE + Vector2(6, 6)
			border.color    = Color.WHITE
			$Control.add_child(border)
			_nodes.append(border)

		var col: Color = TYPE_COLS[def.type]
		if def.cleared:
			col = col.darkened(0.42)

		var box := ColorRect.new()
		box.position = rpos
		box.size     = R_SIZE
		box.color    = col
		$Control.add_child(box)
		_nodes.append(box)

		var lbl := Label.new()
		lbl.text = TYPE_NAMES[def.type]
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = rpos + Vector2(0, 14)
		lbl.size     = R_SIZE
		$Control.add_child(lbl)
		_nodes.append(lbl)

		if def.cleared:
			var check := Label.new()
			check.text = "✓"
			check.add_theme_font_size_override("font_size", 13)
			check.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
			check.position = rpos + Vector2(R_SIZE.x - 16, 2)
			check.size     = Vector2(16, 18)
			$Control.add_child(check)
			_nodes.append(check)

extends CanvasLayer

var _boss: Node = null
var _max_health: int = 1
var _bar_fill: ColorRect = null
var _name_lbl: Label = null
var _phase_lbl: Label = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build_ui()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var panel := ColorRect.new()
	panel.color = Color(0.04, 0.04, 0.08, 0.90)
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_top = 8
	panel.offset_bottom = 60
	panel.offset_left = 220
	panel.offset_right = -220
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	_name_lbl = Label.new()
	_name_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_name_lbl.offset_top = 5
	_name_lbl.offset_bottom = 22
	_name_lbl.add_theme_font_size_override("font_size", 12)
	_name_lbl.add_theme_color_override("font_color", Color(0.95, 0.2, 0.2))
	_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_name_lbl)

	_phase_lbl = Label.new()
	_phase_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_phase_lbl.offset_top = 22
	_phase_lbl.offset_bottom = 35
	_phase_lbl.add_theme_font_size_override("font_size", 9)
	_phase_lbl.add_theme_color_override("font_color", Color(0.7, 0.4, 0.9))
	_phase_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_phase_lbl)

	var bar_bg := ColorRect.new()
	bar_bg.color = Color(0.18, 0.04, 0.04)
	bar_bg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar_bg.offset_top = 36
	bar_bg.offset_bottom = 50
	bar_bg.offset_left = 8
	bar_bg.offset_right = -8
	bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bar_bg)

	_bar_fill = ColorRect.new()
	_bar_fill.color = Color(0.88, 0.12, 0.12)
	_bar_fill.anchor_left = 0.0
	_bar_fill.anchor_top = 0.0
	_bar_fill.anchor_right = 1.0
	_bar_fill.anchor_bottom = 1.0
	_bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_bg.add_child(_bar_fill)

func _process(_delta: float) -> void:
	if _boss == null or not is_instance_valid(_boss):
		_boss = null
		var bosses := get_tree().get_nodes_in_group("boss")
		if bosses.is_empty():
			visible = false
			return
		_boss = bosses[0]
		_max_health = _boss.max_health
		_name_lbl.text = _boss.boss_name
		visible = true

	var frac := clampf(float(_boss.health) / float(_max_health), 0.0, 1.0)
	_bar_fill.anchor_right = frac
	if _boss.has_method("get_phase_name"):
		_phase_lbl.text = _boss.get_phase_name()

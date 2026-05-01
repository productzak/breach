extends CanvasLayer

@onready var hbox: HBoxContainer = $Control/HBox

var _deck_manager = null
var _last_deck_size := -1
var _slots: Array = []
var _tooltip: Control = null

func _process(_delta: float) -> void:
	if _deck_manager == null:
		var players := get_tree().get_nodes_in_group("player")
		if players.is_empty():
			return
		var p := players[0]
		if p.has_node("DeckManager"):
			_deck_manager = p.get_node("DeckManager")
		return

	if _deck_manager.deck.size() != _last_deck_size:
		_rebuild()
	else:
		_update_slots()

func _rebuild() -> void:
	_hide_tooltip()
	for child in hbox.get_children():
		child.queue_free()
	_slots.clear()
	_last_deck_size = _deck_manager.deck.size()
	for card in _deck_manager.deck:
		_add_slot(card)
	# Staggered fade-in
	for i in _slots.size():
		var panel: Panel = _slots[i].panel
		panel.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(panel, "modulate:a", 1.0, 0.22).set_delay(float(i) * 0.07)

func _add_slot(card: HackCard) -> void:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(80, 100)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.12, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	var border := ColorRect.new()
	border.color = Color(0.15, 0.55, 0.85, 0.5)
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.offset_left = -1; border.offset_top = -1
	border.offset_right = 1; border.offset_bottom = 1
	border.z_index = -1
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(border)

	var icon := ColorRect.new()
	icon.color = card.icon_color
	icon.offset_left = 4; icon.offset_top = 4
	icon.offset_right = 76; icon.offset_bottom = 44
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon)

	var name_lbl := Label.new()
	name_lbl.text = card.card_name
	name_lbl.offset_left = 2; name_lbl.offset_top = 46
	name_lbl.offset_right = 78; name_lbl.offset_bottom = 62
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(name_lbl)

	var cd_lbl := Label.new()
	cd_lbl.offset_left = 2; cd_lbl.offset_top = 64
	cd_lbl.offset_right = 78; cd_lbl.offset_bottom = 76
	cd_lbl.add_theme_font_size_override("font_size", 8)
	cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_lbl.add_theme_color_override("font_color", Color(1, 0.6, 0.2))
	cd_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(cd_lbl)

	var cd_overlay := ColorRect.new()
	cd_overlay.color = Color(0, 0, 0, 0.68)
	cd_overlay.offset_left = 0; cd_overlay.offset_top = 0
	cd_overlay.offset_right = 80; cd_overlay.offset_bottom = 0
	cd_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(cd_overlay)

	var sel_border := ColorRect.new()
	sel_border.color = Color(1, 0.95, 0.3, 0.38)
	sel_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	sel_border.visible = false
	sel_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(sel_border)

	var locked_overlay := ColorRect.new()
	locked_overlay.color = Color(0.55, 0.0, 0.0, 0.78)
	locked_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	locked_overlay.visible = false
	locked_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(locked_overlay)

	var locked_lbl := Label.new()
	locked_lbl.text = "LOCKED"
	locked_lbl.add_theme_font_size_override("font_size", 9)
	locked_lbl.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	locked_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	locked_lbl.set_anchors_preset(Control.PRESET_CENTER)
	locked_lbl.offset_left = -30
	locked_lbl.offset_right = 30
	locked_lbl.offset_top = -8
	locked_lbl.offset_bottom = 8
	locked_lbl.visible = false
	locked_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(locked_lbl)

	panel.mouse_entered.connect(func(): _show_tooltip(card, panel))
	panel.mouse_exited.connect(func(): _hide_tooltip())
	panel.gui_input.connect(func(e): _on_slot_input(e, card))
	hbox.add_child(panel)
	_slots.append({card = card, panel = panel,
				   cd_overlay = cd_overlay, cd_lbl = cd_lbl,
				   sel_border = sel_border,
				   locked_overlay = locked_overlay, locked_lbl = locked_lbl})

func _update_slots() -> void:
	var locked := _deck_manager.cards_locked
	for s in _slots:
		var card: HackCard = s.card
		var frac := _deck_manager.cooldown_fraction(card)
		var remaining := _deck_manager.cooldown_remaining(card)
		s.cd_overlay.offset_bottom = 100.0 * frac
		s.cd_lbl.text = "%.0fs" % remaining if remaining > 0 else ""
		s.sel_border.visible = (not locked and _deck_manager.selected_card == card)
		s.locked_overlay.visible = locked
		s.locked_lbl.visible = locked

func _show_tooltip(card: HackCard, near_panel: Control) -> void:
	_hide_tooltip()
	_tooltip = _build_tooltip(card, near_panel)
	$Control.add_child(_tooltip)

func _hide_tooltip() -> void:
	if _tooltip != null and is_instance_valid(_tooltip):
		_tooltip.queue_free()
	_tooltip = null

func _build_tooltip(card: HackCard, near_panel: Control) -> Control:
	var tip := Panel.new()
	tip.custom_minimum_size = Vector2(130, 100)

	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.14, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tip.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 6; vbox.offset_right = -6
	vbox.offset_top = 5; vbox.offset_bottom = -5
	vbox.add_theme_constant_override("separation", 3)
	tip.add_child(vbox)

	var n := Label.new()
	n.text = card.card_name
	n.add_theme_font_size_override("font_size", 11)
	n.add_theme_color_override("font_color", card.icon_color)
	vbox.add_child(n)

	var d := Label.new()
	d.text = card.description
	d.add_theme_font_size_override("font_size", 9)
	d.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(d)

	var cd := Label.new()
	cd.text = "Cooldown: %.0fs" % card.cooldown
	cd.add_theme_font_size_override("font_size", 9)
	cd.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	vbox.add_child(cd)

	# Position above the hovered panel
	var panel_rect := near_panel.get_global_rect()
	tip.position = Vector2(panel_rect.position.x - 20.0, panel_rect.position.y - 112.0)
	tip.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(tip, "modulate:a", 1.0, 0.10)
	return tip

func _on_slot_input(event: InputEvent, card: HackCard) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		_deck_manager.select_card(card)

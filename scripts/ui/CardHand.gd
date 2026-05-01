extends CanvasLayer

@onready var hbox: HBoxContainer = $Control/HBox

var _deck_manager = null
var _last_deck_size := -1
var _slots: Array = []

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
	for child in hbox.get_children():
		child.queue_free()
	_slots.clear()
	_last_deck_size = _deck_manager.deck.size()
	for card in _deck_manager.deck:
		_add_slot(card)

func _add_slot(card: HackCard) -> void:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(80, 100)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.07, 0.12, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

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

func _on_slot_input(event: InputEvent, card: HackCard) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		_deck_manager.select_card(card)

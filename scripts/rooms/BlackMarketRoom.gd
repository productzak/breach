extends BaseRoom

var _shop_layer: CanvasLayer = null

func _on_room_ready() -> void:
	RunManager.on_room_cleared(room_def.id)
	_build_decor()
	call_deferred("_open_shop")

# ── Decoration (same as placeholder, kept for visual context behind shop) ──────

func _build_decor() -> void:
	var cx := ROOM_W / 2.0
	var cy := ROOM_H / 2.0
	var counter := Polygon2D.new()
	counter.polygon = PackedVector2Array([Vector2(-160,-20),Vector2(160,-20),Vector2(160,20),Vector2(-160,20)])
	counter.color = Color(0.18, 0.14, 0.10); counter.position = Vector2(cx, cy + 40)
	add_child(counter)

# ── Shop UI ───────────────────────────────────────────────────────────────────

func _open_shop() -> void:
	_shop_layer = CanvasLayer.new()
	_shop_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_shop_layer)
	get_tree().paused = true

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.88)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shop_layer.add_child(overlay)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.offset_left = -540; root.offset_right  = 540
	root.offset_top  = -320; root.offset_bottom = 320
	root.add_theme_constant_override("separation", 10)
	_shop_layer.add_child(root)

	# Title row
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 20)
	root.add_child(title_row)

	var title := Label.new()
	title.text = "BLACK MARKET"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.95, 0.80, 0.2))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	var cr_lbl := Label.new()
	cr_lbl.name = "CRLabel"
	cr_lbl.text = "CR  %d" % RunManager.player_stats.currency
	cr_lbl.add_theme_font_size_override("font_size", 16)
	cr_lbl.add_theme_color_override("font_color", Color(0.95, 0.82, 0.2))
	cr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_row.add_child(cr_lbl)

	if GameState.has_unlock("market_hack"):
		var disc := Label.new()
		disc.text = "[ 25% DISCOUNT ACTIVE ]"
		disc.add_theme_font_size_override("font_size", 10)
		disc.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		root.add_child(disc)

	# Columns
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(cols)

	var players := get_tree().get_nodes_in_group("player")
	var dm = null
	if players.size() > 0:
		dm = players[0].get_node_or_null("DeckManager")

	cols.add_child(_weapon_column())
	cols.add_child(_card_column(dm))
	cols.add_child(_cyberware_column())
	if dm != null:
		cols.add_child(_upgrade_column(dm))

	# Leave button
	var leave := Button.new()
	leave.text = "LEAVE MARKET"
	leave.process_mode = Node.PROCESS_MODE_ALWAYS
	leave.add_theme_font_size_override("font_size", 14)
	leave.custom_minimum_size = Vector2(0, 36)
	leave.pressed.connect(_close_shop)
	root.add_child(leave)

# ── Column builders ───────────────────────────────────────────────────────────

func _weapon_column() -> Control:
	var col := _make_column("WEAPONS")
	var pool := _available_weapons()
	pool.shuffle()
	for w in pool.slice(0, 3):
		col.add_child(_shop_item(w.weapon_name, w.description,
			"FR %.2f  ·  Melee %d" % [w.fire_rate, w.melee_damage],
			_discounted(w.cost),
			func(): _buy_weapon(w)))
	return col

func _card_column(dm) -> Control:
	var col := _make_column("HACK DECK")
	if dm == null:
		return col
	var pool: Array = dm.get_draft_pool(3)
	for card in pool:
		col.add_child(_shop_item(card.card_name, card.description,
			"CD %.0fs" % card.cooldown,
			_discounted(60),
			func(): _buy_card(card, dm)))
	return col

func _cyberware_column() -> Control:
	var col := _make_column("CYBERWARE")
	var pool := _all_cyberware()
	pool.shuffle()
	var count := 2 if randf() > 0.4 else 1
	for cw in pool.slice(0, count):
		col.add_child(_shop_item(cw.cyberware_name, cw.description, "", _discounted(cw.cost),
			func(): _buy_cyberware(cw)))
	return col

func _upgrade_column(dm) -> Control:
	var col := _make_column("UPGRADE CARD")
	var upgradable := dm.deck.filter(func(c): return c.upgraded_version != null)
	if upgradable.is_empty():
		var lbl := Label.new()
		lbl.text = "No upgrades\navailable"
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		col.add_child(lbl)
	else:
		for card in upgradable.slice(0, 3):
			col.add_child(_shop_item(card.card_name, "→ " + card.upgraded_version.card_name,
				"", _discounted(80),
				func(): _upgrade_card(card, dm)))
	return col

# ── Buy actions ───────────────────────────────────────────────────────────────

func _buy_weapon(w: WeaponDef) -> void:
	if not _deduct(_discounted(w.cost)):
		return
	RunManager.active_weapon = w
	RunManager.apply_to_current_player(w)
	_refresh_cr()

func _buy_card(card: HackCard, dm) -> void:
	if not _deduct(_discounted(60)):
		return
	dm.add_card(card)
	_refresh_cr()

func _buy_cyberware(cw: Cyberware) -> void:
	if RunManager.active_cyberware.size() >= RunManager.get_cyberware_slots():
		return
	if not _deduct(_discounted(cw.cost)):
		return
	RunManager.active_cyberware.append(cw)
	RunManager.apply_to_current_player(cw)
	_refresh_cr()

func _upgrade_card(card: HackCard, dm) -> void:
	if not _deduct(_discounted(80)):
		return
	dm.upgrade_card(card)
	_refresh_cr()

func _deduct(amount: int) -> bool:
	if RunManager.player_stats.currency < amount:
		return false
	RunManager.player_stats.currency -= amount
	RunManager.shop_spent_this_run   += amount
	AudioManager.play("shop_purchase")
	return true

func _discounted(base_cost: int) -> int:
	return int(base_cost * 0.75) if GameState.has_unlock("market_hack") else base_cost

func _refresh_cr() -> void:
	var lbl := _find_node_named(_shop_layer, "CRLabel")
	if lbl:
		lbl.text = "CR  %d" % RunManager.player_stats.currency

func _find_node_named(node: Node, target: String) -> Node:
	if node.name == target:
		return node
	for child in node.get_children():
		var r := _find_node_named(child, target)
		if r:
			return r
	return null

func _close_shop() -> void:
	get_tree().paused = false
	if is_instance_valid(_shop_layer):
		_shop_layer.queue_free()

# ── Item data factories ───────────────────────────────────────────────────────

func _available_weapons() -> Array:
	var pool: Array = [
		_weapon("Heavy Pistol",  "Slow rate, strong\nmelee bonus",  90,  0.25, 45),
		_weapon("Plasma Cutter", "Balanced upgrade",                85,  0.10, 38),
		_weapon("Burst Rifle",   "Very fast fire rate",             100, 0.06, 22),
	]
	if GameState.has_unlock("dual_wield"):
		pool.append(_weapon("Auto-Pistol", "Rapid fire,\nlight melee", 80, 0.07, 22))
	if GameState.has_unlock("ballistic_frame"):
		pool.append(_weapon("Combat Blade", "Slow shoot,\nmassive melee", 95, 0.22, 70))
	return pool

func _weapon(n: String, d: String, c: int, fr: float, md: int) -> WeaponDef:
	var w := WeaponDef.new()
	w.weapon_name = n; w.description = d; w.cost = c
	w.fire_rate = fr; w.melee_damage = md
	return w

func _all_cyberware() -> Array:
	return [
		_cw("Neural Processor", "Fire rate -25%",      Cyberware.EffectType.FIRE_RATE,    0.030, 70),
		_cw("Titanium Frame",   "+30 max HP",           Cyberware.EffectType.HEALTH_MAX,   30,    80),
		_cw("Overdrive Module", "+50 move speed",       Cyberware.EffectType.SPEED,        50,    65),
		_cw("Combat Stims",     "+12 melee damage",     Cyberware.EffectType.MELEE_DAMAGE, 12,    55),
		_cw("Regen Core",       "+20 HP per room clear",Cyberware.EffectType.REGEN_ON_CLEAR, 20,  90),
	]

func _cw(n: String, d: String, t: int, v: float, c: int) -> Cyberware:
	var cw := Cyberware.new()
	cw.cyberware_name = n; cw.description = d
	cw.effect_type = t; cw.effect_value = v; cw.cost = c
	return cw

# ── UI helpers ────────────────────────────────────────────────────────────────

func _make_column(title: String) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(240, 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)

	var title_lbl := Label.new()
	title_lbl.text = title
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
	col.add_child(title_lbl)

	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 2)
	div.color = Color(0.2, 0.5, 0.7, 0.4)
	col.add_child(div)

	return col

func _shop_item(name_text: String, desc_text: String, stat_text: String,
				cost: int, on_buy: Callable) -> Control:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 76)

	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.09, 0.14, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 6; vbox.offset_right = -6
	vbox.offset_top  = 4; vbox.offset_bottom = -4
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.text = name_text
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_lbl)

	if desc_text != "":
		var desc_lbl := Label.new()
		desc_lbl.text = desc_text
		desc_lbl.add_theme_font_size_override("font_size", 9)
		desc_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_lbl)

	if stat_text != "":
		var stat_lbl := Label.new()
		stat_lbl.text = stat_text
		stat_lbl.add_theme_font_size_override("font_size", 9)
		stat_lbl.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
		vbox.add_child(stat_lbl)

	var can_afford := RunManager.player_stats.currency >= cost
	var btn := Button.new()
	btn.text = "BUY  %d CR" % cost
	btn.disabled = not can_afford
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.add_theme_font_size_override("font_size", 10)
	btn.pressed.connect(func():
		on_buy.call()
		# Refresh button state after purchase
		btn.disabled = RunManager.player_stats.currency < cost
	)
	vbox.add_child(btn)

	return panel

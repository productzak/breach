extends Node

signal card_used(card: HackCard)

var deck: Array[HackCard] = []
var selected_card: HackCard = null
var _cooldowns: Dictionary = {}

func _ready() -> void:
	if RunManager.deck_cards.size() > 0:
		deck.assign(RunManager.deck_cards)
	else:
		deck = _make_starting_deck()
		if GameState.has_unlock("ghost_protocol"):  deck.append(_card_ping())
		if GameState.has_unlock("neural_implant"):  deck.append(_card_overclock())
		if GameState.has_unlock("vault_key"):       deck.append(_card_firewall())

func _process(delta: float) -> void:
	for key in _cooldowns.keys():
		_cooldowns[key] = maxf(_cooldowns[key] - delta, 0.0)
		if _cooldowns[key] <= 0.0:
			_cooldowns.erase(key)

func select_card(card: HackCard) -> void:
	if is_on_cooldown(card):
		return
	selected_card = card if selected_card != card else null

func cancel_selection() -> void:
	selected_card = null

func play_selected(target_pos: Vector2, target_node: Node2D = null) -> void:
	if selected_card == null:
		return
	var card := selected_card
	selected_card = null
	_apply_effect(card, target_pos, target_node)
	_cooldowns[card.card_name] = card.cooldown
	card_used.emit(card)

func is_on_cooldown(card: HackCard) -> bool:
	return _cooldowns.has(card.card_name)

func cooldown_fraction(card: HackCard) -> float:
	if not _cooldowns.has(card.card_name):
		return 0.0
	return _cooldowns[card.card_name] / card.cooldown

func cooldown_remaining(card: HackCard) -> float:
	return _cooldowns.get(card.card_name, 0.0)

func add_card(card: HackCard) -> void:
	deck.append(card)

func upgrade_card(card: HackCard) -> void:
	if card.upgraded_version == null:
		return
	var idx := deck.find(card)
	if idx >= 0:
		deck[idx] = card.upgraded_version

func get_draft_pool(count: int = 3) -> Array[HackCard]:
	var pool := _all_cards()
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))

# ── Effects ──────────────────────────────────────────────────────────────────

func _apply_effect(card: HackCard, target_pos: Vector2, target_node: Node2D) -> void:
	match card.effect_type:
		HackCard.EffectType.STUN:
			_effect_stun(target_pos, card.effect_radius, card.effect_duration)
		HackCard.EffectType.REDIRECT:
			_effect_redirect(target_node, card.effect_duration)
		HackCard.EffectType.BREACH:
			_effect_breach(target_pos, card.effect_radius, card.effect_duration)
		HackCard.EffectType.OVERCLOCK:
			_effect_overclock(card.effect_duration)
		HackCard.EffectType.PING:
			_effect_ping(card.effect_duration)
		HackCard.EffectType.FIREWALL:
			_effect_firewall(card.effect_duration)

func _effect_breach(pos: Vector2, radius: float, stun_duration: float) -> void:
	for node in get_tree().get_nodes_in_group("hackable"):
		if node.global_position.distance_to(pos) <= radius and node.has_method("on_breach"):
			node.on_breach(get_parent(), stun_duration)
			break
	# Breach+ also stuns nearby enemies
	if stun_duration > 0.0:
		_effect_stun(pos, radius * 1.5, stun_duration)

func _effect_stun(pos: Vector2, radius: float, duration: float) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(pos) <= radius and enemy.has_method("stun"):
			enemy.stun(duration)

func _effect_redirect(target: Node2D, duration: float) -> void:
	var t := target if (target != null and target.has_method("redirect")) \
					 else _nearest_enemy(get_parent().global_position)
	if t and t.has_method("redirect"):
		t.redirect(duration)

func _effect_overclock(duration: float) -> void:
	var player := get_parent()
	var orig := player.move_speed
	player.move_speed = orig * 1.8
	get_tree().create_timer(duration).timeout.connect(func(): player.move_speed = orig)

func _effect_ping(duration: float) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("ping"):
			enemy.ping(duration)

func _effect_firewall(duration: float) -> void:
	var player := get_parent()
	player.invincible = true
	get_tree().create_timer(duration).timeout.connect(func(): player.invincible = false)

func _nearest_enemy(from: Vector2) -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for e in get_tree().get_nodes_in_group("enemies"):
		var d := from.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

# ── Card definitions ─────────────────────────────────────────────────────────

func _make_starting_deck() -> Array[HackCard]:
	return [_card_stun(), _card_redirect(), _card_breach()]

func _all_cards() -> Array[HackCard]:
	return [_card_stun(), _card_redirect(), _card_breach(),
			_card_overclock(), _card_ping(), _card_firewall()]

func _card_stun() -> HackCard:
	var c := HackCard.new()
	c.card_name = "Stun.exe"
	c.description = "Stun enemies\nin radius\nfor 2.5s"
	c.icon_color = Color(0.2, 0.85, 1.0)
	c.effect_type = HackCard.EffectType.STUN
	c.cooldown = 12.0; c.effect_radius = 150.0; c.effect_duration = 2.5
	var u := HackCard.new()
	u.card_name = "Stun.exe+"; u.description = "Stun enemies\nin wider radius\nfor 4s"
	u.icon_color = Color(0.0, 1.0, 1.0)
	u.effect_type = HackCard.EffectType.STUN
	u.cooldown = 10.0; u.effect_radius = 220.0; u.effect_duration = 4.0
	c.upgraded_version = u
	return c

func _card_redirect() -> HackCard:
	var c := HackCard.new()
	c.card_name = "Redirect"; c.description = "Turn enemy\nagainst allies\nfor 5s"
	c.icon_color = Color(1.0, 0.6, 0.1)
	c.effect_type = HackCard.EffectType.REDIRECT
	c.cooldown = 18.0; c.effect_radius = 0.0; c.effect_duration = 5.0
	var u := HackCard.new()
	u.card_name = "Redirect+"; u.description = "Turn enemy\nagainst allies\nfor 9s"
	u.icon_color = Color(1.0, 0.4, 0.0)
	u.effect_type = HackCard.EffectType.REDIRECT
	u.cooldown = 15.0; u.effect_radius = 0.0; u.effect_duration = 9.0
	c.upgraded_version = u
	return c

func _card_breach() -> HackCard:
	var c := HackCard.new()
	c.card_name = "Breach"; c.description = "Unlock door\nor disable\nturret"
	c.icon_color = Color(0.9, 0.2, 0.5)
	c.effect_type = HackCard.EffectType.BREACH
	c.cooldown = 5.0; c.effect_radius = 100.0; c.effect_duration = 0.0
	var u := HackCard.new()
	u.card_name = "Breach+"; u.description = "Unlock door or\ndisable turret.\nStuns nearby\nenemies 1.5s"
	u.icon_color = Color(1.0, 0.1, 0.4)
	u.effect_type = HackCard.EffectType.BREACH
	u.cooldown = 4.0; u.effect_radius = 120.0; u.effect_duration = 1.5
	c.upgraded_version = u
	return c

func _card_overclock() -> HackCard:
	var c := HackCard.new()
	c.card_name = "Overclock"; c.description = "Move speed\n+80% for 4s"
	c.icon_color = Color(0.4, 1.0, 0.2)
	c.effect_type = HackCard.EffectType.OVERCLOCK
	c.cooldown = 20.0; c.effect_radius = 0.0; c.effect_duration = 4.0
	var u := HackCard.new()
	u.card_name = "Overclock+"; u.description = "Move speed\n+80% for 7s"
	u.icon_color = Color(0.2, 1.0, 0.0)
	u.effect_type = HackCard.EffectType.OVERCLOCK
	u.cooldown = 16.0; u.effect_radius = 0.0; u.effect_duration = 7.0
	c.upgraded_version = u
	return c

func _card_ping() -> HackCard:
	var c := HackCard.new()
	c.card_name = "Ping.exe"; c.description = "Flash all\nenemies for 3s"
	c.icon_color = Color(1.0, 1.0, 0.2)
	c.effect_type = HackCard.EffectType.PING
	c.cooldown = 8.0; c.effect_radius = 9999.0; c.effect_duration = 3.0
	var u := HackCard.new()
	u.card_name = "Ping.exe+"; u.description = "Flash all\nenemies for 5s"
	u.icon_color = Color(1.0, 0.95, 0.0)
	u.effect_type = HackCard.EffectType.PING
	u.cooldown = 6.0; u.effect_radius = 9999.0; u.effect_duration = 5.0
	c.upgraded_version = u
	return c

func _card_firewall() -> HackCard:
	var c := HackCard.new()
	c.card_name = "Firewall"; c.description = "Invincible\nfor 2s"
	c.icon_color = Color(0.6, 0.2, 1.0)
	c.effect_type = HackCard.EffectType.FIREWALL
	c.cooldown = 25.0; c.effect_radius = 0.0; c.effect_duration = 2.0
	var u := HackCard.new()
	u.card_name = "Firewall+"; u.description = "Invincible\nfor 4s"
	u.icon_color = Color(0.5, 0.0, 1.0)
	u.effect_type = HackCard.EffectType.FIREWALL
	u.cooldown = 20.0; u.effect_radius = 0.0; u.effect_duration = 4.0
	c.upgraded_version = u
	return c

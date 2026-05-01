extends Node

signal floor_cleared
signal run_ended(victory: bool)

const SCENES := {
	RoomDef.Type.HUB:          "res://scenes/rooms/HubRoom.tscn",
	RoomDef.Type.COMBAT:       "res://scenes/rooms/CombatRoom.tscn",
	RoomDef.Type.HACK:         "res://scenes/rooms/HackRoom.tscn",
	RoomDef.Type.LOOT:         "res://scenes/rooms/LootRoom.tscn",
	RoomDef.Type.BLACK_MARKET: "res://scenes/rooms/BlackMarketRoom.tscn",
	RoomDef.Type.BOSS:         "res://scenes/rooms/BossRoom.tscn",
}

# ── Persistent run state ──────────────────────────────────────────────────────
var player_stats: PlayerStats = null
var deck_cards: Array[HackCard] = []
var active_cyberware: Array[Cyberware] = []
var active_weapon: WeaponDef = null

# ── Floor / room state ────────────────────────────────────────────────────────
var current_floor: int = 1
var rooms: Dictionary = {}
var current_room_id: int = 0
var entry_direction: int = -1

# ── Run-end stats (set in _finalize_run, read by end screens) ─────────────────
var enemies_killed: int = 0
var shop_spent_this_run: int = 0
var floor_reached: int = 1
var currency_earned_last_run: int = 0
var persistent_awarded_last_run: int = 0

# ── UI refs ───────────────────────────────────────────────────────────────────
var _hud         = null
var _death_screen = null
var _victory_screen = null
var _card_hand   = null
var _draft_screen = null
var _map_ui      = null

func _ready() -> void:
	_setup_persistent_ui()
	call_deferred("go_to_network")

func _setup_persistent_ui() -> void:
	_hud = load("res://scenes/ui/HUD.tscn").instantiate()
	add_child(_hud)
	_death_screen = load("res://scenes/ui/DeathScreen.tscn").instantiate()
	add_child(_death_screen)
	_victory_screen = load("res://scenes/ui/VictoryScreen.tscn").instantiate()
	add_child(_victory_screen)
	_card_hand = load("res://scenes/ui/CardHand.tscn").instantiate()
	add_child(_card_hand)
	_draft_screen = load("res://scenes/ui/DraftScreen.tscn").instantiate()
	add_child(_draft_screen)
	_map_ui = load("res://scenes/ui/MapUI.tscn").instantiate()
	add_child(_map_ui)

# ── Navigation ────────────────────────────────────────────────────────────────

func go_to_network() -> void:
	_set_gameplay_ui(false)
	get_tree().change_scene_to_packed(load("res://scenes/ui/NetworkMenu.tscn"))

func start_run() -> void:
	_set_gameplay_ui(true)
	player_stats = PlayerStats.new()
	player_stats.max_health = 100
	player_stats.current_health = 100
	player_stats.currency = 0
	deck_cards.clear()
	enemies_killed    = 0
	shop_spent_this_run = 0
	active_cyberware.clear()
	active_weapon = null
	current_floor = 1
	_apply_stat_cyberware()
	_generate_and_load()

func restart_run() -> void:
	get_tree().paused = false
	start_run()

func _set_gameplay_ui(visible: bool) -> void:
	_hud.visible       = visible
	_card_hand.visible = visible
	# map/draft/death/victory manage their own visibility

func _generate_and_load() -> void:
	if current_floor <= 3:
		rooms = FloorGenerator.generate(current_floor)
	else:
		rooms.clear()
		var boss := RoomDef.new()
		boss.id = 0; boss.type = RoomDef.Type.BOSS; boss.floor_num = current_floor
		rooms[0] = boss
	current_room_id  = 0
	entry_direction  = -1
	_map_ui.refresh(rooms, current_room_id)
	_load_room(0)

func _load_room(room_id: int) -> void:
	current_room_id = room_id
	_map_ui.refresh(rooms, current_room_id)
	var def: RoomDef = rooms[room_id]
	get_tree().change_scene_to_packed(load(SCENES[def.type]))

func travel_to_room(target_id: int, came_from_dir: int) -> void:
	_save_deck()
	entry_direction = came_from_dir
	_load_room(target_id)

func advance_floor() -> void:
	_save_deck()
	current_floor += 1
	_generate_and_load()

# ── Room query ────────────────────────────────────────────────────────────────

func get_current_room_def() -> RoomDef:
	return rooms.get(current_room_id)

func get_entry_direction() -> int:
	return entry_direction

func get_cyberware_slots() -> int:
	var slots := 1
	if GameState.has_unlock("cyberware_bay"):   slots += 1
	if GameState.has_unlock("enhanced_bay"):    slots += 1
	return slots

# ── Room clear events ─────────────────────────────────────────────────────────

func on_room_cleared(room_id: int) -> void:
	if rooms.has(room_id):
		rooms[room_id].cleared = true
	_map_ui.refresh(rooms, current_room_id)
	# Regen cyberware on clear
	for cw in active_cyberware:
		if cw.effect_type == Cyberware.EffectType.REGEN_ON_CLEAR:
			player_stats.current_health = mini(
				player_stats.current_health + int(cw.effect_value), player_stats.max_health)
	var def: RoomDef = rooms.get(room_id)
	if def and def.type == RoomDef.Type.COMBAT:
		_show_draft()
	_check_all_cleared()

func on_enemies_killed(count: int) -> void:
	enemies_killed += count

func _check_all_cleared() -> void:
	for id in rooms:
		var def: RoomDef = rooms[id]
		if def.type == RoomDef.Type.HUB:
			continue
		if not def.cleared:
			return
	floor_cleared.emit()
	var scene := get_tree().current_scene
	if scene and scene.has_method("on_floor_cleared"):
		scene.on_floor_cleared()

# ── Run-end events ────────────────────────────────────────────────────────────

func show_death_screen() -> void:
	_finalize_run(false)
	_death_screen.show_death()

func on_boss_defeated() -> void:
	if rooms.has(0):
		rooms[0].cleared = true
	_map_ui.refresh(rooms, current_room_id)
	_finalize_run(true)
	run_ended.emit(true)
	_victory_screen.show_victory()

func _finalize_run(_victory: bool) -> void:
	_save_deck()
	floor_reached            = current_floor
	currency_earned_last_run = player_stats.currency + shop_spent_this_run
	persistent_awarded_last_run = GameState.award_run_end(currency_earned_last_run)

# ── Cyberware / weapon helpers ────────────────────────────────────────────────

func _apply_stat_cyberware() -> void:
	if GameState.has_unlock("combat_stims"):
		player_stats.max_health    += 20
		player_stats.current_health += 20
	for cw in active_cyberware:
		if cw.effect_type == Cyberware.EffectType.HEALTH_MAX:
			player_stats.max_health    += int(cw.effect_value)
			player_stats.current_health += int(cw.effect_value)

func apply_run_modifiers(player: Node) -> void:
	for cw in active_cyberware:
		match cw.effect_type:
			Cyberware.EffectType.SPEED:
				player.move_speed += cw.effect_value
			Cyberware.EffectType.MELEE_DAMAGE:
				player.melee_damage += int(cw.effect_value)
			Cyberware.EffectType.FIRE_RATE:
				player.fire_rate = maxf(0.04, player.fire_rate - cw.effect_value)
	if active_weapon != null:
		player.fire_rate    = active_weapon.fire_rate
		player.melee_damage = active_weapon.melee_damage

func apply_to_current_player(cw_or_weapon) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p := players[0]
	if cw_or_weapon is Cyberware:
		match cw_or_weapon.effect_type:
			Cyberware.EffectType.SPEED:        p.move_speed  += cw_or_weapon.effect_value
			Cyberware.EffectType.MELEE_DAMAGE: p.melee_damage += int(cw_or_weapon.effect_value)
			Cyberware.EffectType.FIRE_RATE:    p.fire_rate = maxf(0.04, p.fire_rate - cw_or_weapon.effect_value)
			Cyberware.EffectType.HEALTH_MAX:
				p.stats.max_health    += int(cw_or_weapon.effect_value)
				p.stats.current_health += int(cw_or_weapon.effect_value)
	elif cw_or_weapon is WeaponDef:
		p.fire_rate    = cw_or_weapon.fire_rate
		p.melee_damage = cw_or_weapon.melee_damage

# ── Draft ─────────────────────────────────────────────────────────────────────

func _show_draft() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var dm = players[0].get_node_or_null("DeckManager")
	if dm != null:
		_draft_screen.show_draft(dm)

# ── Deck persistence ──────────────────────────────────────────────────────────

func _save_deck() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var dm = players[0].get_node_or_null("DeckManager")
	if dm == null:
		return
	deck_cards.clear()
	for card in dm.deck:
		deck_cards.append(card)

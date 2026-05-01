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

var player_stats: PlayerStats = null
var deck_cards: Array[HackCard] = []

var current_floor: int = 1
var rooms: Dictionary = {}
var current_room_id: int = 0
var entry_direction: int = -1

var _death_screen = null
var _victory_screen = null
var _draft_screen = null
var _map_ui = null

func _ready() -> void:
	_setup_persistent_ui()
	call_deferred("start_run")

func _setup_persistent_ui() -> void:
	var hud = load("res://scenes/ui/HUD.tscn").instantiate()
	add_child(hud)
	_death_screen = load("res://scenes/ui/DeathScreen.tscn").instantiate()
	add_child(_death_screen)
	_victory_screen = load("res://scenes/ui/VictoryScreen.tscn").instantiate()
	add_child(_victory_screen)
	var card_hand = load("res://scenes/ui/CardHand.tscn").instantiate()
	add_child(card_hand)
	_draft_screen = load("res://scenes/ui/DraftScreen.tscn").instantiate()
	add_child(_draft_screen)
	_map_ui = load("res://scenes/ui/MapUI.tscn").instantiate()
	add_child(_map_ui)

func start_run() -> void:
	player_stats = PlayerStats.new()
	player_stats.max_health = 100
	player_stats.current_health = 100
	player_stats.currency = 0
	deck_cards.clear()
	current_floor = 1
	_generate_and_load()

func restart_run() -> void:
	get_tree().paused = false
	start_run()

func _generate_and_load() -> void:
	if current_floor <= 3:
		rooms = FloorGenerator.generate(current_floor)
	else:
		rooms.clear()
		var boss := RoomDef.new()
		boss.id = 0
		boss.type = RoomDef.Type.BOSS
		boss.floor_num = current_floor
		rooms[0] = boss
	current_room_id = 0
	entry_direction = -1
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

func get_current_room_def() -> RoomDef:
	return rooms.get(current_room_id)

func get_entry_direction() -> int:
	return entry_direction

func on_room_cleared(room_id: int) -> void:
	if rooms.has(room_id):
		rooms[room_id].cleared = true
	_map_ui.refresh(rooms, current_room_id)
	var def: RoomDef = rooms.get(room_id)
	if def and def.type == RoomDef.Type.COMBAT:
		_show_draft()
	_check_all_cleared()

func _show_draft() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var dm = players[0].get_node_or_null("DeckManager")
	if dm != null:
		_draft_screen.show_draft(dm)

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

func show_death_screen() -> void:
	_death_screen.show_death()

func on_boss_defeated() -> void:
	if rooms.has(0):
		rooms[0].cleared = true
	_map_ui.refresh(rooms, current_room_id)
	run_ended.emit(true)
	_victory_screen.show_victory()

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

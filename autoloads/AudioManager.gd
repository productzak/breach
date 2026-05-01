extends Node

const EVENTS := [
	"player_shoot", "player_melee_hit", "player_hurt", "player_death",
	"enemy_hurt", "enemy_death", "boss_phase_change",
	"card_played", "card_drafted", "shop_purchase",
	"room_cleared", "floor_transition", "boss_intro",
]

var _players: Dictionary = {}

func _ready() -> void:
	for ev in EVENTS:
		var p := AudioStreamPlayer.new()
		p.name = ev
		add_child(p)
		_players[ev] = p

func play(event: String) -> void:
	if _players.has(event):
		var p: AudioStreamPlayer = _players[event]
		if p.stream != null and not p.playing:
			p.play()

func set_master_volume(vol: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(vol, 0.001)))

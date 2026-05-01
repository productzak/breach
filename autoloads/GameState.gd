extends Node

const SAVE_PATH := "user://breach_save.json"

var persistent_currency: int = 0
var purchased_unlocks: Array = []
var crt_enabled: bool = false
var master_volume: float = 1.0

func _ready() -> void:
	load_data()

func has_unlock(id: String) -> bool:
	return id in purchased_unlocks

func purchase_unlock(id: String, cost: int) -> bool:
	if persistent_currency < cost or has_unlock(id):
		return false
	persistent_currency -= cost
	purchased_unlocks.append(id)
	save_data()
	return true

func award_run_end(in_run_currency: int) -> int:
	var award := int(in_run_currency * 0.30)
	persistent_currency += award
	save_data()
	return award

func save_data() -> void:
	var data := {
		"persistent_currency": persistent_currency,
		"purchased_unlocks": purchased_unlocks,
		"crt_enabled": crt_enabled,
		"master_volume": master_volume,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if data is Dictionary:
		persistent_currency = int(data.get("persistent_currency", 0))
		purchased_unlocks = []
		for id in data.get("purchased_unlocks", []):
			purchased_unlocks.append(str(id))
		crt_enabled = bool(data.get("crt_enabled", false))
		master_volume = float(data.get("master_volume", 1.0))

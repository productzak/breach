extends CanvasLayer

var _vignette: ColorRect = null
var _flash: ColorRect = null
var _scanlines = null
var _vignette_t := 0.0
var _shake_requested := false

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Red vignette edge overlay for low health
	_vignette = ColorRect.new()
	_vignette.color = Color(0.85, 0.0, 0.05, 0.0)
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.visible = false
	root.add_child(_vignette)

	# Room transition flash
	_flash = ColorRect.new()
	_flash.color = Color(0.15, 0.85, 1.0, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.visible = false
	root.add_child(_flash)

	# CRT scanlines
	_scanlines = load("res://scripts/effects/ScanlinesOverlay.gd").new()
	_scanlines.visible = GameState.crt_enabled
	root.add_child(_scanlines)

func _process(delta: float) -> void:
	_update_vignette(delta)

func _update_vignette(delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		_vignette.visible = false
		return
	var stats = players[0].get("stats")
	if stats == null or stats.max_health <= 0:
		_vignette.visible = false
		return
	var frac := float(stats.current_health) / float(stats.max_health)
	if frac > 0.25:
		_vignette.visible = false
		_vignette_t = 0.0
		return
	_vignette.visible = true
	_vignette_t += delta * 3.5
	_vignette.color.a = (sin(_vignette_t) * 0.5 + 0.5) * 0.38

func flash_transition(on_mid: Callable) -> void:
	_flash.color = Color(0.15, 0.85, 1.0, 0.0)
	_flash.visible = true
	var t := create_tween()
	t.tween_property(_flash, "color:a", 1.0, 0.07)
	t.tween_callback(on_mid)
	t.tween_property(_flash, "color:a", 0.0, 0.16)
	t.tween_callback(func(): _flash.visible = false)

func set_crt_enabled(val: bool) -> void:
	GameState.crt_enabled = val
	GameState.save_data()
	if _scanlines:
		_scanlines.visible = val

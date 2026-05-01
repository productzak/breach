extends Control

@onready var settings_panel: Control = $SettingsPanel
@onready var crt_check: CheckButton   = $SettingsPanel/VBox/CRTRow/CRTCheck
@onready var vol_slider: HSlider      = $SettingsPanel/VBox/VolumeRow/VolumeSlider

func _ready() -> void:
	settings_panel.visible = false
	crt_check.button_pressed = GameState.crt_enabled
	vol_slider.value = GameState.master_volume

func _on_start_pressed() -> void:
	RunManager.go_to_network()

func _on_settings_pressed() -> void:
	settings_panel.visible = not settings_panel.visible
	if settings_panel.visible:
		settings_panel.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(settings_panel, "modulate:a", 1.0, 0.18)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_crt_toggled(val: bool) -> void:
	ScreenEffects.set_crt_enabled(val)

func _on_volume_changed(val: float) -> void:
	GameState.master_volume = val
	GameState.save_data()
	AudioManager.set_master_volume(val)

func _on_close_settings_pressed() -> void:
	var t := create_tween()
	t.tween_property(settings_panel, "modulate:a", 0.0, 0.14)
	t.tween_callback(func(): settings_panel.visible = false)

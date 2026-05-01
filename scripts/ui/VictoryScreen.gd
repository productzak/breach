extends CanvasLayer

func show_victory() -> void:
	visible = true
	get_tree().paused = true

func _on_new_run_pressed() -> void:
	get_tree().paused = false
	RunManager.restart_run()

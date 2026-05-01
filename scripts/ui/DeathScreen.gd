extends CanvasLayer

func show_death() -> void:
	visible = true
	get_tree().paused = true

func _on_try_again_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

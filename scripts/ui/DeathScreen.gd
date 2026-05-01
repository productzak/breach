extends CanvasLayer

@onready var title_label: Label = $CenterBox/Title

func show_death() -> void:
	title_label.text = "BREACH FAILED"
	visible = true
	get_tree().paused = true

func _on_try_again_pressed() -> void:
	RunManager.restart_run()

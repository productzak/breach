extends CanvasLayer

@onready var title_lbl: Label  = $CenterBox/Title
@onready var sub_lbl: Label    = $CenterBox/Subtitle

func show_death() -> void:
	title_lbl.text = "BREACH FAILED"
	sub_lbl.text   = "connection lost"
	_update_stats()
	visible = true
	get_tree().paused = true

func _update_stats() -> void:
	var old := $CenterBox.get_node_or_null("RunStats")
	if old:
		old.queue_free()
	var lbl := Label.new()
	lbl.name = "RunStats"
	lbl.text = "Floor %d  ·  %d Eliminated  ·  %d CR Earned\n+%d Network Credits awarded" % [
		RunManager.floor_reached,
		RunManager.enemies_killed,
		RunManager.currency_earned_last_run,
		RunManager.persistent_awarded_last_run,
	]
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85, 0.9))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.size = Vector2(360, 48)
	$CenterBox.add_child(lbl)
	$CenterBox.move_child(lbl, 2)

func _on_try_again_pressed() -> void:
	get_tree().paused = false
	RunManager.go_to_network()

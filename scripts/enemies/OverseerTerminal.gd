extends Node2D

var _breached := false

func _ready() -> void:
	add_to_group("hackable")

func on_breach(_player_node, _duration: float) -> void:
	if _breached:
		return
	_breached = true
	remove_from_group("hackable")
	$Visual.color = Color(0.25, 0.25, 0.25)
	$Label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	for boss in get_tree().get_nodes_in_group("boss"):
		if boss.has_method("on_terminal_breached"):
			boss.on_terminal_breached()
			break

extends Node2D

signal breached

var _active := true

func on_breach(_player: Node, _duration: float) -> void:
	if not _active:
		return
	_active = false
	breached.emit()
	$Visual.modulate = Color(0.2, 1.0, 0.5)

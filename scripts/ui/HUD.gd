extends CanvasLayer

const BAR_MAX_WIDTH := 200.0

@onready var health_fill: ColorRect = $Control/HealthBarFill
@onready var health_label: Label = $Control/HealthLabel
@onready var currency_label: Label = $Control/CurrencyLabel

var _player: Node = null

func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		var group := get_tree().get_nodes_in_group("player")
		if group.is_empty():
			return
		_player = group[0]

	var stats = _player.stats
	var pct := clampf(float(stats.current_health) / float(stats.max_health), 0.0, 1.0)
	health_fill.size.x = BAR_MAX_WIDTH * pct
	health_fill.color = _health_color(pct)
	health_label.text = "HEALTH   %d / %d" % [stats.current_health, stats.max_health]
	currency_label.text = "CR   %d" % stats.currency

func _health_color(pct: float) -> Color:
	if pct > 0.5:
		return Color(0.15, 0.85, 0.35)
	elif pct > 0.25:
		return Color(0.9, 0.75, 0.1)
	return Color(0.9, 0.2, 0.15)

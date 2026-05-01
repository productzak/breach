extends CanvasLayer

@onready var card_container: HBoxContainer = $Control/VBox/CardContainer
@onready var skip_btn: Button = $Control/VBox/SkipButton

var _deck_manager = null

func show_draft(dm) -> void:
	_deck_manager = dm
	_populate(dm.get_draft_pool(3))
	visible = true
	get_tree().paused = true

func _populate(cards: Array) -> void:
	for child in card_container.get_children():
		child.queue_free()
	for card in cards:
		card_container.add_child(_make_card_btn(card))

func _make_card_btn(card: HackCard) -> Button:
	var btn := Button.new()
	btn.process_mode = Node.PROCESS_MODE_ALWAYS
	btn.custom_minimum_size = Vector2(140, 180)
	btn.text = "%s\n\n%s\n\nCD: %.0fs" % [card.card_name, card.description, card.cooldown]
	btn.add_theme_font_size_override("font_size", 11)
	btn.pressed.connect(func(): _pick(card))
	return btn

func _pick(card: HackCard) -> void:
	_deck_manager.add_card(card)
	AudioManager.play("card_drafted")
	_close()

func _on_skip_pressed() -> void:
	_close()

func _close() -> void:
	get_tree().paused = false
	visible = false

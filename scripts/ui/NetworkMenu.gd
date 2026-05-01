extends Control

@onready var currency_lbl: Label = $VBox/Header/CurrencyLabel
@onready var last_run_lbl: Label = $VBox/LastRunLabel
@onready var grid: GridContainer = $VBox/UnlockGrid
@onready var start_btn: Button   = $VBox/Footer/StartButton

func _ready() -> void:
	_refresh_currency()
	_refresh_last_run()
	_build_grid()

func _refresh_currency() -> void:
	currency_lbl.text = "NET-CR  %d" % GameState.persistent_currency

func _refresh_last_run() -> void:
	if RunManager.floor_reached > 0:
		last_run_lbl.text = "LAST RUN  //  Floor %d  |  %d Enemies  |  %d CR Earned  |  +%d Net-CR" % [
			RunManager.floor_reached,
			RunManager.enemies_killed,
			RunManager.currency_earned_last_run,
			RunManager.persistent_awarded_last_run,
		]
	else:
		last_run_lbl.text = "No previous run data"

func _build_grid() -> void:
	for child in grid.get_children():
		child.queue_free()
	for unlock in UnlockDefs.ALL:
		grid.add_child(_make_unlock_tile(unlock))

func _make_unlock_tile(unlock: Dictionary) -> Control:
	var owned   := GameState.has_unlock(unlock.id)
	var cost    := unlock.cost as int
	var afford  := GameState.persistent_currency >= cost

	var panel  := Panel.new()
	panel.custom_minimum_size = Vector2(170, 120)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.08, 0.14, 0.95) if not owned else Color(0.06, 0.12, 0.08, 0.95)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg)

	var cat_lbl := Label.new()
	cat_lbl.text = "[%s]" % unlock.cat
	cat_lbl.add_theme_font_size_override("font_size", 8)
	cat_lbl.add_theme_color_override("font_color", Color(0.4, 0.6, 0.9, 0.8))
	cat_lbl.position = Vector2(6, 4)
	panel.add_child(cat_lbl)

	var name_lbl := Label.new()
	name_lbl.text = unlock.name
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_lbl.add_theme_color_override("font_color",
		Color(0.3, 1.0, 0.4) if owned else (Color.WHITE if afford else Color(0.5, 0.5, 0.5)))
	name_lbl.position = Vector2(6, 18)
	name_lbl.size     = Vector2(158, 18)
	panel.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = unlock.desc
	desc_lbl.add_theme_font_size_override("font_size", 9)
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	desc_lbl.position     = Vector2(6, 38)
	desc_lbl.size         = Vector2(158, 32)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(desc_lbl)

	if owned:
		var owned_lbl := Label.new()
		owned_lbl.text = "OWNED ✓"
		owned_lbl.add_theme_font_size_override("font_size", 10)
		owned_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4))
		owned_lbl.position = Vector2(6, 92)
		panel.add_child(owned_lbl)
	else:
		var btn := Button.new()
		btn.text = "BUY  %d" % cost
		btn.disabled = not afford
		btn.add_theme_font_size_override("font_size", 10)
		btn.position = Vector2(6, 86)
		btn.size     = Vector2(158, 26)
		btn.pressed.connect(func(): _on_buy(unlock.id, cost))
		panel.add_child(btn)

	return panel

func _on_buy(id: String, cost: int) -> void:
	if GameState.purchase_unlock(id, cost):
		_refresh_currency()
		_build_grid()

func _on_start_run_pressed() -> void:
	RunManager.start_run()

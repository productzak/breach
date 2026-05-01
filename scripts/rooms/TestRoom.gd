extends Node2D

@export var player_scene: PackedScene
@export var drone_scene: PackedScene
@export var security_bot_scene: PackedScene
@export var gang_member_scene: PackedScene

const ROOM_W := 1280
const ROOM_H := 720
const BORDER := 64

@onready var nav_region: NavigationRegion2D = $NavigationRegion2D
@onready var death_screen = $DeathScreen
@onready var draft_screen = $DraftScreen

var _player_ref: Node = null
var _enemies_spawned := false
var _room_cleared := false
var _clear_check_delay := 2.0

func _ready() -> void:
	_setup_navigation()
	_build_geometry()
	_spawn_entities()

func _process(delta: float) -> void:
	if _room_cleared or not _enemies_spawned:
		return
	if _clear_check_delay > 0.0:
		_clear_check_delay -= delta
		return
	if get_tree().get_nodes_in_group("enemies").is_empty():
		_room_cleared = true
		if is_instance_valid(_player_ref):
			draft_screen.show_draft(_player_ref.get_node("DeckManager"))

func _setup_navigation() -> void:
	var nav_poly := NavigationPolygon.new()
	nav_poly.add_outline(PackedVector2Array([
		Vector2(BORDER, BORDER),
		Vector2(ROOM_W - BORDER, BORDER),
		Vector2(ROOM_W - BORDER, ROOM_H - BORDER),
		Vector2(BORDER, ROOM_H - BORDER),
	]))
	nav_poly.make_polygons_from_outlines()
	nav_region.navigation_polygon = nav_poly

func _build_geometry() -> void:
	var floor_vis := Polygon2D.new()
	floor_vis.polygon = PackedVector2Array([
		Vector2(BORDER, BORDER),
		Vector2(ROOM_W - BORDER, BORDER),
		Vector2(ROOM_W - BORDER, ROOM_H - BORDER),
		Vector2(BORDER, ROOM_H - BORDER),
	])
	floor_vis.color = Color(0.06, 0.06, 0.10)
	add_child(floor_vis)
	move_child(floor_vis, 0)

	_add_wall(Vector2(ROOM_W * 0.5, BORDER * 0.5),                Vector2(ROOM_W, BORDER))
	_add_wall(Vector2(ROOM_W * 0.5, ROOM_H - BORDER * 0.5),       Vector2(ROOM_W, BORDER))
	_add_wall(Vector2(BORDER * 0.5, ROOM_H * 0.5),                 Vector2(BORDER, ROOM_H))
	_add_wall(Vector2(ROOM_W - BORDER * 0.5, ROOM_H * 0.5),       Vector2(BORDER, ROOM_H))

func _add_wall(pos: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos

	var cshape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	cshape.shape = rect
	body.add_child(cshape)

	var vis := Polygon2D.new()
	var hw := size.x * 0.5
	var hh := size.y * 0.5
	vis.polygon = PackedVector2Array([
		Vector2(-hw, -hh), Vector2(hw, -hh),
		Vector2(hw, hh),   Vector2(-hw, hh),
	])
	vis.color = Color(0.13, 0.13, 0.20)
	body.add_child(vis)

	add_child(body)

func _spawn_entities() -> void:
	if player_scene:
		var p := player_scene.instantiate()
		p.position = Vector2(200, 360)
		p.died.connect(death_screen.show_death)
		add_child(p)
		_player_ref = p

	if drone_scene:
		for pos: Vector2 in [Vector2(950, 220), Vector2(1080, 420), Vector2(840, 560)]:
			var d := drone_scene.instantiate()
			d.position = pos
			add_child(d)

	if security_bot_scene:
		for pos: Vector2 in [Vector2(700, 180), Vector2(1100, 560)]:
			var b := security_bot_scene.instantiate()
			b.position = pos
			add_child(b)

	if gang_member_scene:
		for pos: Vector2 in [Vector2(600, 500), Vector2(750, 300), Vector2(1000, 300)]:
			var g := gang_member_scene.instantiate()
			g.position = pos
			add_child(g)

	_enemies_spawned = true

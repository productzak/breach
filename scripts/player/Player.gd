extends CharacterBody2D

signal died

@export var move_speed: float = 220.0
@export var fire_rate: float = 0.12
@export var melee_range: float = 60.0
@export var melee_damage: int = 25
@export var melee_cooldown: float = 0.5
@export var bullet_scene: PackedScene
@export var stats: PlayerStats

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var gun_pivot: Node2D = $GunPivot
@onready var fire_timer: Timer = $FireTimer
@onready var melee_timer: Timer = $MeleeTimer
@onready var muzzle: Marker2D = $GunPivot/Muzzle
@onready var deck_manager = $DeckManager

var can_fire: bool = true
var can_melee: bool = true
var invincible: bool = false
var _attacking := false

func _ready() -> void:
	add_to_group("player")
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	if stats == null:
		stats = PlayerStats.new()

func _unhandled_input(event: InputEvent) -> void:
	# Right-click always cancels card selection
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_RIGHT \
			and event.pressed:
		deck_manager.cancel_selection()
		return

	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if event.pressed:
		# Targeting mode: card click activates the selected card
		if deck_manager.selected_card != null:
			var target := _enemy_at(get_global_mouse_position())
			deck_manager.play_selected(get_global_mouse_position(), target)
			return

		# Normal: move or attack
		var enemy := _enemy_at(get_global_mouse_position())
		if enemy:
			var dist := global_position.distance_to(enemy.global_position)
			if dist <= melee_range:
				_melee_attack(enemy)
				_attacking = false
			else:
				_attacking = true
		else:
			_attacking = false
			nav_agent.target_position = get_global_mouse_position()
	else:
		_attacking = false

func _process(_delta: float) -> void:
	gun_pivot.look_at(get_global_mouse_position())

	if deck_manager.selected_card != null:
		Input.set_default_cursor_shape(Input.CURSOR_CROSS)
		return
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if _attacking and can_fire:
			_fire()
		elif not _attacking:
			nav_agent.target_position = get_global_mouse_position()

func _enemy_at(world_pos: Vector2) -> Node2D:
	var q := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 20.0
	q.shape = circle
	q.transform = Transform2D(0, world_pos)
	q.collision_mask = 4
	var hits := get_world_2d().direct_space_state.intersect_shape(q)
	return hits[0].collider if hits.size() > 0 else null

func _physics_process(_delta: float) -> void:
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
	else:
		var next := nav_agent.get_next_path_position()
		velocity = (next - global_position).normalized() * move_speed
	move_and_slide()

func _fire() -> void:
	if bullet_scene == null:
		return
	can_fire = false
	fire_timer.start(fire_rate)
	var bullet := bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	bullet.direction = (get_global_mouse_position() - muzzle.global_position).normalized()

func _melee_attack(target: Node2D) -> void:
	if not can_melee:
		return
	can_melee = false
	melee_timer.start(melee_cooldown)
	if target.has_method("take_damage"):
		target.take_damage(melee_damage)

func _on_fire_timer_timeout() -> void:
	can_fire = true

func _on_melee_timer_timeout() -> void:
	can_melee = true

func take_damage(amount: int) -> void:
	if invincible:
		return
	stats.current_health -= amount
	if stats.current_health <= 0:
		stats.current_health = 0
		died.emit()
		queue_free()

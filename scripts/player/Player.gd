extends CharacterBody2D

@export var move_speed: float = 220.0
@export var fire_rate: float = 0.12
@export var bullet_scene: PackedScene
@export var stats: PlayerStats

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var gun_pivot: Node2D = $GunPivot
@onready var fire_timer: Timer = $FireTimer
@onready var muzzle: Marker2D = $GunPivot/Muzzle

var can_fire: bool = true

func _ready() -> void:
	add_to_group("player")
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	if stats == null:
		stats = PlayerStats.new()

func _process(_delta: float) -> void:
	gun_pivot.look_at(get_global_mouse_position())
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		nav_agent.target_position = get_global_mouse_position()
		if can_fire:
			_fire()

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

func _on_fire_timer_timeout() -> void:
	can_fire = true

func take_damage(amount: int) -> void:
	stats.current_health -= amount
	if stats.current_health <= 0:
		stats.current_health = 0
		queue_free()

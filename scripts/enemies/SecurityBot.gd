extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK }

@export var move_speed: float = 80.0
@export var health: int = 80
@export var detection_radius: float = 350.0
@export var attack_range: float = 280.0
@export var shoot_rate: float = 1.8
@export var bullet_damage: int = 12
@export var bullet_scene: PackedScene

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var gun_pivot: Node2D = $GunPivot

var state: State = State.IDLE
var player: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	shoot_timer.wait_time = shoot_rate
	shoot_timer.one_shot = true

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		state = State.CHASE

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = null
		state = State.IDLE

	match state:
		State.IDLE:
			_scan_for_player()
			velocity = Vector2.ZERO
		State.CHASE:
			_do_chase()
		State.ATTACK:
			_do_attack()

	move_and_slide()

func _scan_for_player() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(p.global_position) <= detection_radius:
			player = p
			state = State.CHASE
			break

func _do_chase() -> void:
	var dist := global_position.distance_to(player.global_position)
	if dist <= attack_range:
		velocity = Vector2.ZERO
		state = State.ATTACK
		return
	nav_agent.target_position = player.global_position
	if not nav_agent.is_navigation_finished():
		velocity = (nav_agent.get_next_path_position() - global_position).normalized() * move_speed
	else:
		velocity = Vector2.ZERO

func _do_attack() -> void:
	var dist := global_position.distance_to(player.global_position)
	if dist > attack_range:
		state = State.CHASE
		return
	velocity = Vector2.ZERO
	gun_pivot.look_at(player.global_position)
	if shoot_timer.is_stopped():
		shoot_timer.start()

func _on_shoot_timer_timeout() -> void:
	if state != State.ATTACK or not is_instance_valid(player):
		return
	_shoot()
	shoot_timer.start()

func _shoot() -> void:
	if bullet_scene == null:
		return
	var bullet := bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	bullet.direction = (player.global_position - global_position).normalized()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()

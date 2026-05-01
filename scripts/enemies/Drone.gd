extends CharacterBody2D

@export var move_speed: float = 110.0
@export var detection_radius: float = 320.0
@export var attack_range: float = 160.0
@export var attack_damage: int = 8
@export var health: int = 30

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var attack_timer: Timer = $AttackTimer

var player: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	attack_timer.wait_time = 1.0
	attack_timer.one_shot = true

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body

func _physics_process(_delta: float) -> void:
	if player == null:
		_scan_for_player()
		return

	var dist := global_position.distance_to(player.global_position)

	if dist <= attack_range:
		velocity = Vector2.ZERO
		if attack_timer.is_stopped():
			attack_timer.start()
	else:
		nav_agent.target_position = player.global_position
		if not nav_agent.is_navigation_finished():
			var next := nav_agent.get_next_path_position()
			velocity = (next - global_position).normalized() * move_speed
		else:
			velocity = Vector2.ZERO

	move_and_slide()

func _scan_for_player() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(p.global_position) <= detection_radius:
			player = p
			break

func _on_attack_timer_timeout() -> void:
	if player == null:
		return
	if global_position.distance_to(player.global_position) <= attack_range:
		player.take_damage(attack_damage)
		attack_timer.start()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		queue_free()

extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK }

@export var move_speed: float = 80.0
@export var health: int = 80
@export var detection_radius: float = 350.0
@export var attack_range: float = 280.0
@export var shoot_rate: float = 1.8
@export var bullet_damage: int = 12
@export var bullet_scene: PackedScene
@export var patrol_radius: float = 80.0
@export var currency_drop: int = 15

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var shoot_timer: Timer = $ShootTimer
@onready var patrol_timer: Timer = $PatrolTimer
@onready var gun_pivot: Node2D = $GunPivot

var state: State = State.IDLE
var player: Node2D = null
var spawn_pos: Vector2
var _stunned := false
var _redirected := false

func _ready() -> void:
	add_to_group("enemies")
	spawn_pos = global_position
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0
	shoot_timer.wait_time = shoot_rate
	shoot_timer.one_shot = true
	patrol_timer.one_shot = true
	call_deferred("_pick_patrol_point")

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body
		state = State.CHASE

func _physics_process(_delta: float) -> void:
	if _stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_instance_valid(player):
		player = null
		state = State.IDLE

	match state:
		State.IDLE:   _do_idle()
		State.CHASE:  _do_chase()
		State.ATTACK: _do_attack()

	move_and_slide()

func _do_idle() -> void:
	_scan_for_player()
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		if patrol_timer.is_stopped():
			patrol_timer.start(randf_range(1.5, 3.5))
	else:
		var next := nav_agent.get_next_path_position()
		velocity = (next - global_position).normalized() * (move_speed * 0.4)

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

func _scan_for_player() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(p.global_position) <= detection_radius:
			player = p
			state = State.CHASE
			break

func _pick_patrol_point() -> void:
	var angle := randf_range(0.0, TAU)
	var dist := randf_range(30.0, patrol_radius)
	nav_agent.target_position = spawn_pos + Vector2(cos(angle), sin(angle)) * dist

func _on_patrol_timer_timeout() -> void:
	_pick_patrol_point()

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

func stun(duration: float) -> void:
	_stunned = true
	$Visual.modulate = Color(0.85, 0.85, 1.0, 0.65)
	var t := create_tween()
	t.tween_interval(duration)
	t.tween_callback(func(): _stunned = false; $Visual.modulate = Color.WHITE)

func redirect(duration: float) -> void:
	if _redirected:
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	enemies.erase(self)
	if enemies.is_empty():
		return
	_redirected = true
	var old_player := player
	player = enemies.pick_random()
	state = State.CHASE
	$Visual.modulate = Color(1.5, 0.5, 1.5)
	var t := create_tween()
	t.tween_interval(duration)
	t.tween_callback(func():
		_redirected = false
		player = old_player if is_instance_valid(old_player) else null
		state = State.IDLE if player == null else State.CHASE
		$Visual.modulate = Color.WHITE
	)

func ping(duration: float) -> void:
	var orig := $Visual.modulate
	$Visual.modulate = Color(2.0, 2.0, 0.5)
	get_tree().create_timer(duration).timeout.connect(func(): $Visual.modulate = orig)

func take_damage(amount: int) -> void:
	AudioManager.play("enemy_hurt")
	_flash_hit()
	_spawn_damage_number(amount)
	health -= amount
	if health <= 0:
		_drop_currency()
		_spawn_death_effect()
		queue_free()

func _flash_hit() -> void:
	$Visual.modulate = Color(2.2, 2.2, 2.2)
	var t := create_tween()
	t.tween_property($Visual, "modulate", Color.WHITE, 0.11)

func _spawn_damage_number(amount: int) -> void:
	var dn := load("res://scripts/effects/DamageNumber.gd").new()
	get_tree().current_scene.add_child(dn)
	dn.global_position = global_position + Vector2(0.0, -16.0)
	dn.setup(amount)

func _drop_currency() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0].get("stats") != null:
		players[0].stats.currency += currency_drop
		if currency_drop > 0:
			var fx := load("res://scripts/effects/CurrencySparkle.gd").new()
			fx.global_position = global_position
			get_tree().current_scene.add_child(fx)

func _spawn_death_effect() -> void:
	AudioManager.play("enemy_death")
	var fx := load("res://scenes/effects/DeathEffect.tscn").instantiate()
	fx.base_color = $Visual.color
	fx.global_position = global_position
	get_tree().current_scene.add_child(fx)
	_camera_shake(3.5, 0.14)

func _camera_shake(strength: float, duration: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0].has_method("camera_shake"):
		players[0].camera_shake(strength, duration)

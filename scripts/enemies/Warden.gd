extends CharacterBody2D

@export var health: int = 600
@export var max_health: int = 600
@export var boss_name: String = "WARDEN"
@export var move_speed: float = 95.0
@export var bullet_scene: PackedScene
@export var currency_drop: int = 0

const SHIELD_ROTATION_SPEED := 1.8
const CHARGE_SPEED := 380.0
const CHARGE_DURATION := 0.6
const CHARGE_COOLDOWN := 5.0
const TURRET_HP_THRESHOLD := 0.5

var _turrets_deployed := false
var _charge_cooldown := CHARGE_COOLDOWN
var _charge_timer := 0.0
var _charging := false
var _charge_dir := Vector2.ZERO
var _player: Node2D = null
var _stunned := false

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var shield_arm: Node2D = $ShieldArm
@onready var shoot_timer: Timer = $ShootTimer

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	shoot_timer.wait_time = 1.4
	shoot_timer.one_shot = true

func get_phase_name() -> String:
	if float(health) / float(max_health) <= TURRET_HP_THRESHOLD:
		return "PHASE II — ARMED"
	return "PHASE I — SHIELDED"

func _physics_process(delta: float) -> void:
	shield_arm.rotation += SHIELD_ROTATION_SPEED * delta

	if _stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_find_player()
	if _player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if float(health) / float(max_health) <= TURRET_HP_THRESHOLD and not _turrets_deployed:
		_turrets_deployed = true
		_deploy_turrets()

	if _charging:
		_do_charge(delta)
	else:
		_do_normal(delta)

	move_and_slide()

func _find_player() -> void:
	if is_instance_valid(_player):
		return
	var ps := get_tree().get_nodes_in_group("player")
	if ps.size() > 0:
		_player = ps[0]

func _do_normal(delta: float) -> void:
	_charge_cooldown -= delta
	nav_agent.target_position = _player.global_position
	if not nav_agent.is_navigation_finished():
		velocity = (nav_agent.get_next_path_position() - global_position).normalized() * move_speed
	else:
		velocity = Vector2.ZERO

	if _charge_cooldown <= 0.0 and global_position.distance_to(_player.global_position) < 450.0:
		_start_charge()

	if shoot_timer.is_stopped() and bullet_scene != null:
		shoot_timer.start()

func _start_charge() -> void:
	_charging = true
	var target := _player.global_position if is_instance_valid(_player) else global_position
	_charge_dir = (target - global_position).normalized()
	_charge_timer = CHARGE_DURATION
	_charge_cooldown = CHARGE_COOLDOWN
	$Visual.modulate = Color(1.0, 0.3, 0.15)

func _do_charge(delta: float) -> void:
	_charge_timer -= delta
	velocity = _charge_dir * CHARGE_SPEED
	if _charge_timer <= 0.0:
		_charging = false
		$Visual.modulate = Color.WHITE

func _deploy_turrets() -> void:
	var turret_scene := load("res://scenes/enemies/Turret.tscn") as PackedScene
	if turret_scene == null:
		return
	var offsets := [Vector2(-280, -180), Vector2(-280, 180)]
	for offset in offsets:
		var t := turret_scene.instantiate()
		t.global_position = global_position + offset
		if bullet_scene:
			t.bullet_scene = bullet_scene
		get_tree().current_scene.add_child(t)

func stun(duration: float) -> void:
	_stunned = true
	$Visual.modulate = Color(0.5, 0.5, 1.0)
	var tw := create_tween()
	tw.tween_interval(duration)
	tw.tween_callback(func(): _stunned = false; $Visual.modulate = Color.WHITE)

func ping(duration: float) -> void:
	var orig := $Visual.modulate
	$Visual.modulate = Color(2.0, 2.0, 0.5)
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(self): $Visual.modulate = orig)

func redirect(_duration: float) -> void:
	pass

func _on_shoot_timer_timeout() -> void:
	if bullet_scene == null or not is_instance_valid(_player):
		return
	_shoot()
	shoot_timer.start()

func _shoot() -> void:
	var target := _player.global_position if is_instance_valid(_player) else global_position + Vector2.RIGHT
	var b := bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = global_position
	b.direction = (target - global_position).normalized()

func _on_shield_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
	body.queue_free()

func take_damage(amount: int) -> void:
	health -= amount
	health = max(0, health)
	if health <= 0:
		_drop_currency()
		_spawn_death_effects()
		queue_free()

func _drop_currency() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0].get("stats") != null:
		players[0].stats.currency += currency_drop

func _spawn_death_effects() -> void:
	for i in 4:
		var fx := load("res://scenes/effects/DeathEffect.tscn").instantiate()
		fx.base_color = Color(0.9, 0.4, 0.1)
		fx.global_position = global_position + Vector2(randf_range(-40.0, 40.0), randf_range(-40.0, 40.0))
		get_tree().current_scene.add_child(fx)

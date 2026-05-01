extends CharacterBody2D

@export var health: int = 900
@export var max_health: int = 900
@export var boss_name: String = "OVERSEER"
@export var bullet_scene: PackedScene

const PHASE2_FRAC := 0.66
const PHASE3_FRAC := 0.33

var _phase := 1
var _stunned := false
var _double_damage := false
var _spawn_timer := 0.0
var _spawn_interval := 8.0
var _cards_locked := false
var _terminals_breached := 0
var _player: Node2D = null
var _dm = null

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var shoot_timer: Timer = $ShootTimer

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	shoot_timer.wait_time = 1.2
	shoot_timer.one_shot = true
	_spawn_timer = 3.0

func get_phase_name() -> String:
	match _phase:
		1: return "PHASE I — CONTAINMENT"
		2: return "PHASE II — LOCKDOWN"
		3: return "PHASE III — PURGE"
	return ""

func _physics_process(delta: float) -> void:
	if _stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_find_player()
	if _player == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_check_phase_transitions()

	nav_agent.target_position = _player.global_position
	if not nav_agent.is_navigation_finished():
		velocity = (nav_agent.get_next_path_position() - global_position).normalized() * _get_speed()
	else:
		velocity = Vector2.ZERO

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = _spawn_interval
		_spawn_minions()

	move_and_slide()

func _get_speed() -> float:
	match _phase:
		1: return 70.0
		2: return 95.0
		3: return 130.0
	return 70.0

func _find_player() -> void:
	if is_instance_valid(_player):
		return
	var ps := get_tree().get_nodes_in_group("player")
	if ps.size() > 0:
		_player = ps[0]
		_dm = _player.get_node_or_null("DeckManager")

func _check_phase_transitions() -> void:
	var frac := float(health) / float(max_health)
	if frac <= PHASE3_FRAC and _phase < 3:
		_enter_phase(3)
	elif frac <= PHASE2_FRAC and _phase < 2:
		_enter_phase(2)

func _enter_phase(p: int) -> void:
	AudioManager.play("boss_phase_change")
	_phase = p
	match p:
		2:
			_spawn_interval = 5.0
			_spawn_timer = 0.5
			shoot_timer.wait_time = 0.9
			if _dm != null and _dm.has_method("lock_cards"):
				_cards_locked = true
				_dm.lock_cards(INF)
			$Visual.modulate = Color(1.0, 0.5, 1.0)
		3:
			_spawn_interval = 3.0
			_spawn_timer = 0.5
			shoot_timer.wait_time = 0.7
			if _cards_locked and _dm != null and _dm.has_method("unlock_cards"):
				_dm.unlock_cards()
				_cards_locked = false
			$Visual.modulate = Color(1.0, 0.15, 0.15)

func _spawn_minions() -> void:
	match _phase:
		1, 2:
			var drone_scene := load("res://scenes/enemies/Drone.tscn") as PackedScene
			for _i in randi_range(1, 2):
				var d := drone_scene.instantiate()
				var angle := randf_range(0.0, TAU)
				d.global_position = global_position + Vector2(cos(angle), sin(angle)) * 130.0
				get_tree().current_scene.add_child(d)
		3:
			var guard_scene := load("res://scenes/enemies/CorpoGuard.tscn") as PackedScene
			for _i in randi_range(1, 2):
				var g := guard_scene.instantiate()
				var angle := randf_range(0.0, TAU)
				g.global_position = global_position + Vector2(cos(angle), sin(angle)) * 130.0
				get_tree().current_scene.add_child(g)

func on_terminal_breached() -> void:
	_terminals_breached += 1
	if _terminals_breached >= 3:
		_terminals_breached = 0
		_trigger_breach_stun()

func _trigger_breach_stun() -> void:
	_stunned = true
	_double_damage = true
	var orig_color := $Visual.modulate
	$Visual.modulate = Color(0.3, 0.3, 1.0)
	var tw := create_tween()
	tw.tween_interval(3.0)
	tw.tween_callback(func():
		_stunned = false
		_double_damage = false
		$Visual.modulate = orig_color
	)

func stun(duration: float) -> void:
	_stunned = true
	var orig := $Visual.modulate
	$Visual.modulate = Color(0.5, 0.5, 1.0)
	var tw := create_tween()
	tw.tween_interval(duration)
	tw.tween_callback(func(): _stunned = false; $Visual.modulate = orig)

func ping(duration: float) -> void:
	var orig := $Visual.modulate
	$Visual.modulate = Color(2.0, 2.0, 0.5)
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(self): $Visual.modulate = orig)

func redirect(_duration: float) -> void:
	pass

func _on_shoot_timer_timeout() -> void:
	if not is_instance_valid(_player):
		return
	_shoot()
	shoot_timer.start()

func _shoot() -> void:
	if bullet_scene == null:
		return
	var dir := (_player.global_position - global_position).normalized()
	_fire_bullet(dir)
	if _phase >= 3:
		_fire_bullet(dir.rotated(-0.3))
		_fire_bullet(dir.rotated(0.3))

func _fire_bullet(dir: Vector2) -> void:
	var b := bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = global_position
	b.direction = dir

func take_damage(amount: int) -> void:
	var actual := amount * 2 if _double_damage else amount
	AudioManager.play("enemy_hurt")
	_flash_hit()
	_spawn_damage_number(actual)
	health -= actual
	health = max(0, health)
	if health <= 0:
		_on_death()

func _flash_hit() -> void:
	$Visual.modulate = Color(2.2, 2.2, 2.2)
	var t := create_tween()
	t.tween_property($Visual, "modulate", Color.WHITE if _phase == 1 else
		(Color(1.0, 0.5, 1.0) if _phase == 2 else Color(1.0, 0.15, 0.15)), 0.14)

func _spawn_damage_number(amount: int) -> void:
	var dn := load("res://scripts/effects/DamageNumber.gd").new()
	get_tree().current_scene.add_child(dn)
	dn.global_position = global_position + Vector2(0.0, -26.0)
	dn.setup(amount)

func _on_death() -> void:
	AudioManager.play("enemy_death")
	if _cards_locked and _dm != null and _dm.has_method("unlock_cards"):
		_dm.unlock_cards()
	for i in 6:
		var fx := load("res://scenes/effects/DeathEffect.tscn").instantiate()
		fx.base_color = Color(0.85, 0.15, 0.85)
		fx.global_position = global_position + Vector2(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0))
		get_tree().current_scene.add_child(fx)
	_camera_shake(9.0, 0.45)
	queue_free()

func _camera_shake(strength: float, duration: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0].has_method("camera_shake"):
		players[0].camera_shake(strength, duration)

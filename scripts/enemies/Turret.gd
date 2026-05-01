extends StaticBody2D

@export var health: int = 60
@export var shoot_rate: float = 2.0
@export var bullet_damage: int = 14
@export var detection_radius: float = 400.0
@export var currency_drop: int = 10
@export var bullet_scene: PackedScene

@onready var gun_pivot: Node2D = $GunPivot
@onready var shoot_timer: Timer = $ShootTimer

var _player: Node2D = null
var _disabled := false

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("hackable")
	shoot_timer.wait_time = shoot_rate
	shoot_timer.one_shot = true

func _process(_delta: float) -> void:
	if _disabled:
		return
	_scan_for_player()
	if not is_instance_valid(_player):
		_player = null
		return
	gun_pivot.look_at(_player.global_position)
	if shoot_timer.is_stopped():
		shoot_timer.start()

func _scan_for_player() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if global_position.distance_to(p.global_position) <= detection_radius:
			_player = p
			return
	_player = null

func _on_shoot_timer_timeout() -> void:
	if _disabled or not is_instance_valid(_player):
		return
	_shoot()
	shoot_timer.start()

func _shoot() -> void:
	if bullet_scene == null or not is_instance_valid(_player):
		return
	var b := bullet_scene.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = global_position
	b.direction = (_player.global_position - global_position).normalized()

func on_breach(_player_node, duration: float) -> void:
	_disabled = true
	$Visual.modulate = Color(0.3, 0.3, 0.3, 0.6)
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(self):
			_disabled = false
			$Visual.modulate = Color.WHITE
	)

func stun(duration: float) -> void:
	on_breach(null, duration)

func ping(duration: float) -> void:
	$Visual.modulate = Color(2.0, 2.0, 0.5)
	get_tree().create_timer(duration).timeout.connect(func():
		if is_instance_valid(self): $Visual.modulate = Color.WHITE)

func redirect(_duration: float) -> void:
	pass

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

func _spawn_death_effect() -> void:
	AudioManager.play("enemy_death")
	var fx := load("res://scenes/effects/DeathEffect.tscn").instantiate()
	fx.base_color = $Visual.color
	fx.global_position = global_position
	get_tree().current_scene.add_child(fx)
	_camera_shake(2.5, 0.10)

func _camera_shake(strength: float, duration: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty() and players[0].has_method("camera_shake"):
		players[0].camera_shake(strength, duration)

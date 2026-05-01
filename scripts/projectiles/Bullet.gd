extends CharacterBody2D

@export var speed: float = 650.0
@export var damage: int = 15
@export var trail_color: Color = Color(0.1, 1.0, 0.88)
@export var emit_trail: bool = true

var direction: Vector2 = Vector2.RIGHT
var _trail_t := 0.0

func _ready() -> void:
	get_tree().create_timer(2.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	if emit_trail:
		_trail_t += delta
		if _trail_t >= 0.035:
			_trail_t = 0.0
			_spawn_trail()

	velocity = direction * speed
	var collision := move_and_collide(velocity * delta)
	if collision:
		var collider := collision.get_collider()
		if collider != null and collider.has_method("take_damage"):
			collider.take_damage(damage)
		queue_free()

func _spawn_trail() -> void:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([-3.5, -1.5, 3.5, -1.5, 3.5, 1.5, -3.5, 1.5])
	p.color = trail_color
	p.global_position = global_position
	get_tree().current_scene.add_child(p)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(p, "scale", Vector2(0.05, 0.05), 0.14)
	t.tween_property(p, "modulate:a", 0.0, 0.14)
	get_tree().create_timer(0.15).timeout.connect(p.queue_free)

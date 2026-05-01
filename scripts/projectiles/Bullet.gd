extends CharacterBody2D

@export var speed: float = 650.0
@export var damage: int = 15

var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	get_tree().create_timer(2.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	velocity = direction * speed
	var collision := move_and_collide(velocity * delta)
	if collision:
		var collider := collision.get_collider()
		if collider != null and collider.has_method("take_damage"):
			collider.take_damage(damage)
		queue_free()

extends Area2D

@export var SPEED := 200
var direction := 1

func _physics_process(delta):
	position.x += direction * SPEED * delta

func set_direction(dir: int):
	direction = dir
	scale.x = dir

func _on_area_entered(area: Area2D) -> void:
	var enemy = area.owner   

	if enemy != null and enemy.has_method("go_to_dead_state"):
		enemy.go_to_dead_state()

	queue_free()

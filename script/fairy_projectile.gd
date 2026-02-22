extends Area2D

@export var SPEED := 250
var direction := 1

func _ready() -> void:
	pass 



func _process(delta: float) -> void:
	position.x += direction * SPEED * delta

func set_direction(dir: int):
	direction = dir
	scale.x = dir
		


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damge"):
			body.take_damage(global_position.x)
		queue_free()	

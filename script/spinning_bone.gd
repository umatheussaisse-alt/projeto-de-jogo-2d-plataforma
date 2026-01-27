extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var SPEED = 60
var direction = 1

func _ready():
	add_to_group("enemy_attack")
func _process(delta: float) -> void:
	position.x += SPEED * delta * direction

func set_direction(skl_direction):
	direction = skl_direction
	anim.flip_h = direction < 0	
	

func _on_self_destruct_timer_timeout() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(global_position.x)
	queue_free()
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_spell"):
		return
	queue_free()

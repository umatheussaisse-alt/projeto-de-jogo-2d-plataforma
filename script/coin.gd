extends Area2D
@onready var coin_sfx: AudioStreamPlayer = $coin_sfx
@onready var anim: AnimatedSprite2D = $anim
var coins := 1
# C
func _ready() -> void:
	pass 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_body_entered(_body: Node2D) -> void:
	anim.play("colect")
	coin_sfx.play()
	#evita colisao dupla
	await $CollisionShape2D.call_deferred("queue_free")
	Globals.coins += coins

func _on_anim_animation_finished() -> void:
	queue_free()

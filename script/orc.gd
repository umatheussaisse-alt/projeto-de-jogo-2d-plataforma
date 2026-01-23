extends CharacterBody2D

enum orc_state {
	walk,
	attack,
	dead
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@onready var wall_detector: RayCast2D = $wall_detector
@onready var ground_detector: RayCast2D = $ground_detector
@onready var player_detector: RayCast2D = $player_detector
@onready var hitbox_spear: Area2D = $hitbox_spear

const SPEED = 21.0

var status: orc_state
var direction := -1

var spear_normal_x := 0.0
var spear_attack_x := 0.0

func _ready() -> void:
	spear_normal_x = hitbox_spear.position.x
	spear_attack_x = spear_normal_x + 15
	hitbox_spear.monitoring = false
	go_to_walk_state()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		orc_state.walk:
			walk_state(delta)
		orc_state.attack:
			attack_state(delta)
		orc_state.dead:
			dead_state(delta)

	move_and_slide()



func go_to_walk_state():
	status = orc_state.walk
	anim.play("walk")
	hitbox_spear.monitoring = false
	hitbox_spear.position.x = spear_normal_x * direction

func go_to_attack_state():
	status = orc_state.attack
	anim.play("attack")
	velocity = Vector2.ZERO

func go_to_dead_state():
	status = orc_state.dead
	anim.play("dead")
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO



func walk_state(_delta):
	velocity.x = SPEED * direction

	if wall_detector.is_colliding() or not ground_detector.is_colliding():
		scale.x *= -1
		direction *= -1
		hitbox_spear.position.x = spear_normal_x * direction

	if player_detector.is_colliding():
		go_to_attack_state()

func attack_state(_delta):
	velocity = Vector2.ZERO

	if anim.frame == 2:
		hitbox_spear.position.x = spear_attack_x * direction
		hitbox_spear.monitoring = true
	else:
		hitbox_spear.monitoring = false

func dead_state(_delta):
	pass

func take_damage():
	go_to_dead_state()


func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "attack":
		go_to_walk_state()

func _on_hitbox_spear_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.go_to_hurt_state()

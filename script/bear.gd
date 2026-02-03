extends CharacterBody2D

enum bear_state{
	idle,
	walk,
	attack,
	dead
}


#vars globais
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@onready var wall_detector: RayCast2D = $hitbox/wall_detector
@onready var ground_detector: RayCast2D = $hitbox/ground_detector
@onready var player_detector: RayCast2D = $hitbox/player_detector
@onready var attack_area: Area2D = $hitbox/attack_area
@onready var attack_shape: CollisionShape2D = $hitbox/attack_area/attack_shape
@onready var walking_sfx: AudioStreamPlayer = $walking_sfx
@onready var attack_sfx: AudioStreamPlayer = $attack_sfx



var SPEED := 20
var status : bear_state
var direction := -1

func _ready() -> void:
	attack_shape.disabled = true
	go_to_walk_state()
	
func _physics_process(delta: float) -> void:
	if status == bear_state.dead:
		return
	
	if not is_on_floor():
		velocity += get_gravity() * delta
			
	match status:
		bear_state.idle:
			idle_state(delta)
		bear_state.walk:
			walk_state(delta)
		bear_state.attack:
			attack_state(delta)	
		bear_state.dead:
			dead_state(delta)
	move_and_slide()
	
func go_to_walk_state():
	if status == bear_state.dead:
		return
	if status == bear_state.walk:
		return

	status = bear_state.walk
	anim.play("walk")
	if not walking_sfx.playing:
		walking_sfx.play()

func go_to_idle_state():
	pass

func go_to_attack_state():
	if status == bear_state.dead or status == bear_state.attack:
		return

	status = bear_state.attack
	anim.play("attack")
	velocity = Vector2.ZERO
	
	walking_sfx.stop()
	attack_sfx.play()
	
func go_to_dead_state():
	if status == bear_state.dead:
		return
	
	status = bear_state.dead
	velocity = Vector2.ZERO
	anim.play("dead")

	walking_sfx.stop()
	attack_sfx.stop()

	attack_shape.set_deferred("disabled", true)
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED


	



func idle_state(delta):
	pass

func walk_state(_delta):
	if status == bear_state.dead:
		return
	velocity.x = SPEED * direction

	if wall_detector.is_colliding() or not ground_detector.is_colliding():
		scale.x *= -1
		direction *= -1

	if player_detector.is_colliding():
		go_to_attack_state()

func attack_state(_delta):
	velocity = Vector2.ZERO

	if anim.frame == 2:
		if not attack_sfx.playing:
			attack_sfx.play()
		attack_shape.disabled = false
	else:
		attack_shape.disabled = true



func dead_state(_delta):
	velocity = Vector2.ZERO

func take_damage():
	go_to_dead_state()

func _on_animated_sprite_2d_animation_finished() -> void:
	if status == bear_state.dead:
		return

	if anim.animation == "attack":
		go_to_walk_state()

			
	
func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(global_position.x)

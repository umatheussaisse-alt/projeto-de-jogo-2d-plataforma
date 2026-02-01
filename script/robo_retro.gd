extends CharacterBody2D

enum roboretro_state {
	idle,
	walk,
	spin_attack,
	flight_start,
	flight_patrol,
	flight_end,
	dead
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@onready var wall_detector: RayCast2D = $hitbox/wall_detector
@onready var ground_detector: RayCast2D = $hitbox/ground_detector
@onready var player_detector: RayCast2D = $hitbox/player_detector

const SPEED := 21.0

var status: roboretro_state
var direction := -1
@export var fly_speed := 60.0
@export var fly_limit_left := -120.0
@export var fly_limit_right := 120.0

var fly_origin_x := 0.0


func _ready() -> void:
	go_to_walk_state()


func _physics_process(delta: float) -> void:
	if status == roboretro_state.dead:
		return
	if status not in [
		roboretro_state.flight_start,
		roboretro_state.flight_patrol,
		roboretro_state.spin_attack
	]:
		if not is_on_floor():
			velocity += get_gravity() * delta

	match status:
		roboretro_state.flight_start:
			flight_start_state(delta)
		roboretro_state.flight_patrol:
			flight_patrol_state(delta)
		roboretro_state.idle:
			idle_state(delta)
		roboretro_state.walk:
			walk_state(delta)
		roboretro_state.spin_attack:
			spin_attack_state(delta)


	move_and_slide()

func go_to_idle_state():
	status = roboretro_state.idle
	anim.play("idle")
	velocity = Vector2.ZERO


func go_to_walk_state():
	status = roboretro_state.walk
	anim.play("walk")


func go_to_flight_start_state():
	if status == roboretro_state.flight_start or status == roboretro_state.spin_attack:
		return
	status = roboretro_state.flight_start
	anim.play("flight_start")
	velocity = Vector2.ZERO

func go_to_flight_patrol():
	status = roboretro_state.flight_patrol
	anim.play("flight_patrol")
	fly_origin_x = global_position.x

func go_to_spin_attack_state():
	status = roboretro_state.spin_attack
	anim.play("spin_attack")
	velocity = Vector2.ZERO


func go_to_flight_end_state():
	if status == roboretro_state.dead:
		return

	status = roboretro_state.flight_end
	anim.play("flight_end")
	velocity = Vector2.ZERO


func go_to_dead_state():
	status = roboretro_state.dead
	anim.play("dead")
	velocity = Vector2.ZERO
	hitbox.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)


func idle_state(_delta):
	velocity.x = 0

	if player_detector.is_colliding():
		go_to_flight_start_state()



func flight_start_state(_delta):
	velocity = Vector2.ZERO

func flight_patrol_state(_delta):
	if not player_detector.is_colliding():
		velocity.x = fly_speed * direction
	else:
		var player = player_detector.get_collider()
		if player:
			direction = sign(player.global_position.x - global_position.x)
			velocity.x = fly_speed * direction

	var distance = global_position.x - fly_origin_x
	if distance > fly_limit_right:
		direction = -1
	elif distance < fly_limit_left:
		direction = 1

	velocity.y = 0
	scale.x = direction					

func walk_state(_delta):
	velocity.x = SPEED * direction

	if wall_detector.is_colliding() or not ground_detector.is_colliding():
		scale.x *= -1
		direction *= -1

	if player_detector.is_colliding():
		go_to_flight_start_state()


func spin_attack_state(_delta):
	velocity = Vector2.ZERO

func take_damage():
	go_to_flight_end_state()

func _on_animated_sprite_2d_animation_finished() -> void:
	match anim.animation:
		"flight_start":
			go_to_flight_patrol()

		"flight_end":
			go_to_dead_state()

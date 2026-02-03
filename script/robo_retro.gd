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
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var wall_detector: RayCast2D = $hitbox/wall_detector
@onready var ground_detector: RayCast2D = $hitbox/ground_detector
@onready var player_detector: RayCast2D = $hitbox/player_detector
@onready var walking_sfx: AudioStreamPlayer = $walking_sfx
@onready var flight_sfx: AudioStreamPlayer = $flight_sfx

var can_flip := true
var original_shape: Shape2D





const SPEED := 21.0

var status: roboretro_state
var direction := -1
@export var fly_speed := 20.0
@export var fly_limit_left := -120.0
@export var fly_limit_right := 120.0

var fly_origin_x := 0.0
var waiting_ground := false
var dying := false
var landed := false


func _ready():
	original_shape = collision_shape_2d.shape
	go_to_walk_state()

func _physics_process(delta: float) -> void:
	if status not in [
		roboretro_state.flight_start,
		roboretro_state.flight_patrol,
		roboretro_state.spin_attack
	]:
		if not is_on_floor():
			velocity += get_gravity() * delta

	if status == roboretro_state.flight_end and is_on_floor():
		go_to_dead_state()
		
	match status:
		roboretro_state.flight_start:
			flight_start_state(delta)
		roboretro_state.flight_patrol:
			flight_patrol_state(delta)
		roboretro_state.flight_end:
			flight_end_state(delta)	
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

	if not walking_sfx.playing:
		walking_sfx.play()

	flight_sfx.stop()


func go_to_flight_start_state():
	if status == roboretro_state.flight_start or status == roboretro_state.spin_attack:
		return

	status = roboretro_state.flight_start
	anim.play("flight_start")
	velocity = Vector2.ZERO
	
	walking_sfx.stop()
	
	if not flight_sfx.playing:
		flight_sfx.play()

	walking_sfx.stop()

func go_to_flight_patrol():
	status = roboretro_state.flight_patrol
	anim.play("flight_patrol")
	fly_origin_x = global_position.x

func go_to_spin_attack_state():
	status = roboretro_state.spin_attack
	anim.play("spin_attack")
	velocity = Vector2.ZERO

func go_to_flight_end_state():
	status = roboretro_state.flight_end
	anim.play("flight_end")
	velocity.x = 0
	
	flight_sfx.stop()


	status = roboretro_state.flight_end
	anim.play("flight_end")
	velocity = Vector2.ZERO

func go_to_dead_state():
	status = roboretro_state.dead
	anim.play("dead")

	velocity.x = 0

	walking_sfx.stop()
	flight_sfx.stop()

	var dead_shape := CapsuleShape2D.new()
	dead_shape.radius = 6
	dead_shape.height = 8

	collision_shape_2d.shape = dead_shape

			
func idle_state(_delta):
	velocity.x = 0

	if player_detector.is_colliding():
		go_to_flight_start_state()

func flight_start_state(_delta):
	velocity = Vector2.ZERO

func flight_end_state(_delta):
	velocity.x = 0

	if is_on_floor() and not landed:
		landed = true
		go_to_dead_state()


func flight_patrol_state(_delta):
	if anim.animation == "flight_patrol":
		if anim.frame == 0 and not flight_sfx.playing:
			flight_sfx.play()
	
	if wall_detector.is_colliding() and can_flip:
		var normal := wall_detector.get_collision_normal()
		if normal.x * direction < 0:
			can_flip = false
			flip()

	if not wall_detector.is_colliding():
		can_flip = true

	velocity.x = fly_speed * direction
	velocity.y = 0

func flip():
	direction *= -1
	anim.flip_h = direction < 0

	wall_detector.target_position.x *= -1
	ground_detector.target_position.x *= -1
	player_detector.target_position.x *= -1
		
func walk_state(_delta):
	velocity.x = SPEED * direction

	if anim.animation == "walk":
		if anim.frame == 1 or anim.frame == 4:
			if not walking_sfx.playing:
				walking_sfx.play()

	if wall_detector.is_colliding() and can_flip:
		var normal := wall_detector.get_collision_normal()
		if normal.x * direction < 0:
			can_flip = false
			flip()

	if not wall_detector.is_colliding():
		can_flip = true

	if player_detector.is_colliding():
		go_to_flight_start_state()

func spin_attack_state(_delta):
	velocity = Vector2.ZERO

func take_damage():
	go_to_flight_end_state()

func start_death():
	if dying:
		return

	dying = true
	landed = false
	go_to_flight_end_state()


func dead_state():
	if status == roboretro_state.dead and is_on_floor():
		velocity = Vector2.ZERO

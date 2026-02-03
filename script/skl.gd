extends CharacterBody2D

enum skl_state{
	walk,
	attack,
	dead
}
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $hitbox
@onready var wall_detector: RayCast2D = $wall_detector
@onready var ground_detector: RayCast2D = $ground_detector
@onready var player_detector: RayCast2D = $player_detector
const SPINNING_BONE = preload("uid://dsapxxquu32s")
@onready var bone_start_position: Node2D = $bone_start_position
@export var enemy_score := 100 
@onready var step_sfx: AudioStreamPlayer = $step_sfx
@onready var death_sfx: AudioStreamPlayer = $death_sfx


const SPEED = 7.0
const JUMP_VELOCITY = -400.0

var status: skl_state
var direction = 1
var can_throw = true

func _ready() -> void:
	go_to_walk_state()
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	
	match status:
		skl_state.walk:
			walk_state(delta)
		skl_state.attack:
			attack_state(delta)	
		skl_state.dead:
			dead_state(delta)
					

	move_and_slide()
	
func go_to_walk_state():
	status = skl_state.walk
	anim.play("walking")

func go_to_attack_state():
	status = skl_state.attack
	anim.play("attack")
	velocity = Vector2.ZERO
	can_throw = true
		
func go_to_dead_state():
	status = skl_state.dead
	anim.play("dead")
	Globals.score += enemy_score
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO	
	
	death_sfx.play()
	step_sfx.stop()
			
func walk_state(_delta):
	if anim.frame == 3 or anim.frame == 4:
		velocity.x = SPEED * direction
		if not step_sfx.playing:
			step_sfx.play()
	else:
		velocity.x = 0	
	if wall_detector.is_colliding():
		scale.x *= -1
		direction *= -1
		
	if not ground_detector.is_colliding():
		scale.x *= -1
		direction *= -1
	
	if player_detector.is_colliding():
		go_to_attack_state()	
			
func attack_state(_delta):
	if anim.frame == 2 && can_throw:
		throw_bone()		
		can_throw = false

func dead_state(_delta):
	pass 	

func take_damage():
	go_to_dead_state()	 	

func throw_bone():
	var new_bone = SPINNING_BONE.instantiate()
	add_sibling(new_bone)
	new_bone.position = bone_start_position.global_position
	new_bone.set_direction(direction)
func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "attack":
		go_to_walk_state()
		return

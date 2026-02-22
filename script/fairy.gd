extends CharacterBody2D

enum fairy_state{
	idle_ground,
	idle_fly,
	flying,
	charging,
	magic_attack,
	hurt,
	dead
}

#refs globais
var projectile_scene = preload("res://entitys/fairy_projectile.tscn")
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $hitbox
@onready var wall_detector: RayCast2D = $hitbox/wall_detector
@onready var ground_detector: RayCast2D = $hitbox/ground_detector
@onready var player_detector: RayCast2D = $hitbox/player_detector
@onready var player = get_tree().get_first_node_in_group("player")
var can_flip := true
var original_shape: Shape2D

const SPEED := 21.0

var status: fairy_state
var direction := 1
@export var fly_speed := 50.0
@export var fly_limit_left := -120.0
@export var fly_limit_right := 120.0
@export var shots_fired := 0
@export var max_shots := 3
var shoot_timer := 0.0
@export var shoot_cooldown := 2.0

var player_ref : Node2D
var fly_origin_x := 0.0
func _ready():
	fly_origin_x = global_position.x
	player_ref = get_tree().get_first_node_in_group("player")
	go_to_idle_ground()
	
func _physics_process(delta: float) -> void:
		
	match status:
		fairy_state.idle_ground:
			idle_ground_state(delta)
		fairy_state.idle_fly:
			idle_fly_state(delta)
		fairy_state.flying:
			flying_state(delta)
		fairy_state.charging:
			charging_state(delta)
		fairy_state.magic_attack:
			magic_attack_state(delta)
		fairy_state.hurt:
			hurt_state(delta)
		fairy_state.dead:
			dead_state(delta)						
	move_and_slide()

#func de transição 
func go_to_idle_ground():
	status = fairy_state.idle_ground
	anim.play("idle_ground")
	velocity = Vector2.ZERO	

func go_to_idle_fly():
	status = fairy_state.idle_fly
	anim.play("idle_fly")
	velocity = Vector2.ZERO

func go_to_flying():
	status = fairy_state.flying
	anim.play("flying")

func go_to_charging():
	status = fairy_state.charging
	anim.play("charging")
	velocity = Vector2.ZERO

func go_to_magic_attack():
	status = fairy_state.magic_attack
	anim.play("magic_attack")
	velocity = Vector2.ZERO

func go_to_hurt():
	status = fairy_state.hurt
	anim.play("hurt")
	velocity = Vector2.ZERO

func go_to_dead_state():
	status = fairy_state.dead
	anim.play("hurt") 
	velocity = Vector2.ZERO
	
	set_collision_layer(0)
	set_collision_mask(0)
	hitbox.set_deferred("monitoring", false)

#func de estado	
func idle_ground_state(delta):
	velocity.x = 0
	
	if player_detector.is_colliding():
		go_to_idle_fly()
	
func idle_fly_state(delta):
	velocity = Vector2.ZERO

	
func flying_state(delta):

	if player_ref == null:
		return

	var to_player = player_ref.global_position - global_position
	var distance = to_player.length()
	var stop_distance := 40.0

	# Movimento
	if distance > stop_distance:
		velocity = to_player.normalized() * fly_speed
	else:
		velocity = Vector2.ZERO

	var horizontal_threshold := 15.0

	if abs(to_player.x) > horizontal_threshold:
		var new_direction = sign(to_player.x)

		if new_direction != direction:
			direction = new_direction
			scale.x = direction

	shoot_timer -= delta
	if shoot_timer <= 0:
		shoot()
		shoot_timer = shoot_cooldown
			
func charging_state(delta):
	velocity = Vector2.ZERO
	if anim.frame == anim.sprite_frames.get_frame_count("charging") - 1:
		go_to_magic_attack()
	
func shoot():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	if projectile_scene == null:
		return

	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position

	var dir = sign(player.global_position.x - global_position.x)
	projectile.set_direction(dir)
	
	
func magic_attack_state(delta):
	velocity = Vector2.ZERO
	

	
func hurt_state(delta):
	velocity = Vector2.ZERO

	if anim.frame == anim.sprite_frames.get_frame_count("hurt") - 1:
		go_to_idle_fly()
						

func dead_state(delta):
	velocity = Vector2.ZERO
	
func take_damage():
	go_to_hurt()				


func _on_animated_sprite_2d_animation_finished():

	if status == fairy_state.idle_fly:
		go_to_flying()

	elif status == fairy_state.charging:
		go_to_magic_attack()

	elif status == fairy_state.magic_attack:
		shoot()
		go_to_flying()

	elif status == fairy_state.dead:
		queue_free()

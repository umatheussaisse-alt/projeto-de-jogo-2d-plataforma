extends CharacterBody2D

enum PlayerState {
	idle,
	walk,
	attack_ground,
	attack_air,
	jump,
	fall,
	duck,
	slide,
	wall,
	swimming,
	hurt,
	dead
}
#refs globais
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $hitbox
@onready var hitbox_shape: CollisionShape2D = $hitbox/CollisionShape2D
@onready var left_wall_detector: RayCast2D = $left_wall_detector
@onready var right_wall_detector: RayCast2D = $right_wall_detector
@onready var reload_timer: Timer = $reload_timer
@onready var damage_flash_timer: Timer = $damage_flash_timer


#vars globais alteradas no player
@export var max_speed: float = 180.0
@export var acceleration: float = 400.0
@export var deceleration: float = 400.0
@export var slide_deceleration: float = 100.0
@export var wall_acceleration: float = 40.0
@export var wall_jump_velocity: float = 240.0
@export var water_max_speed: float = 100.0
@export var water_acceleration: float = 200.0
@export var water_jump_force: float = -100.0
@export var knockback_force_x: float = 180.0
@export var knockback_force_y: float = -150.0
@onready var jump_sfx: AudioStreamPlayer = $jump_sfx
@onready var destroy_sfx = preload("res://scene/destroy_efects.tscn")


#vars constantes
var spell_casted := false
@export var spell_offset := 12.0
const SPELL = preload("res://entitys/spell.tscn")
@onready var spell_start = $spell_start
var can_cast = true

var knockback_vector = Vector2.ZERO
var direction = 0
var status: PlayerState
var damage_tween: Tween

const JUMP_VELOCITY = -300.0
var jump_count = 0

@export var max_jump_count: int = 2





#func que starta o jogo		
func _ready() -> void:
	add_to_group("spell")
	go_to_idle_state()
#func fisica, match so status
func _physics_process(delta: float) -> void:
	match status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.attack_ground:
			attack_ground_state(delta)
		PlayerState.attack_air:
			attack_air_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.fall:
			fall_state(delta)
		PlayerState.duck:
			duck_state(delta)
		PlayerState.slide:
			slide_state(delta)
		PlayerState.wall:
			wall_state(delta)
		PlayerState.swimming:
			swimming_state(delta)
		PlayerState.hurt:
			hurt_state(delta)
		PlayerState.dead:
			dead_state(delta)
	
		
	if knockback_vector != Vector2.ZERO:
		velocity = knockback_vector
		knockback_vector = knockback_vector.move_toward(Vector2.ZERO, 800 * delta)


	move_and_slide()
	check_falling_platform()
#func de prepara para o estado
func go_to_idle_state():
	status = PlayerState.idle
	anim.play("idle")
	
func go_to_walk_state():
	status = PlayerState.walk
	anim.play("walk")

func go_to_jump_state():
	if not can_jump():
		return

	status = PlayerState.jump
	anim.play("jump")
	jump_sfx.play()
	velocity.y = JUMP_VELOCITY
	jump_count += 1

	
func go_to_fall_state():
	status = PlayerState.fall
	anim.play("fall")
	
func go_to_duck_state():
	status = PlayerState.duck
	anim.play("duck")
	set_small_collider()
	
func exit_from_duck_state():
	set_large_collider()
	
func go_to_slide_state():
	status = PlayerState.slide
	anim.play("slide")
	set_small_collider()
	
func exit_from_slide_state():
	set_large_collider()
	
func go_to_wall_state():
	status = PlayerState.wall
	anim.play("wall")
	velocity = Vector2.ZERO
	jump_count = 0
	
func go_to_swimming_state():
	status = PlayerState.swimming
	anim.play("swim")
	velocity.y = min(velocity.y, 150)
	
func go_to_hurt_state():
	if status == PlayerState.hurt or status == PlayerState.dead:
		return
	
	status = PlayerState.hurt
	anim.play("dead")

func go_to_dead_state():
	if status == PlayerState.dead:
		return

	status = PlayerState.dead
	anim.play("dead")
	velocity = Vector2.ZERO
	reload_timer.start()
	
func go_to_attack_state():
	#seleciona se o attack ser ano chao ou se sera no jump
	if status == PlayerState.swimming:
		return

	if status == PlayerState.attack_ground or status == PlayerState.attack_air:
		return

	spell_casted = false

	if is_airborne():
		status = PlayerState.attack_air
		anim.play("jump_attack")
	else:
		status = PlayerState.attack_ground
		anim.play("magic_attack")	
	
	
	
#func dos estados
func move(delta):
	update_direction()
	
	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func idle_state(delta):
	apply_gravity(delta)
	move(delta)
	if velocity.x != 0:
		go_to_walk_state()
		return
		
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
		
	if Input.is_action_pressed("duck"):
		go_to_duck_state()
		return
	
	if Input.is_action_just_pressed("cast_spell"):
		go_to_attack_state()
		return
		
	if Input.is_action_just_pressed("cast_spell"):
		go_to_attack_state()

func walk_state(delta):
	apply_gravity(delta)
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
		return
		
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
		
	if Input.is_action_just_pressed("duck"):
		go_to_slide_state()
		return
	
	if Input.is_action_just_pressed("cast_spell"):
		go_to_attack_state()
		return

		
	if !is_on_floor():
		go_to_fall_state()
		return
	
	if Input.is_action_just_pressed("cast_spell"):
		go_to_attack_state()

func attack_ground_state(delta):
	apply_gravity(delta)
	move(delta)

func attack_air_state(delta):
	apply_gravity(delta)	
	move(delta)
	
	if is_on_floor():
		jump_count = 0
		go_to_idle_state()
					
#func de ataque
func _cast_spell() -> void:
	if spell_casted:
		return

	cast_spell()
	spell_casted = true

func cast_spell():
	var spell = SPELL.instantiate()

	var spell_dir: int = direction
	if spell_dir == 0:
		spell_dir = -1 if anim.flip_h else 1

	spell.set_direction(spell_dir)

	spell.global_position = spell_start.global_position + Vector2(spell_offset * spell_dir, 0)

	add_sibling(spell)

func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "magic_attack":
		go_to_idle_state()
	elif anim.animation == "jump_attack":
		if is_on_floor():
			jump_count = 0 
			go_to_idle_state()
		else:
			go_to_fall_state()						

func is_airborne() -> bool:
	return status == PlayerState.jump or status == PlayerState.fall

func jump_state(delta):
	apply_gravity(delta)
	move(delta)

	if Input.is_action_just_pressed("jump") and can_jump():
		go_to_jump_state()
		return

	if Input.is_action_just_pressed("cast_spell"):
		go_to_attack_state()
		return

	if velocity.y > 0:
		go_to_fall_state()
		
func fall_state(delta):
	apply_gravity(delta)
	move(delta)

	if Input.is_action_just_pressed("jump") and can_jump():
		go_to_jump_state()
		return

	if Input.is_action_just_pressed("cast_spell"):
		go_to_attack_state()
		return

	if is_on_floor():
		jump_count = 0
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()

		
	if (left_wall_detector.is_colliding() or right_wall_detector.is_colliding()) && is_on_wall():
		go_to_wall_state()
		return	

func duck_state(delta):
	apply_gravity(delta)
	update_direction()
	if Input.is_action_just_released("duck"):
		exit_from_duck_state()
		go_to_idle_state()
		return
		
func slide_state(delta):
	apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, slide_deceleration * delta)
	
	if Input.is_action_just_released("duck"):
		exit_from_slide_state()
		go_to_walk_state()
		return
		
	if velocity.x == 0:
		exit_from_slide_state()
		go_to_duck_state()
		return
		
func wall_state(delta):
	
	velocity.y += wall_acceleration * delta
	
	if left_wall_detector.is_colliding():
		anim.flip_h = false
		direction = 1
	elif right_wall_detector.is_colliding():
		anim.flip_h = true
		direction = -1
	else:
		go_to_fall_state()
		return
	
	if is_on_floor():
		go_to_idle_state()
		return
		
	if Input.is_action_just_pressed("jump"):
		velocity.x = wall_jump_velocity * direction
		go_to_jump_state()
		return
		
func swimming_state(delta):
	update_direction()
	
	if direction:
		velocity.x = move_toward(velocity.x, water_max_speed * direction, water_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, water_acceleration * delta)
		
	velocity.y += water_acceleration * delta
	velocity.y = min(velocity.y, water_max_speed)
	
	if Input.is_action_just_pressed("jump"):
		velocity.y = water_jump_force

#todo sistema de dano ao jogador		
func hurt_state(delta):
	apply_gravity(delta)
	
	if is_on_floor():
		go_to_idle_state()

func dead_state(_delta):
	pass

func apply_knockback(from_x: float):
	var dir: float = sign(global_position.x - from_x)
	if dir == 0:
		dir = 1
	
	knockback_vector = Vector2(knockback_force_x * dir,knockback_force_y)

func take_damage(from_x: float):
	if status == PlayerState.hurt or status == PlayerState.dead:
		return

	apply_knockback(from_x)
	hits_damage()

	# flash vermelho
	if has_meta("damage_tween"):
		var old_tween: Tween = get_meta("damage_tween")
		if old_tween and old_tween.is_running():
			old_tween.kill()

	anim.modulate = Color(1, 0.2, 0.2)
	var tween := create_tween()
	tween.tween_property(anim, "modulate", Color(1,1,1), 0.25)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	set_meta("damage_tween", tween)

	go_to_hurt_state()

func hits_damage():
	Globals.hits -= 1

	if Globals.hits > 0:
		return

	# perdeu um coração
	Globals.hearts -= 1
	Globals.hits = Globals.max_hits_per_heart


	if Globals.hearts <= 0:
		go_to_dead_state()
	else:
		reload_timer.start()

func lose_heart():
	Globals.hearts -= 1
	Globals.hits = Globals.max_hits_per_heart

	if Globals.hearts <= 0:
		game_over()
	else:
		reload_timer.start()
	
func game_over():
	reload_timer.start()

#func apply gravidade	
func apply_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta
#func de mudar dirção do personagem	
func update_direction():
	direction = Input.get_axis("left", "right")
	
	if direction < 0:
		anim.flip_h = true
	elif direction > 0:
		anim.flip_h = false

func check_falling_platform():
	if not is_on_floor():
		return

	for falling_platform in get_slide_collision_count():
		var collision := get_slide_collision(falling_platform)
		var collider := collision.get_collider()

		if collider and collider.has_method("trigger_fall"):
			collider.trigger_fall()
func can_jump() -> bool:
	return jump_count < max_jump_count
#func collider small e large
func set_small_collider():
	collision_shape_2d.shape.radius = 5
	collision_shape_2d.shape.height = 12
	collision_shape_2d.position.y = 8
	
	hitbox_shape.shape.size.y = 6
	hitbox_shape.position.y = 10
	
func set_large_collider():
	collision_shape_2d.shape.radius = 9
	collision_shape_2d.shape.height = 25
	collision_shape_2d.position.y = 1
	
	hitbox_shape.shape.size.y = 24
	hitbox_shape.position.y = 0.5
#func faz ele ficar vermelho

#func que mata o personagem
func die_instantly():
	if status == PlayerState.dead:
		return
	go_to_dead_state()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if status == PlayerState.dead:
		return
	if area.is_in_group("enemies"):
		hit_enemy(area)
	elif area.is_in_group("lethal_area"):
		die_instantly()

#func lava e water		
func _on_hitbox_body_entered(body: Node2D) -> void:
	if status == PlayerState.dead:
		return
	if  body.is_in_group("lethal_area"):
		die_instantly()
	
	elif body.is_in_group("water"):
		go_to_swimming_state()		 

func hit_enemy(area: Area2D):
	if velocity.y > 0:
		area.get_parent().take_damage()
		go_to_jump_state()
	else:
		take_damage(area.global_position.x)

#func lethal area	
func hit_lethal_area():
	take_damage(global_position.x)

#func reset fase
func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("water"):
		jump_count = 0
		go_to_jump_state()

func _on_head_collider_body_entered(body: Node2D) -> void:
	if body.has_method("break_sprite"):
		body.hitpoints -= 1
		if body.hitpoints < 0:
			body.break_sprite()
			play_destroy_effects()
		else:
			body.animation_player.play("hit")
			body.hit_block_sfx.play()
			body.create_coin()

func play_destroy_effects():
	var sound_sfx = destroy_sfx.instantiate()
	get_parent().add_child(sound_sfx)
	sound_sfx.play()
	await sound_sfx.finished
	sound_sfx.queue_free()

func _on_animated_sprite_2d_frame_changed() -> void:
	if anim.animation == "magic_attack" and anim.frame == 3:
		_cast_spell()
	if anim.animation == "jump_attack" and anim.frame == 1:
		_cast_spell()

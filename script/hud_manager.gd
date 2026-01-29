extends Control
@onready var player := get_tree().get_first_node_in_group("player")
@onready var mana_bar: AnimatedSprite2D = $container/mana_container/mana_bar
@onready var coins_counter: Label = $container/coins_container/coins_icon/coins_counter 
@onready var life_counter: Label = $container/life_container/life_icon/life_counter
@onready var timer_counter: Label = $container/timer_container/timer_counter
@onready var score_counter: Label = $container/score_container/score_counter
var current_frame: float = 0
var mana_tween: Tween
# Called when the node enters the scene tree for the first time.

func _ready() -> void:
	update_hud()
	if player:
		player.mana_changed.connect(update_mana)
		update_mana(player.mana, player.max_mana)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	update_hud()
	
	
func update_hud():
	coins_counter.text = "%04d" % Globals.coins
	score_counter.text = "%06d" % Globals.score
	life_counter.text = str(Globals.hearts)
	timer_counter.text = format_time(Globals.time_left)	
	

	
func format_time(time: float) -> String:
	var minutes := int(time) / 60
	var seconds := int(time) % 60
	return "%02d:%02d" % [minutes, seconds]

#aplica as edic visuais da mana
func _apply_mana_visual(current: int, max: int) -> void:
	mana_bar.frame = int(current_frame)
	update_mana_color(current, max)


func update_mana(current: int, max: int) -> void:
	var target_frame: int = clamp(max - current, 0, max)
	if mana_tween and mana_tween.is_running():
		mana_tween.kill()
#func tweeen pra transicao barra manan
	mana_tween = create_tween()
	mana_tween.tween_property(self,"current_frame",target_frame,0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	mana_tween.tween_callback(_apply_mana_visual.bind(current, max))


func update_mana_color(current: int, max: int) -> void:
	var ratio := float(current) / max
	if ratio <= 0.2:
		mana_bar.modulate = Color(1, 0.2, 0.2) # vermelho (crítico)
	elif ratio <= 0.5:
		mana_bar.modulate = Color(1, 0.8, 0.3) # amarelo (atenção)
	else:
		mana_bar.modulate = Color(1, 1, 1) # normal

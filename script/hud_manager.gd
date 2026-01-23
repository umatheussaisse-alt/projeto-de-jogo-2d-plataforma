extends Control

@onready var coins_counter: Label = $container/coins_container/coins_icon/coins_counter 
@onready var life_counter: Label = $container/life_container/life_icon/life_counter
@onready var timer_counter: Label = $container/timer_container/timer_counter
@onready var score_counter: Label = $container/score_container/score_counter

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_hud()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
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

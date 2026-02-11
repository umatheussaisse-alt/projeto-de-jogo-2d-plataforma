extends Node2D
@onready var gameover := preload("res://scene/gameover.tscn")


func _ready():
	Globals.game_over.connect(show_game_over)

func show_game_over():
	if get_tree().paused:
		return

	var game_over_scene = preload("res://scene/gameover.tscn").instantiate()
	add_child(game_over_scene)
	get_tree().paused = true

	

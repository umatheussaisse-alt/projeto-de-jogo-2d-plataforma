extends Camera2D
#variaveel target = camera
var target: Node2D
#chama a camera
func _ready() -> void:
	get_target()
#define a posicao da camera e transforma position para o target
func _process(_delta: float) -> void:
	position = target.position
	#procura o player e se nao acha ele dapresenta um erro
func get_target():
	var nodes = get_tree().get_nodes_in_group("player")
	if nodes.size() == 0:
		push_error("Player not found")
		return
	target = nodes[0]	

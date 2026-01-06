extends Node

@export var player_one: CharacterBody3D
@export var player_two: CharacterBody3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#set initial game state
	await get_tree().process_frame #waits for all instances to be initialized
	
	player_one.current_state = player_one.serve_state
	player_one.fsm.transition(player_one.current_state)
	
	player_two.current_state = player_two.return_state
	player_two.fsm.transition(player_two.current_state)
	return

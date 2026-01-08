extends Node

@export var player_one: CharacterBody3D
@export var player_two: CharacterBody3D

@export var main: Node3D

var ball
var rally_ready = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#set initial game state
	await get_tree().process_frame #waits for all instances to be initialized
	
	player_one.current_state = player_one.serve_state
	player_one.fsm.transition(player_one.current_state)
	
	player_two.current_state = player_two.return_state
	player_two.fsm.transition(player_two.current_state)
	return

func _process(delta: float) -> void:
	if not ball:
		ball = main.get_node_or_null("Ball")
	
	if ball and (ball.bounces == 2 or ball.hit_wall):
		ball.bounces = 0
		ball.hit_wall = false
		_reset()
		
func _reset():
	rally_ready = false
	
	player_two.current_playstyle = null
	player_two.current_state = player_two.return_state
	player_two.fsm.transition(player_two.current_state)
	
	player_one.current_playstyle = null
	player_one.current_state = player_one.pick_up_ball_state
	player_one.fsm.transition(player_one.current_state)
	
	return

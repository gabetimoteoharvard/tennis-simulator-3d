class_name ServeState
extends State

@export var actor: CharacterBody3D

@export var jump_height: float
var jumped
var hit_ball

var serve_boundaries
var serve_target_boundaries

var serve_position
var serve_target
var rng = RandomNumberGenerator.new()

var ball_scene = preload("res://scenes/tennis_ball.tscn")
var ball_instance

var actions = [rotation_phase, await_opponent, toss_phase, hit_phase]
var current_action

signal to_position_state

func _enter_state():
	
	current_action = 0 #our current action begins at 0
	serve_boundaries = actor.service_area.global_position #gets x, y coords of service box
	
	serve_target_boundaries = actor.service_target_area.global_position
	
	#mapping that allows us to define serve boundaries
	var serve_mapping = {1: {1: Vector2(0, 1.125),
							   0: Vector2(-1.125, 0)}, 
						 0: {1: Vector2(-1.125, 0),
							   0: Vector2(0, 1.125)}}
							
	
	#define serve boundaries based on whether it's deuce or ad, and what side of the court the player is on
	var offset = serve_mapping[actor.service_side][actor.court_side]
	serve_boundaries = [serve_boundaries.x - 0.05, serve_boundaries.x + 0.05, 
							serve_boundaries.z + offset.x, serve_boundaries.z + offset.y]
	
	var target_offset = serve_mapping[int(!actor.service_side)][actor.court_side]
	serve_target_boundaries = [serve_target_boundaries.x - 0.8755, serve_target_boundaries.x + 0.8755, 
							serve_target_boundaries.z + target_offset.x, serve_target_boundaries.z + target_offset.y]
								
	#select random serving spot position
	rng.randomize()
	serve_position = Vector2(rng.randf_range(serve_boundaries[0], serve_boundaries[1]),
							 rng.randf_range(serve_boundaries[2], serve_boundaries[3]))
	serve_target = Vector3(rng.randf_range(serve_target_boundaries[0], serve_target_boundaries[1]),
						   0,
						   rng.randf_range(serve_target_boundaries[2], serve_target_boundaries[3]))
	
	
	jumped = false
	
	#set target to move 
	actor.curr_target = serve_position
	actor.wobble_dir = "left"
	set_physics_process(true)
	
	
func _physics_process(delta):
	#first we need to get on serve position
	if actor.curr_target != null:
		return
	
	#handle current actiom
	actions[current_action].call(delta)
	
	
func rotation_phase(delta):
	
	#vector we want our ray cast to be
	
	var target_vector = actor.serve_direction

	var rotated = actor.rotate_self(target_vector, delta)
	if not rotated:
		return
		
	current_action+=1
	
var wait_timer = 0		
func await_opponent(delta):
	if actor.opponent.curr_target:
		return
	wait_timer += delta
	if wait_timer >= 1.5:
		wait_timer = 0
		current_action += 1
	
func toss_phase(delta):
		
	ball_instance = ball_scene.instantiate()
	ball_instance.name = "Ball"
	ball_instance.global_position = actor.global_position + Vector3(0, 0.2, 0)
	ball_instance.linear_velocity = Vector3(0, 5, 0)
		
	actor.main.add_child(ball_instance)
	current_action+=1
	

func hit_phase(delta):
	
	if not jumped and (ball_instance.linear_velocity.y > 2 and ball_instance.linear_velocity.y < 2.2):
		actor.velocity.y = jump_height		
		jumped = true
	
	if not hit_ball and (actor.velocity.y > 0 and actor.velocity.y < 0.2):
		process_serve(ball_instance, serve_target)
		hit_ball = true
		
		actor.current_playstyle = "neutral"
		to_position_state.emit()
		return
		
	if jumped:
	
		#vector we want our ray cast to be
		var target_vector = serve_target
		
		actor.rotate_self(target_vector, delta)
	
		
func process_serve(ball, target):
	var serve_vec = (target - ball_instance.global_position).normalized()
	var serve_speed = randf_range(10,12)
	serve_vec *= serve_speed
	serve_vec.y =  0
	ball.linear_velocity = serve_vec
	
	
	
func _exit_state():
	set_physics_process(false)

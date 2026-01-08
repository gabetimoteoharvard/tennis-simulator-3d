class_name ReturnState
extends State

@export var actor: CharacterBody3D

var current_action
var actions = [anticipate, move_to_ball]

var return_boundaries
var return_position

var ball
var hit
var velocity_

var predicted = false
var ps

var rng = RandomNumberGenerator.new()

signal to_position_state
func _enter_state():
	hit = false
	velocity_ = Vector3(0,0,0)
	current_action = 0
	
	return_boundaries = actor.return_area.global_position #gets x, y coords of service box
	
	var return_mapping = {1: {1: Vector2(0, 1.125),
							   0: Vector2(-1.125, 0)}, 
						 0: {1: Vector2(-1.125, 0),
							   0: Vector2(0, 1.125)}}
	
	var offset = return_mapping[actor.service_side][actor.court_side]
	return_position = Vector2(return_boundaries.x, (2*return_boundaries.z + offset.x + offset.y)/2)
	
	actor.curr_target = return_position
	actor.player_speed = 0.8
	
	set_physics_process(true)
	return

func _physics_process(delta: float) -> void:
	actions[current_action].call(delta)

func anticipate(delta):
	if actor.curr_target:
		return
		
	actor.rotate_speed = 4
	actor.rotate_self((actor.opponent.global_position - actor.global_position).normalized(), delta)
	actor.player_wobble = true
	
	if !actor.GAME_CONTROLLER.rally_ready:
		return
		
	ball = actor.main.get_node_or_null("Ball")
	if ball != null:
		current_action += 1

func move_to_ball(delta):
	if ball.linear_velocity.x == 0 and ball.linear_velocity.z == 0:
		return
	
	actor.rotate_speed = 6
	actor.rotate_self((ball.global_position - actor.global_position).normalized(), delta)
	
	
	if not predicted:
		var bounce_parameters = actor.predict_bounce(ball, delta)
		var time = bounce_parameters[2]
		
		ps = Vector2(bounce_parameters[0], bounce_parameters[1])
		actor.curr_target = ps
		
		actor.player_speed = min(actor.MAX_SPEED, (ps - Vector2(actor.global_position.x, actor.global_position.z)).length()/time)
		
		actor.wobble_speed = 6
		predicted = true
		
	if hit:
		actor.hit_ball(delta, ball, actor.velocity)
		actor.curr_target = null
		
		to_position_state.emit()
		return
	
func _exit_state():
	predicted = false
	hit = false
	current_action = 0
	ps = null
	
	set_physics_process(false)
	return

func _on_strike_zone_body_entered(body: Node3D) -> void:
	if body is TennisBall:
		#ball hitting logic here
		
		hit = true
		return

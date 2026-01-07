class_name RallyState
extends State

""" Very similar to return logic, move towards the ball and the your next shot will depend on your return readiness, then
switch state to the positioning stage """

@export var actor: CharacterBody3D


var ball
var hit
var velocity_

var predicted
var ps

var rng = RandomNumberGenerator.new()

signal to_position_state

func _enter_state():
	
	hit = false
	predicted = false
	velocity_ = Vector3(0,0,0)
	ball = actor.main.get_node_or_null("Ball")
	
	set_physics_process(true)
	
	return

func _physics_process(delta: float) -> void:
	
	if !ball.is_moving_towards_player(actor):
		return
				
	if not predicted:
		var bounce_parameters = actor.predict_bounce(ball, delta, 2.0, [0.1, 0.4])
	
		var time = bounce_parameters[2]
		ps = Vector2(bounce_parameters[0], bounce_parameters[1]) 
	
		if((actor.court_side == 0 and ps[0] > actor.global_position.x) 
		or (actor.court_side == 1 and ps[0] < actor.global_position.x)):
			ps[0] = actor.global_position.x
	
	
		actor.player_speed = min(actor.MAX_SPEED, (ps - Vector2(actor.global_position.x, actor.global_position.z)).length()/time)
			
		actor.wobble_speed = 6
	
		actor.curr_target = ps
		
		predicted = true
	
	if hit:
		actor.hit_ball(delta, ball, actor.velocity)
		
		actor.curr_target = null
		hit = false
		
		to_position_state.emit()
		return
	
func _on_strike_zone_body_entered(body: Node3D) -> void:
	if body is TennisBall:
		hit = true
		return

func _exit_state():
	predicted = false
	hit = false
	
	ps = null
	
	set_physics_process(false)
	return

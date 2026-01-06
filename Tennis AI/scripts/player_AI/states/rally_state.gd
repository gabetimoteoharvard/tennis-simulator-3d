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
	
	if !is_moving_towards_player():
	
		return
		
		
	if not predicted:
		var bounce_parameters = predict_bounce(ball, delta)
	
		var time = bounce_parameters[2]
		ps = Vector2(bounce_parameters[0], bounce_parameters[1]) #first fix: if the x-coord is behind the player and player is defensive or neutral, keep it as is (aka don't move backwards) 
	
		if((actor.court_side == 0 and ps[0] > actor.global_position.x) or (actor.court_side == 1 and ps[0] < actor.global_position.x)):
			ps[0] = actor.global_position.x
	
	
		actor.player_speed = min(actor.MAX_SPEED, (ps - Vector2(actor.global_position.x, actor.global_position.z)).length()/time)
			
		actor.wobble_speed = 6
	
		actor.curr_target = ps
		
		predicted = true
	
	if hit:
		hit_ball(delta)
		
		actor.curr_target = null
		hit = false
		
		to_position_state.emit()
		return
	
		


	
func is_moving_towards_player():
	""" Returns whether ball is currently going to player"""
	if ((actor.court_side == 0) and (ball.linear_velocity.x > 0)) or ((actor.court_side == 1) and (ball.linear_velocity.x < 0)):
		return true
	return false
	
func predict_bounce(ball: TennisBall, delta, max_time = 2.0):
	"""Returns position of where player should be for optimal ball hitting"""
	
	var g = ProjectSettings.get_setting("physics/3d/default_gravity")
	var t = 0.0
	var pos = ball.global_position
	var vel = ball.linear_velocity
	
	var bounced = false
	while t < max_time:
		
		vel.y += -g*delta
		pos += vel * delta
	
		
		if not bounced and pos.y <= 0:
			vel.y = -(vel.y + sign(vel.y)*ball.court_bounce_factor) * ball.bounce_factor
			pos.y = 0
	
			bounced = true
			continue
		
		if bounced and 0.1 <= pos.y and pos.y <= 0.4:
			return [pos.x, pos.z, t]
		t += delta
			
	return [pos.x, pos.z, t]
	
func hit_ball(delta):
	#idea: first look at player's speed, then at our velocity vector (both will determine how hard it is to return a shot). 
	#ball speed will also factor in
	
	var to_ball = (ball.global_position - actor.global_position).normalized()
	var movement_dir = velocity_.normalized() if velocity_.length() != 0 else velocity_
	
	var alignment = Vector2(movement_dir.x, movement_dir.z).dot(Vector2(to_ball.x, to_ball.z)) if movement_dir.length() != 0 else 1
	
	var return_readiness = clamp((1.0 - actor.player_speed/actor.MAX_SPEED)*0.5 + alignment*0.5, 0.0, 1.0)

	
	var target_box
	var ball_target_coords
	var speed 
	if return_readiness < 0.25:
		#block, high ball, high chance for error
		var error = randf_range(0,1)
		target_box = actor.court_areas["defensive"]
		ball_target_coords = Vector2(randf_range(target_box[0], target_box[1]) + error, randf_range(target_box[2], target_box[3]) + error)
		speed = randf_range(2,3)
		
		actor.current_playstyle = "defensive"
		
	elif return_readiness < 0.4:
		#defensive, somewhat neutral
		target_box = actor.court_areas["defensive"]
		ball_target_coords = Vector2(randf_range(target_box[0], target_box[1]), randf_range(target_box[2], target_box[3]))
		speed = randf_range(4,6)
		
		actor.current_playstyle = "defensive"
		
	
	elif return_readiness < 0.7:
		#neutral, go for deep return
		target_box = actor.court_areas["neutral"]
		ball_target_coords = Vector2(randf_range(target_box[0], target_box[1]), randf_range(target_box[2], target_box[3]))
		speed = randf_range(6,8)
		
		actor.current_playstyle = "neutral"
	
	else:
		var choose =["right", "left"][ randi_range(0,1)]
		target_box = actor.court_areas[choose]
		ball_target_coords = Vector2(randf_range(target_box[0], target_box[1]), randf_range(target_box[2], target_box[3]))
		speed = randf_range(8,10)
		
		actor.current_playstyle = "attack"
		
	
	var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	var dist = ball_target_coords - Vector2(ball.global_position.x, ball.global_position.z)
	var horizontal_dist = sqrt(dist.x * dist.x + dist.y * dist.y)
	var vel = (dist).normalized() * speed
	
	var v_xz = sqrt(vel.x*vel.x  + vel.y*vel.y)
	
	var t = horizontal_dist/ v_xz
	var v_y = max(2.8, (-ball.global_position.y + 0.5*gravity*t*t)/t)
	
	
	ball.linear_velocity.x = vel.x
	ball.linear_velocity.z = vel.y
	ball.linear_velocity.y = v_y
	
	actor.velocity.y = 1.5
	
func _on_strike_zone_body_entered(body: Node3D) -> void:
	if body is TennisBall:
		#ball hitting logic here
		print('hello?')
		hit = true
		return

func _exit_state():
	predicted = false
	hit = false
	
	ps = null
	
	set_physics_process(false)
	return

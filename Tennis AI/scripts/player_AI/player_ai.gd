extends CharacterBody3D

@export var main: Node3D
@export var court_side: int  #represents court side the player is on
@export var opponent: CharacterBody3D

#finite state machine
@onready var fsm = $FiniteStateMachine as FiniteStateMachine
@onready var serve_state = $FiniteStateMachine/ServeState as ServeState
@onready var return_state = $FiniteStateMachine/ReturnState as ReturnState
@onready var positioning_state = $FiniteStateMachine/PosititoningStage as PositioningState
@onready var rally_state = $FiniteStateMachine/RallyState as RallyState

@onready var facing_dir = $RayCast3D

#movement parameters
var player_wobble = false
var wobble_dir = "left"
@export var wobble_speed := 3
var last_rotation_z = 0

var curr_target = null

#speed parameters
@export var rotate_speed = 2
@export var player_speed = 0.8
@export var MAX_SPEED = 2

#serve parameters
@export var service_area: MeshInstance3D
@export var service_target_area: MeshInstance3D

@export var return_area: MeshInstance3D

@export var target_ball_area: MeshInstance3D

var service_side = 1 #represents side of serve, 1 represents deuce, 0 represents ad
var serve_direction = Vector3(0,0,1)

var current_state: State

var court_areas = {"dropshot": null, "neutral": null, "defensive": null, "left": null, "right": null}

var current_playstyle = null

var ball

func _ready() -> void:
	process_bounds(target_ball_area)
	serve_state.set_physics_process(false)
	return_state.set_physics_process(false)
	positioning_state.set_physics_process(false)
	rally_state.set_physics_process(false)
	
	return_state.to_position_state.connect(fsm.transition.bind(positioning_state))
	serve_state.to_position_state.connect(fsm.transition.bind(positioning_state))
	rally_state.to_position_state.connect(fsm.transition.bind(positioning_state))
	
	positioning_state.to_rally_state.connect(fsm.transition.bind(rally_state))
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	
	movement(delta)	#moves to a target if one exists
	wobble(delta) #wobbling movement when moving
	move_and_slide()
	
func movement(delta):
	if curr_target == null: # if there is no current target, set our velocity to be zero, and return
		velocity.x = 0
		velocity.z = 0
		return
	
	#player wobbles while moving
	player_wobble = true
	
	#vector we want our ray cast to be
	var target_vector = (Vector3(curr_target.x, global_position.y, curr_target.y) - global_position).normalized() 
							   
	if !current_playstyle:
		rotate_self(target_vector, delta) # rotate based on target
	else:
		
		if not ball:	
			ball = main.get_node_or_null("Ball")
			
		if ball:	
			var target_ball_vector = (Vector3(ball.global_position.x, global_position.y, ball.global_position.z) - global_position).normalized() 
			rotate_self(target_ball_vector, delta)
	
	#adjust our player velocity
	var velocity_dir = (target_vector)*player_speed
	velocity.x = velocity_dir.x
	velocity.z = velocity_dir.z
	
	#if the difference between the target and our position is small enough (tolerance of 0.07), we have reached the target
	var diff = Vector2(global_position.x , global_position.z) - curr_target
	if sqrt(diff.x * diff.x + diff.y * diff.y) <= 0.07:
		player_wobble = false
		curr_target = null
	
func wobble(delta):
	if not player_wobble:
		
		last_rotation_z = 0 #set our last rotation to 0 
		
		#smooth stop wobbling
		if rotation.z != 0:
			if rotation.z < 0 :
				rotation.z = min(0, wobble_speed*delta + rotation.z)
			else:
				rotation.z = max(0, -wobble_speed*delta + rotation.z)	
		return

		
	if wobble_dir == "left": #wobble to the left
		rotation.z = rotation.z + wobble_speed*delta
		if rotation.z >= deg_to_rad(30):
			wobble_dir = "right"
			
	if wobble_dir == "right": #wobble to the right
		rotation.z = rotation.z - wobble_speed*delta
		if rotation.z <= deg_to_rad(-30):
			wobble_dir = "left"
			
	#once direction changes, do a little hop
	if (sign(rotation.z) != sign(last_rotation_z)) and is_on_floor():
		velocity.y = 1
	
	last_rotation_z = rotation.z #update our last rotation
	
func rotate_self(target_vector, delta=1):
	"""Makes a small rotation towards a target_vector"""
	
	var current_facing = facing_dir.global_transform.basis.z.normalized() #vector of our ray cast
	
	var angle = atan2(target_vector.x, target_vector.z) - atan2(current_facing.x, current_facing.z)
	angle = rad_to_deg(wrapf(angle, -PI, PI))
	
	
	#if the angle is higher than 1 (our tolerance threshold), rotate character
	
	if abs(angle) > 2.0:

		#take cross product of vectors to determine what direction to turn
		var cross_2d = current_facing.x*target_vector.z - current_facing.z*target_vector.x
		
		if cross_2d >= 0:
			rotation.y = rotation.y - rotate_speed*delta
		else:
			rotation.y = rotation.y + rotate_speed*delta
		
		return false
	return true
	
func process_bounds(area: MeshInstance3D):
	"""Takes the in bounds and process it into different areas (dropshot, left, right, neutral)"""
	
	var map = {0: 1, 1: -1}

	court_areas["dropshot"] = [area.global_position.x - 1.625*map[court_side], area.global_position.x - 0.8125*map[court_side],
							   area.global_position.z - 1.125, area.global_position.z + 1.125]
		
	court_areas["defensive"] = [area.global_position.x - 0.8125*map[court_side], area.global_position.x + 0.8125*map[court_side], 
								   area.global_position.z - 1.125, area.global_position.z + 1.125]
		
	court_areas["neutral"] = [area.global_position.x + 0.8125*map[court_side], area.global_position.x + 1.625*map[court_side],
								 area.global_position.z - 0.84375, area.global_position.z + 0.84375]
		
	court_areas["left"] = [area.global_position.x + 0.8125*map[court_side], area.global_position.x + 1.625*map[court_side],
							   area.global_position.z + 0.84375, area.global_position.z + 1.125]
			
	court_areas["right"] = [area.global_position.x + 0.8125*map[court_side], area.global_position.x + 1.625*map[court_side],
							   area.global_position.z - 0.84375, area.global_position.z - 1.125]
		
func hit_ball(delta, ball: TennisBall, velocity_):
	#idea: first look at player's speed, then at our velocity vector (both will determine how hard it is to return a shot). 
	#ball speed will also factor in
	
	var to_ball = (ball.global_position - global_position).normalized()
	var movement_dir = velocity_.normalized() if velocity_.length() != 0 else velocity_
	
	var alignment = Vector2(movement_dir.x, movement_dir.z).dot(Vector2(to_ball.x, to_ball.z)) if movement_dir.length() != 0 else 1
	
	var return_readiness = clamp((1.0 - player_speed/MAX_SPEED)*0.5 + alignment*0.5, 0.0, 1.0)

	
	var target_box
	var ball_target_coords
	var speed 
	if return_readiness < 0.25:
		#block, high ball, high chance for error
		var error = randf_range(0,1)
		target_box = court_areas["defensive"]
		ball_target_coords = Vector2(randf_range(target_box[0], target_box[1]) + error, randf_range(target_box[2], target_box[3]) + error)
		speed = randf_range(2,3)
		
		current_playstyle = "defensive"
		
	elif return_readiness < 0.4:
		#defensive, somewhat neutral
		target_box = court_areas["defensive"]
		ball_target_coords = Vector2(randf_range(target_box[0], target_box[1]), randf_range(target_box[2], target_box[3]))
		speed = randf_range(4,6)
		
		current_playstyle = "defensive"
		
	
	elif return_readiness < 0.7:
		#neutral, go for deep return
		target_box = court_areas["neutral"]
		ball_target_coords = Vector2(randf_range(target_box[0], target_box[1]), randf_range(target_box[2], target_box[3]))
		speed = randf_range(6,8)
		
		current_playstyle = "neutral"
	
	else:
		var choose =["right", "left"][ randi_range(0,1)]
		target_box = court_areas[choose]
		ball_target_coords = Vector2(randf_range(target_box[0], target_box[1]), randf_range(target_box[2], target_box[3]))
		speed = randf_range(8,10)
		
		current_playstyle = "attack"
		
	
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
	
	velocity.y = 1.5
	
func predict_bounce(ball: TennisBall, delta, max_time = 2.0, ball_threshold=[0.3, 0.4] ):
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
		
		if bounced and ball_threshold[0] <= pos.y and pos.y <= ball_threshold[1]:
			return [pos.x, pos.z, t]
		t += delta
			
	return [pos.x, pos.z, t]
	

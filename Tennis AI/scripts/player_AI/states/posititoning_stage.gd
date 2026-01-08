class_name PositioningState
extends State

"""
Moves to a part of the court depending on the player's current status (defensive, neutral, attacking, net play)
"""

@export var actor: CharacterBody3D
var ball

@export var timing := 1.0 

var stages = {
	"neutral": 3.40,
	"defensive": 3.70,
	"attack": 1.70,
	"net": 0.80
}

var dist

var initial_vel = null

signal to_rally_state
func _enter_state():
	ball = actor.main.get_node_or_null("Ball")
	timing = 1.0

	if ball != null:
		initial_vel = ball.linear_velocity.x
	set_physics_process(true)
	return
	

func _physics_process(delta: float) -> void:
	
	if ball.is_moving_towards_player(actor):
		to_rally_state.emit()
		return
	
	actor.player_wobble = true
	actor.wobble_speed = 3
	
	dist =  Vector2(actor.global_position.x, actor.global_position.z) - Vector2(
							  sign(actor.global_position.x)*stages[actor.current_playstyle], 0)
				
	var speed=determine_speed(dist, timing)
	if sqrt(dist.x*dist.x + dist.y*dist.y) > 0.2:
		actor.curr_target = Vector2(sign(actor.global_position.x)*stages[actor.current_playstyle],0)
		actor.player_speed = min(actor.MAX_SPEED, speed)
		actor.wobble_speed = max(3, actor.player_speed * 2)
	else:
		actor.curr_target = null
		to_rally_state.emit()
		
		
	actor.rotate_self((ball.global_position - actor.global_position).normalized(), delta)
	
	timing = max(0, timing - delta)
	return
	
	
func determine_speed(dist: Vector2, time: float):
	"""determines speed at which player moves toward target"""
	if time == 0:
		return actor.MAX_SPEED
	return dist.length()/time
	
func _exit_state():
	set_physics_process(false)
	return

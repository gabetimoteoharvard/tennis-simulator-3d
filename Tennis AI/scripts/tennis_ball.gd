class_name TennisBall
extends RigidBody3D

@export var bounce_factor: float = 0.6
@export var court_bounce_factor: float = 0.5

var floor = 0.025

func _physics_process(delta: float) -> void:
	if abs(linear_velocity.y) < 1.7 and global_position.y < floor:
		global_position.y = floor
		linear_velocity.y = 0.0
		
func bounce():

	if linear_velocity.y < -2.5:
		linear_velocity.y = -(linear_velocity.y + sign(linear_velocity.y)*court_bounce_factor) * bounce_factor
	elif linear_velocity.y < 0:
		linear_velocity.y = -(linear_velocity.y) * bounce_factor
	
	
		
	#lateral damping
	linear_velocity.x *= 0.95
	linear_velocity.z *= 0.95

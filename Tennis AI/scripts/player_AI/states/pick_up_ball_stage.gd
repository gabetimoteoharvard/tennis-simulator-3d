class_name PickUpBallState
extends State

@export var actor: CharacterBody3D
var ball
var active = false
signal to_serve

func _enter_state() -> void:
	ball = actor.main.get_node_or_null("Ball")
	actor.player_speed = 1.0
	active = true
	
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not ball:
		to_serve.emit()
		return
		
	actor.curr_target = Vector2(ball.global_position.x, ball.global_position.z)

func _exit_state():
	active = false
	set_physics_process(false)

func _on_strike_zone_body_entered(body: Node3D) -> void:
	if not active:
		return
		
	if body is TennisBall:
		body.queue_free()
		
		to_serve.emit()

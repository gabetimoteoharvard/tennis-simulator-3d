extends Node3D

@export var move_speed := 5.0
@export var mouse_sensitivity := 0.3
@export var zoom_speed := 2.0
@export var min_zoom := 1.0 
@export var max_zoom := 15.0

@onready var pivot = $PitchPivot
@onready var camera = $PitchPivot/Camera3D


var zoom := 10.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-45), deg_to_rad(60))
		
		
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_UP:
	#	zoom -= zoom_speed
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
	#	zoom += zoom_speed
	#zoom = clamp(zoom, min_zoom, max_zoom)
	
	#$PitchPivot/Camera3D.position.z = zoom

func _process(delta):
	var direction := Vector3.ZERO
	
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_right"):
		direction.x +=1
	
	direction = (pivot.transform.basis * Vector3(direction.x, 0, direction.z)).normalized()
	translate(direction * move_speed * delta)

class_name FiniteStateMachine
extends Node

@export var state: State 

func transition(new_state: State):
	if state is State:
		state._exit_state()
	new_state._enter_state()
	state = new_state

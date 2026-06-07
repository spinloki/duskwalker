extends Node3D
## Sandbox coordinator: owns the on-foot vs. driving state and the enter/exit
## handoff between the player and the rover. Press `interact` (E) near the rover
## to climb in; press it again to get out.

## How close (metres) the player must be to the rover to climb in.
@export var enter_distance := 3.5
## Where the player is dropped on exit, in the rover's local space (its left side).
@export var exit_offset := Vector3(-2.2, 0.3, 0.0)

@onready var player: CharacterBody3D = $Player
@onready var rover: CharacterBody3D = $Rover
@onready var player_camera: Camera3D = $Player/Camera3D
@onready var rover_camera: Camera3D = $Rover/Camera3D

var _driving := false


func _ready() -> void:
	_set_driving(false)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if _driving:
		_exit_rover()
	elif _within_reach():
		_enter_rover()


func _within_reach() -> bool:
	return player.global_position.distance_to(rover.global_position) <= enter_distance


func _enter_rover() -> void:
	_set_driving(true)


func _exit_rover() -> void:
	# Drop the player beside the rover before reactivating them.
	player.global_position = rover.global_transform * exit_offset
	_set_driving(false)


func _set_driving(driving: bool) -> void:
	_driving = driving
	player.set_active(not driving)
	rover.set_active(driving)
	if driving:
		rover_camera.make_current()
	else:
		player_camera.make_current()

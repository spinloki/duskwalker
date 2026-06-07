extends CharacterBody3D
## First-person character controller (prototype).
##
## Yaw is applied to the body, pitch to the camera. Mouse is captured on ready;
## press Escape (ui_cancel) to release/recapture the cursor while testing.

@export var walk_speed := 4.0
@export var sprint_speed := 7.0
@export var jump_velocity := 4.5
@export var mouse_sensitivity := 0.0025
## Clamp for how far the camera can look up/down, in radians (~85 degrees).
@export var pitch_limit := 1.48

@onready var _camera: Camera3D = $Camera3D

var _pitch := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Enable/disable this controller. While inactive it stops simulating, stops
## reading input, hides, and drops its collision so it can ride inside the rover.
func set_active(value: bool) -> void:
	set_physics_process(value)
	set_process_unhandled_input(value)
	visible = value
	$CollisionShape3D.set_deferred("disabled", not value)
	if not value:
		velocity = Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -pitch_limit, pitch_limit)
		_camera.rotation.x = _pitch
	elif event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()

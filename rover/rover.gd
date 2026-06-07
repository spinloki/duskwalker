extends CharacterBody3D
## Arcade rover controller (prototype).
##
## Intentionally NOT a physics vehicle yet — a scripted arcade model that drives
## predictably on the greybox. Throttle builds forward/reverse speed along the
## body's facing; steering rotates the body and only bites while moving. See
## docs/roadmap.md for the VehicleBody3D/suspension upgrade path.

## Top speed driving forward (m/s).
@export var max_speed := 14.0
## Top speed in reverse (m/s).
@export var max_reverse_speed := 5.0
## How quickly throttle builds speed (m/s^2).
@export var acceleration := 12.0
## How quickly the brake bleeds forward speed (m/s^2).
@export var braking := 22.0
## Passive slow-down when off the throttle (m/s^2).
@export var friction := 6.0
## Steering rate at full authority (radians/sec).
@export var turn_speed := 1.8

## Signed speed along the rover's forward axis (+ forward, - reverse).
var _forward_speed := 0.0


func _physics_process(delta: float) -> void:
	var throttle := Input.get_axis("move_back", "move_forward")
	var steer := Input.get_axis("move_right", "move_left")

	if throttle > 0.0:
		_forward_speed = move_toward(_forward_speed, max_speed, acceleration * delta)
	elif throttle < 0.0:
		if _forward_speed > 0.1:
			# Braking while rolling forward.
			_forward_speed = move_toward(_forward_speed, 0.0, braking * delta)
		else:
			# Stopped or already rolling back: accelerate into reverse.
			_forward_speed = move_toward(_forward_speed, -max_reverse_speed, acceleration * delta)
	else:
		_forward_speed = move_toward(_forward_speed, 0.0, friction * delta)

	# Steering authority scales with speed and flips sign in reverse, so the rover
	# can't pivot in place and reversing curves the way a real vehicle does.
	var speed_factor := clampf(absf(_forward_speed) / max_speed, 0.0, 1.0)
	var dir_sign := signf(_forward_speed)
	rotate_y(steer * turn_speed * delta * speed_factor * dir_sign)

	var forward := -transform.basis.z
	velocity.x = forward.x * _forward_speed
	velocity.z = forward.z * _forward_speed

	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	else:
		velocity.y = 0.0

	move_and_slide()

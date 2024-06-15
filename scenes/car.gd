extends VehicleBody3D

signal playerEnterCarArea
signal playerExitCarArea

const JUMP_VELOCITY = 4

@onready var enterCarLabel = $CanvasLayer/enterCar
@onready var camera = $CameraController/Camera3D

@export var sens = 0.2
const MAX_STEER = 0.75
const ENGINE_POWER = 1000
const BRAKE = 100


# Get the gravity from the project settings to be synced with RigidBody nodes.
#var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _input(event):
	if event is InputEventMouseMotion:
		$CameraController.rotate_y(deg_to_rad(-event.relative.x*sens))
	if Input.is_action_pressed("jump"):
		brake = BRAKE
	else:
		brake = 0

func _physics_process(delta):
	if !$CameraController/Camera3D.current:
		brake = BRAKE
		return
	steering = move_toward(steering, Input.get_axis("right","left") * MAX_STEER, delta * 2.5)
	engine_force = Input.get_axis("backward", "forward") * ENGINE_POWER

func _on_detection_body_entered(body):
	if body.name=="Character":
		emit_signal("playerEnterCarArea")

func _on_detection_body_exited(body):
	if body.name=="Character":
		emit_signal("playerExitCarArea")

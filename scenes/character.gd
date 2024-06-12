extends CharacterBody3D

const JUMP_VELOCITY = 3

@onready var camera = $CameraController/CameraTarget/Camera3D
@onready var collision = $CollisionShape3D

@export var sens = 0.2
var SPEED = 2
var jumping = false
var playerCarState
var playerNavigationState

enum playerCarStates {CANT_ENTER_CAR, CAN_ENTER_CAR, INCAR}
enum playerNavigationStates {IDLE, WALKING, RUNNING}

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	playerCarState=playerCarStates.CANT_ENTER_CAR
	playerNavigationState=playerNavigationStates.IDLE

func _input(event):
	if event is InputEventMouseMotion:
		#$CameraController.rotate_y(deg_to_rad(-event.relative.x*sens))
		#$CameraController.rotate_x(deg_to_rad(event.relative.y*sens))
		$CameraController.rotation.y+=deg_to_rad(-event.relative.x*sens)
		var new_camera_rotation = deg_to_rad(-event.relative.y*(sens*sens))
		var next_camera_x_rotation = rad_to_deg($CameraController.rotation.x+new_camera_rotation)
		if next_camera_x_rotation>-30 and next_camera_x_rotation<45:
			$CameraController.rotation.x+=new_camera_rotation

	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	
func _physics_process(delta):
	if !$CameraController/CameraTarget/Camera3D.current:
		return
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if jumping:
			jumping=false
			$AnimationTree.set("parameters/conditions/velocity", jumping==false)

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jumping=true
	
	if Input.is_action_pressed("run"):
		SPEED = clamp(SPEED + 0.1, SPEED, 4)
		playerNavigationState=playerNavigationStates.RUNNING
	else:
		SPEED = clamp(SPEED - 0.1, 2, SPEED)
		playerNavigationState=playerNavigationStates.WALKING

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var blend_position:float = $AnimationTree.get("parameters/velocity/blend_position")
	var blend_value = 0.03
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		var body_rotation = atan2(-input_dir.x, -input_dir.y)
		$Armature.rotation.y=lerp_angle($Armature.rotation.y,body_rotation,0.1)
		
		rotation.y=lerp_angle(rotation.y,$CameraController.rotation.y,0.1)
		
		if playerNavigationState!=playerNavigationStates.RUNNING:
			if blend_position > 0.5:
				blend_position = clamp(blend_position - blend_value, 0.5, blend_position)
			else:
				blend_position = clamp(blend_position + blend_value, blend_position, 0.5)
		else:
			blend_position = clamp(blend_position + blend_value, blend_position, 1)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		playerNavigationState=playerNavigationStates.IDLE
		blend_position = clamp(blend_position - blend_value, 0, blend_position)
	
	$AnimationTree.set("parameters/velocity/blend_position", blend_position)
	$AnimationTree.set("parameters/conditions/Jump", jumping==true)

	move_and_slide()
	
	$CameraController.position=lerp($CameraController.position,position,0.1)

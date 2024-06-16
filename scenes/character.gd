extends CharacterBody3D

const JUMP_VELOCITY = 3

@onready var camera = $CameraController/CameraTarget/Camera3D
@onready var collision = $CollisionShape3D

@export var sens = 0.2
var SPEED = 2
var jumping = false
var playerCarState
var playerNavigationState
var playerGunState

enum playerCarStates {CANT_ENTER_CAR, CAN_ENTER_CAR, INCAR}
enum playerNavigationStates {IDLE, WALKING, RUNNING}
enum playerGunStates {N, P, R}

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	playerCarState=playerCarStates.CANT_ENTER_CAR
	playerNavigationState=playerNavigationStates.IDLE
	playerGunState=playerGunStates.N
	$AnimationTree.set("parameters/gunStates/transition_request", playerGunStates.keys()[playerGunState])

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
		
	if Input.is_action_pressed("scrollUp"):
		if playerGunState<playerGunStates.size()-1:
			playerGunState=playerGunState+1
			changeGun(playerGunState)
			$AnimationTree.set("parameters/gunStates/transition_request", playerGunStates.keys()[playerGunState])
	
	if Input.is_action_pressed("scrollDown"):
		if playerGunState>0:
			playerGunState=playerGunState-1
			changeGun(playerGunState)
			$AnimationTree.set("parameters/gunStates/transition_request", playerGunStates.keys()[playerGunState])
	
func _physics_process(delta):
	if !$CameraController/CameraTarget/Camera3D.current:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
	#else:
	#	if jumping:
	#		jumping=false
	
	var gunState = playerGunStates.keys()[playerGunState]
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		#jumping=true
		$AnimationTree.set("parameters/jumpTrigger/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	if gunState!="N":
		#var aimBlendAmount:float = $AnimationTree.get("parameters/aim"+gunState+"Blend/blend_amount")
		if Input.is_action_just_pressed("aim") and is_on_floor():
			$AnimationTree.set("parameters/result/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		if Input.is_action_just_released("aim"):
		#elif aimBlendAmount>0.0:
			$AnimationTree.set("parameters/result/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
		
		if Input.is_action_pressed("jab") and is_on_floor():
			if Input.is_action_pressed("aim"):
				$AnimationTree.set("parameters/"+gunState+"/trigger/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

	if Input.is_action_pressed("run"):
		SPEED = clamp(SPEED + 0.1, SPEED, 4)
		playerNavigationState=playerNavigationStates.RUNNING
	else:
		SPEED = clamp(SPEED - 0.1, 2, SPEED)
		playerNavigationState=playerNavigationStates.WALKING

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var blend_position:float = $AnimationTree.get("parameters/locomotion/blend_position")
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

	$AnimationTree.set("parameters/locomotion/blend_position", blend_position)
	
	move_and_slide()
	
	$CameraController.position=lerp($CameraController.position,position,0.1)

func changeGun(ind):
	var parent = $Armature/GeneralSkeleton/BoneAttachment3D
	for child in parent.get_children():
		child.visible = false
	parent.get_child(ind).visible = true 

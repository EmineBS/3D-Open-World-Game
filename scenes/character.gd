extends CharacterBody3D

const JUMP_VELOCITY = 3

@onready var camera = $CameraController/CameraTarget/Camera3D
@onready var cameraTarget = $CameraController/CameraTarget
@onready var collision = $CollisionShape3D
@onready var skeleton = $Armature/GeneralSkeleton
@onready var rifle = $Armature/GeneralSkeleton/BoneAttachment3D/rifle

@export var sens = 0.2
var SPEED = 2
var jumping = false
var playerCarState
var playerNavigationState
var playerGunState

enum playerCarStates {CANT_ENTER_CAR, CAN_ENTER_CAR, INCAR}
enum playerNavigationStates {IDLE, WALKING, RUNNING}
enum playerGunStates {N, P, R}

var rifle_transform = {
	"initPos"=Vector3(-2.065, 2.929, 1.018),
	"initRot"=Vector3(-4.3, 4.7, 5.8),
	"newPos"=Vector3(-1.163, 2.473, -1.631),
	"newRot"=Vector3(-50.6, 13.5, -14.4)
}

var camera_positions = {
	"normalPos"=Vector3(0,2.1,1.75),
	"aimingPos"=Vector3(-0.375,1.75,0)
}

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
			$AnimationTree.set("parameters/result/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	
	if Input.is_action_pressed("scrollDown"):
		if playerGunState>0:
			playerGunState=playerGunState-1
			changeGun(playerGunState)
			$AnimationTree.set("parameters/gunStates/transition_request", playerGunStates.keys()[playerGunState])
			$AnimationTree.set("parameters/result/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	
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
	
	match gunState:
		"N":
			$AnimationTree.set("parameters/result/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
		"P":
			if Input.is_action_just_pressed("aim") and is_on_floor():
				$AnimationTree.set("parameters/result/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				
			if Input.is_action_just_released("aim"):
				$AnimationTree.set("parameters/result/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
				
			if Input.is_action_just_pressed("jab"):
				var aim_target = $CameraController/CameraTarget/RayCast3D.get_collision_point()
				$AnimationTree.set("parameters/P/trigger/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			
			if Input.is_action_pressed("aim"):
				cameraTarget.position=lerp(cameraTarget.position,camera_positions["aimingPos"],0.1)
				rotation.y=lerp_angle(rotation.y,$CameraController.rotation.y,0.25)
				$Armature.rotation.y=lerp_angle($Armature.rotation.y,0,0.25)
				var currentSkeleton = skeleton.get_bone_pose_rotation(2)
				var newRotation = Quaternion(-$CameraController.rotation.x+0.25,currentSkeleton.y,currentSkeleton.z,currentSkeleton.w)
				skeleton.set_bone_pose_rotation(2,newRotation)
			else:
				cameraTarget.position=lerp(cameraTarget.position,camera_positions["normalPos"],0.1)
				
		"R":
			var aimBlendAmount:float = $AnimationTree.get("parameters/R/aim/blend_amount")
			
			if Input.is_action_pressed("aim") and is_on_floor():
				var new_blend_amount = clamp(aimBlendAmount + 0.1, aimBlendAmount, 1.0)
				$AnimationTree.set("parameters/R/aim/blend_amount", new_blend_amount)
				rifle.position=rifle_transform["initPos"]
				rifle.rotation_degrees=rifle_transform["initRot"]
				if Input.is_action_just_pressed("jab"):
					var aim_target = $CameraController/CameraTarget/RayCast3D.get_collision_point()
					$AnimationTree.set("parameters/R/trigger/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				
			elif aimBlendAmount>0.0:
				var new_blend_amount = clamp(aimBlendAmount - 0.1, 0.0, aimBlendAmount)
				$AnimationTree.set("parameters/R/aim/blend_amount", new_blend_amount)
				if new_blend_amount<0.5:
					rifle.position=rifle_transform["newPos"]
					rifle.rotation_degrees=rifle_transform["newRot"]
			
			if not $AnimationTree.get("parameters/result/active"):
				$AnimationTree.set("parameters/result/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
				
			if Input.is_action_pressed("aim"):
				cameraTarget.position=lerp(cameraTarget.position,camera_positions["aimingPos"],0.1)
				rotation.y=lerp_angle(rotation.y,$CameraController.rotation.y,0.25)
				$Armature.rotation.y=lerp_angle($Armature.rotation.y,0,0.25)
				var currentSkeleton = skeleton.get_bone_pose_rotation(2)
				var newRotation = Quaternion(-$CameraController.rotation.x+0.25,currentSkeleton.y,currentSkeleton.z,currentSkeleton.w)
				skeleton.set_bone_pose_rotation(2,newRotation)
			else:
				cameraTarget.position=lerp(cameraTarget.position,camera_positions["normalPos"],0.1)


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
		
		if not Input.is_action_pressed("aim"):
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

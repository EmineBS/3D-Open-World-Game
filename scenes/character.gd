extends CharacterBody3D

const JUMP_VELOCITY = 4

@onready var BULLET = preload("res://scenes/bullet.tscn")

@onready var camera = $CameraController/CameraTarget/Camera3D
@onready var cameraTarget = $CameraController/CameraTarget
@onready var collision = $CollisionShape3D
@onready var skeleton = $Armature/GeneralSkeleton
@onready var rifle = $Armature/GeneralSkeleton/BoneAttachment3D/rifle
@onready var pistol = $Armature/GeneralSkeleton/BoneAttachment3D/pistol

@export var sens = 0.2
var SPEED = 2.0
var jumping = false
var playerCarState
var playerNavigationState
var playerGunState

enum playerCarStates {CANT_ENTER_CAR, CAN_ENTER_CAR, INCAR}
enum playerNavigationStates {IDLE, WALKING, RUNNING}
enum playerGunStates {N, P, R}

var rifle_transform = {
	"initPos"=Vector3(-0.113, 0.117, 0.084),
	"initRot"=Vector3(30.7, -4.6, 0.8),
	"newPos"=Vector3(-0.037, 0.176, 0.005),
	"newRot"=Vector3(3.7, -16.9, -18.1)
}

var camera_positions = {
	"normalPos"=Vector3(0,2.1,1.75),
	"aimingPos"=Vector3(-0.375,1.75,0.13)
}

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	$CameraController/CameraTarget/RayCast3D.add_exception(self)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	playerCarState=playerCarStates.CANT_ENTER_CAR
	playerNavigationState=playerNavigationStates.IDLE
	playerGunState=playerGunStates.N
	changeGun(playerGunState)
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
		
	if Input.is_action_pressed("scrollUp") and not Input.is_action_pressed("aim"):
		if playerGunState<playerGunStates.size()-1:
			playerGunState=playerGunState+1
			changeGun(playerGunState)
			$AnimationTree.set("parameters/gunStates/transition_request", playerGunStates.keys()[playerGunState])
			$AnimationTree.set("parameters/result/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
	
	if Input.is_action_pressed("scrollDown") and not Input.is_action_pressed("aim"):
		if playerGunState>0:
			playerGunState=playerGunState-1
			changeGun(playerGunState)
			$AnimationTree.set("parameters/gunStates/transition_request", playerGunStates.keys()[playerGunState])
			$AnimationTree.set("parameters/result/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
	
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
				if aim_target != Vector3.ZERO:
					var bullet = BULLET.instantiate()
					bullet.target=aim_target
					pistol.get_node("Marker3D").add_child(bullet)
				$AnimationTree.set("parameters/P/trigger/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			
			if Input.is_action_pressed("aim"):
				$CanvasLayer/crosshair.visible=true
				cameraTarget.position=lerp(cameraTarget.position,camera_positions["aimingPos"],0.1)
				rotation.y=lerp_angle(rotation.y,$CameraController.rotation.y,0.25)
				$Armature.rotation.y=lerp_angle($Armature.rotation.y,0,0.25)
				var chest_rotation = Vector3.ZERO
				if $CameraController.rotation_degrees.x<-5:
					chest_rotation=deg_to_rad(5)+0.25
				elif $CameraController.rotation_degrees.x>30:
					chest_rotation=deg_to_rad(-30)+0.25
				else:
					chest_rotation=-$CameraController.rotation.x+0.25
				var currentSkeleton = skeleton.get_bone_pose_rotation(2)
				var newRotation = Quaternion(chest_rotation,currentSkeleton.y,currentSkeleton.z,currentSkeleton.w)
				skeleton.set_bone_pose_rotation(2,newRotation)
			else:
				$CanvasLayer/crosshair.visible=false
				cameraTarget.position=lerp(cameraTarget.position,camera_positions["normalPos"],0.1)
				
		"R":
			var aimBlendAmount:float = $AnimationTree.get("parameters/R/aim/blend_amount")
			
			if Input.is_action_pressed("aim") and is_on_floor():
				var new_blend_amount = clamp(aimBlendAmount + 0.1, aimBlendAmount, 1.0)
				$AnimationTree.set("parameters/R/aim/blend_amount", new_blend_amount)
				rifle.position=rifle_transform["initPos"]
				rifle.rotation_degrees=rifle_transform["initRot"]
				if Input.is_action_pressed("jab") and rifle.can_shoot:
					rifle.can_shoot=false
					rifle.timer.start()
					var aim_target = $CameraController/CameraTarget/RayCast3D.get_collision_point()
					if aim_target != Vector3.ZERO:
						var bullet = BULLET.instantiate()
						bullet.target=aim_target
						rifle.get_node("Marker3D").add_child(bullet)
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
				$CanvasLayer/crosshair.visible=true
				cameraTarget.position=lerp(cameraTarget.position,camera_positions["aimingPos"],0.1)
				rotation.y=lerp_angle(rotation.y,$CameraController.rotation.y,0.25)
				$Armature.rotation.y=lerp_angle($Armature.rotation.y,0,0.25)
				var chest_rotation = Vector3.ZERO
				if $CameraController.rotation_degrees.x<-5:
					chest_rotation=deg_to_rad(5)+0.25
				elif $CameraController.rotation_degrees.x>30:
					chest_rotation=deg_to_rad(-30)+0.25
				else:
					chest_rotation=-$CameraController.rotation.x+0.25
				var currentSkeleton = skeleton.get_bone_pose_rotation(2)
				var newRotation = Quaternion(chest_rotation,currentSkeleton.y,currentSkeleton.z,currentSkeleton.w)
				skeleton.set_bone_pose_rotation(2,newRotation)
			else:
				$CanvasLayer/crosshair.visible=false
				cameraTarget.position=lerp(cameraTarget.position,camera_positions["normalPos"],0.1)


	if Input.is_action_pressed("run"):
		SPEED = lerp(SPEED,4.0,0.1)
		playerNavigationState=playerNavigationStates.RUNNING
	else:
		SPEED = lerp(SPEED,2.0,0.1)
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
		child.get_child(0).visible = false
	parent.get_child(ind).get_child(0).visible = true 

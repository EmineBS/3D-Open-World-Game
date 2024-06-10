extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	$car.playerEnterCarArea.connect(playerEnterCarArea)
	$car.playerExitCarArea.connect(playerExitCarArea)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if Input.is_action_just_pressed("enterCar"):
		if $Character.playerCarState == $Character.playerCarStates.CAN_ENTER_CAR:
			$Character.camera.current=false
			$car.camera.current=true
			$Character.playerCarState=$Character.playerCarStates.INCAR
			$Character.visible=false
			$Character.collision.disabled=true
		elif $Character.playerCarState == $Character.playerCarStates.INCAR:
			$Character.camera.current=true
			$car.camera.current=false
			$Character.playerCarState=$Character.playerCarStates.CAN_ENTER_CAR
			$Character.position=$car.position-Vector3(-2,0,0)
			$Character.visible=true
			$Character.collision.disabled=false

func playerEnterCarArea():
	$Character.playerCarState=$Character.playerCarStates.CAN_ENTER_CAR
	$car.enterCarLabel.visible=true

func playerExitCarArea():
	if $Character.playerCarState != $Character.playerCarStates.INCAR:
		$Character.playerCarState=$Character.playerCarStates.CANT_ENTER_CAR
	$car.enterCarLabel.visible=false

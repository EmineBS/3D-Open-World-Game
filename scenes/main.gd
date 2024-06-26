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
		if $tommy.playerCarState == $tommy.playerCarStates.CAN_ENTER_CAR:
			$tommy.camera.current=false
			$car.camera.current=true
			$tommy.playerCarState=$tommy.playerCarStates.INCAR
			$tommy.visible=false
			$tommy.collision.disabled=true
		elif $tommy.playerCarState == $tommy.playerCarStates.INCAR:
			$tommy.camera.current=true
			$car.camera.current=false
			$tommy.playerCarState=$tommy.playerCarStates.CAN_ENTER_CAR
			$tommy.position=$car.position-Vector3(-2,0,0)
			$tommy.visible=true
			$tommy.collision.disabled=false

func playerEnterCarArea():
	$tommy.playerCarState=$tommy.playerCarStates.CAN_ENTER_CAR
	$car.enterCarLabel.visible=true

func playerExitCarArea():
	if $tommy.playerCarState != $tommy.playerCarStates.INCAR:
		$tommy.playerCarState=$tommy.playerCarStates.CANT_ENTER_CAR
	$car.enterCarLabel.visible=false

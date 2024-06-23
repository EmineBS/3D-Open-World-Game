extends Node3D


@onready var timer = $Timer

var can_shoot = true

func _on_timer_timeout():
	can_shoot = true

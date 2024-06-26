extends Node3D

var speed = 1000
var target = null

func _process(delta):
	if target!=null:
		if not top_level:
			top_level=true
		global_position=lerp(global_position,target,0.9)

func _on_timer_timeout():
	queue_free()

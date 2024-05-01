extends Camera3D

@onready var cam_rig = $"../CamRig"

func _process(delta):
	position.x = lerp(position.x, cam_rig.position.x, 6 * delta)
	position.y = lerp(position.y, cam_rig.position.y, 6 * delta)

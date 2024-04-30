extends Camera3D

@onready var cam_rig = $"../CamRig"

func _process(delta):
	position.x = lerp(position.x, cam_rig.position.x, 6 * delta)
	position.z = lerp(position.z, cam_rig.position.z, 6 * delta)

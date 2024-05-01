extends Node3D

@onready var camera = $"../Camera"
@onready var grid = $"../grid_generation"

@onready var viewSize = get_viewport().size
@onready var lastPos = get_viewport().get_mouse_position()
@onready var zoomTgt = 140

func _ready():
	position = Vector3(grid.grid_width, grid.grid_height, 0)

func _process(delta):
	zoomTgt = clamp(zoomTgt, 20, 140)
	camera.size = lerpf(camera.size, zoomTgt, 4 * delta)

func _input(event):
	if (event is InputEventMouseButton):
		if (event.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			zoomTgt += 10.0
		elif (event.button_index == MOUSE_BUTTON_WHEEL_UP):
			zoomTgt -= 10.0
	if (event is InputEventMouseMotion):
		if (Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)):
			var currMousePos = get_viewport().get_mouse_position()
			if ((currMousePos.x < 0 or currMousePos.x > viewSize.x)
			or (currMousePos.y < 0 or currMousePos.y > viewSize.y)):
				currMousePos.x = wrap(currMousePos.x, 0, viewSize.x)
				currMousePos.y = wrap(currMousePos.y, 0, viewSize.y)
				get_viewport().warp_mouse(currMousePos)
			else:
				position.x -= (currMousePos.x-lastPos.x)*remap(zoomTgt, 0, 200, 0.08, 1)
				position.y -= (currMousePos.y-lastPos.y)*remap(zoomTgt, 0, 200, 0.08, 1)
			lastPos = currMousePos
		else: lastPos = get_viewport().get_mouse_position()



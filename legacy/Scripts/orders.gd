extends Node

const ORDER_AREA = preload("res://Scenes/order_area.tscn")

@onready var alpha = $".."

var mouse_pos
var orders = 0
var max_orders = 10

func _input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_mouse"):
			mouse_pos = floor(get_viewport().get_mouse_position() * 0.25)
			print(mouse_pos)
			if mouse_pos > Vector2(10, 10) and mouse_pos < Vector2(alpha.grid_width-10, alpha.grid_height-10):
				if orders < max_orders:
					var new = ORDER_AREA.instantiate()
					
					print("order sent")
				else:
					print("max orders")
			else:
				print("outside bounds")

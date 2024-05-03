extends Node

const ORDER = preload("res://World Generation/assets/order.tscn")

@onready var grid = $"../grid_generation"

func _input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("left_mouse"):
			var mouse_pos = get_viewport().get_mouse_position() * 0.25
			if (mouse_pos.x > 10 and mouse_pos.x < grid.grid_width-10 and
				mouse_pos.y > 10 and mouse_pos.y < grid.grid_height-10):
				var new = ORDER.instantiate()
				new.position.x = floor(mouse_pos).x * 2
				new.position.y = floor(mouse_pos).y * 2
				add_child(new)
				print(new.position)

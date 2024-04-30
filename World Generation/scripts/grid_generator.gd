@tool

extends GridMap

@export var generate_world : bool
@export var clear_world : bool

@export var grid_width = 192
@export var grid_height = 96

@export var world_seed = 0

@export_range(0.005, 0.05) var frequency = 0.015

@export_range(0, 1) var grass = 0.82
@export_range(0, 1) var dirt = 0.5
@export_range(0, 1) var covert = 0.48
@export_range(0, 1) var coast = 0.85

const TREE = preload("res://World Generation/assets/tree.tscn")

enum type {COVERT, DIRT, GRASS, WATER}

var noise
var rng

var dojo_pos
var road_edges = []

func _process(delta):
	
	if generate_world:
		generate_ground()
		generate_world = false
		print("generating grid...")
	if clear_world:
		grid_clear()
		clear_world = false
		print("clearing grid...")

func grid_clear():
		
	clear()
	
	for child in get_children():
		child.queue_free()

func generate_ground():
	
	grid_clear()
	
	noise = FastNoiseLite.new()
	rng = RandomNumberGenerator.new()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.frequency = frequency
	noise.seed = world_seed
	
	if world_seed == 0:
		noise.seed = rng.randi()
	for x in grid_width:
		for y in grid_height:
			if noise.get_noise_2d(x, y) > -covert:
				set_cell_item(Vector3(x, 0, y), type.COVERT)
			elif noise.get_noise_2d(x, y) > -dirt:
				set_cell_item(Vector3(x, 0, y), type.DIRT)
			elif noise.get_noise_2d(x, y) > -grass:
				set_cell_item(Vector3(x, 0, y), type.GRASS)
			elif noise.get_noise_2d(x, y) > -coast:
				set_cell_item(Vector3(x, 0, y), type.DIRT)
			else:
				set_cell_item(Vector3(x, 0, y), type.WATER)
	generate_road()

func generate_road():
	var choosen
	var edges_amount
	var list = []
	
	#number of road to generate on the world
	edges_amount = rng.randi_range(2, 4)
	
	for x in grid_width:
		for y in grid_height:
			# must be near the center
			if (Vector2(x, y) > Vector2(32, 64)
			and Vector2(x, y) < Vector2(grid_width-32, grid_height-64)):
				list.append(Vector3i(x, 0, y))
	#choose random position
	choosen = list.pick_random()
	dojo_pos = choosen
	#generate open area around dojo
	for i in 5:
		set_cell_item(choosen + Vector3i(i-2, 0, 3), type.DIRT)
		set_cell_item(choosen + Vector3i(i-2, 0, -3), type.DIRT)
	for k in 5:
		for l in 7:
			set_cell_item(choosen + Vector3i(l-3, 0, k-2), type.DIRT)
	set_cell_item(choosen, type.WATER)
	#
	#func generate_edges():
	#edges = [Vector2(randi_range(20, grid_width-20), grid_height-1), # top
			 #Vector2(randi_range(20, grid_width-20), 0), # down
			 #Vector2(grid_width-1, randi_range(20, grid_height-20)), # left
			 #Vector2(0, randi_range(20, grid_height-20))] # right
	#for edge in edges:
		#world_grid[edge]["type"] = type.DIRT
	#for edge in edges_amount:
		#pass

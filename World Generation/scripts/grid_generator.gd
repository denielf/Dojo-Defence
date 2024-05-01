@tool

extends GridMap

@export var generate : bool
@export var delete : bool

@export var grid_width = 192
@export var grid_height = 96

@export var world_seed = 0

@export_range(0.005, 0.1) var frequency = 0.05

@export_range(0, 1) var grass = 0.82
@export_range(0, 1) var dirt = 0.5
@export_range(0, 1) var covert = 0.48

const TREE = preload("res://World Generation/assets/tree.tscn")

enum type {COVERT, DIRT, GRASS, WATER}

var noise
var rng

var dojo_pos
var road_edges = []

func _process(delta):
	
	if generate:
		print("generating grid...")
		generate_world()
		generate = false
	if delete:
		print("clearing grid...")
		grid_clear()
		delete = false

func grid_clear():
	clear()
	for child in get_children():
		child.queue_free()

func generate_world():
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
			if noise.get_noise_2d(x, y) > -grass:
				set_cell_item(Vector3(x, 0, y), type.GRASS)
			elif noise.get_noise_2d(x, y) > -dirt:
				set_cell_item(Vector3(x, 0, y), type.DIRT)
			elif noise.get_noise_2d(x, y) > -covert:
				set_cell_item(Vector3(x, 0, y), type.COVERT)
			else:
				set_cell_item(Vector3(x, 0, y), type.WATER)
	
	generate_road()

func distance(v3_1, v3_2):
	var pos1 = Vector3(v3_1.x, v3_1.y, v3_1.z).distance_to(Vector3(v3_2.x, v3_2.y, v3_2.z))
	return(pos1)

func arrived(curr, target):
	if distance(curr, target) > 1:
		return(false)

func cardinal(curr):
	var neighbors = [curr + Vector3i.FORWARD, curr + Vector3i.BACK,
					 curr + Vector3i.LEFT, curr + Vector3i.RIGHT]
	if neighbors[2].x < 1 :#and neighbors[n].z > 2 and neighbors[n].z < grid_height-2:
		neighbors = [curr + Vector3i.LEFT, curr + Vector3i.FORWARD, curr + Vector3i.BACK]
		return(neighbors)
	elif neighbors[0].z < 1 :#and neighbors[n].x > 2 and neighbors[n].x < grid_width-2:
		neighbors = [curr + Vector3i.BACK, curr + Vector3i.LEFT, curr + Vector3i.RIGHT]
		return(neighbors)
	elif neighbors[3].x > grid_width-2 :#and neighbors[n].z > 2 and neighbors[n].z < grid_height-2:
		neighbors = [curr + Vector3i.LEFT, curr + Vector3i.FORWARD, curr + Vector3i.BACK]
		return(neighbors)
	elif neighbors[1].z > grid_height-2 :#and neighbors[n].x > 2 and neighbors[n].x < grid_width-2:
		neighbors = [curr + Vector3i.FORWARD, curr + Vector3i.LEFT, curr + Vector3i.RIGHT]
		return(neighbors)
	else:
		return(neighbors)

func generate_road():
	dojo_pos = null
	#positions avaliable for dojo
	var list = []
	for x in grid_width:
		for y in grid_height:
			# must be near the center
			if (x > 32 and x < grid_width-32
			and y > 32 and y < grid_height-32
			and get_cell_item(Vector3i(x, 0, y)) == type.GRASS):
				list.append(Vector3i(x, 0, y))
	#choose random position
	var choosen = list.pick_random()
	dojo_pos = choosen
	#generate open area around dojo
	for i in 5:
		set_cell_item(choosen + Vector3i(i-2, 0, 3), type.DIRT)
		set_cell_item(choosen + Vector3i(i-2, 0, -3), type.DIRT)
	for k in 5:
		for l in 7:
			set_cell_item(choosen + Vector3i(l-3, 0, k-2), type.DIRT)
	#
	var edges = [Vector3i(rng.randi_range(20, grid_width-20), 0, grid_height-1), # top
				 Vector3i(rng.randi_range(20, grid_width-20), 0, 0), # down
				 Vector3i(grid_width-1, 0, rng.randi_range(20, grid_height-20)), # left
				 Vector3i(0, 0, rng.randi_range(20, grid_height-20))] # right
	#number of edges to generate on the world
	road_edges.clear()
	var edges_amount = rng.randi_range(2, 4)
	for e in edges_amount:
		var pop
		var sort = edges
		sort.shuffle()
		pop = sort.pop_front()
		road_edges.append(pop)
		set_cell_item(road_edges[e], type.DIRT)
	
	#generate roads
	for edge in road_edges:
		#starting from the dojo
		var current = dojo_pos
		var stuck = 0
		#go to edge
		while arrived(current, edge) == false:
			#probe directions
			var dir = cardinal(current)
			var rating = {}
			var best1 = {}
			var best2 = {}
			var sort = []
			for i in dir.size():
				rating[i] = {"coord": dir[i],
							"distance": distance(dir[i], edge),
							"cost": distance(dir[i], edge) + cost(dir[i])}
			best1 = rating[0]
			best2 = rating[1]
			#sort best direction
			for j in rating.size():
				if rating[j]["cost"] < best1["cost"]:
					best1 = rating[j]
			for k in rating.size():
				if rating[k]["cost"] < best2["cost"] and rating[k]["cost"] > best1["cost"]:
					best2 = rating[k]
			sort.append(best1["coord"])
			sort.append(best2["coord"])
			current = sort.pick_random()
			set_cell_item(current, type.DIRT)
			if stuck > 2000:
				print("stuck")
				break
			stuck += 1

func cost(coord):
	var type = get_cell_item(coord)
	match type:
		0: #forest
			return(0.5)
		1: #dirt 
			return(0)
		2: #grass
			return(0)
		_: #water
			return(3)

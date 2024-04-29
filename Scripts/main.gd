extends Node3D

const TREE = preload("res://Scenes/tree.tscn")
const TREES = preload("res://Scenes/trees.tscn")
const GRASS = preload("res://Scenes/grass.tscn")
const FOREST = preload("res://Scenes/forest.tscn")
const DIRT = preload("res://Scenes/dirt.tscn")
const DOJO = preload("res://Scenes/dojo.tscn")

@onready var noise = $noise
@onready var trees = $trees
@onready var world = $ground

var world_save_path = "user://world_grid.save"

var tile_size = 2
var grid_width = 192
var grid_height = 96

var world_grid = {}
var edges = []

var dojo_pos

enum type {DIRT, GRASS, FOREST, DOJO, EDGE, WATER}

func _ready():
	generate_ground()

func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("ui_accept"):
			get_tree().reload_current_scene()
		if event.is_action("save"):
			save_grid()
		if event.is_action("load"):
			load_grid()
			draw_trees()
			draw_tiles()

func generate_ground():
	noise_map()
	init_tiles()
	spawn_forest_tile(2720)
	expand_tiles(type.FOREST, 3, 10)
	expand_tiles(type.GRASS, 2, 10)
	generate_dojo()
	generate_edges()
	generate_road()
	draw_tiles()
	draw_trees()

func noise_map():
	# noise texture over the entire world
	var texture = NoiseTexture2D.new()
	texture.noise = FastNoiseLite.new()
	texture.color_ramp = Gradient.new()
	texture.color_ramp.set_color(0, Color.WHITE)
	texture.color_ramp.set_color(1, Color.GRAY)
	texture.noise.set("noise_type", "Perlin")
	texture.noise.set("seed", randi())
	texture.noise.set("frequency", 0.5)
	texture.height = 96
	texture.width = 192
	await texture.changed
	noise.get_surface_override_material(0).set("albedo_texture", texture)

func init_tiles():
	for w in grid_width:
		for h in grid_height:
			world_grid[Vector2(w, h)] = {
				"coord": Vector2(w, h),
				"type": type.GRASS,
				"entity": 0,
				"adress": null}

func spawn_forest_tile(amount):
	var list = []
	for g in world_grid:
		list.append(world_grid[g]["coord"])
	for a in amount:
		var current = list.pick_random()
		world_grid[current]["type"] = type.FOREST
		if current > Vector2(0, 0) and current < Vector2(grid_width-1, grid_height-1):
			if current.y > 0:
				world_grid[current - Vector2(0,1)]["type"] = type.FOREST
			if current.y < grid_height-1:
				world_grid[current + Vector2(0,1)]["type"] = type.FOREST
			if current.x > 0:
				world_grid[current - Vector2(1, 0)]["type"] = type.FOREST
			if current.x < grid_width-1:
				world_grid[current + Vector2(1, 0)]["type"] = type.FOREST

func expand_tiles(type, threshold, probability):
	for g in world_grid:
		var count = 0
		if g.x > 0: #W
			if world_grid[g - Vector2(1, 0)]["type"] == type:
				count += 1
		if g.x < grid_width-1: #E
			if world_grid[g + Vector2(1, 0)]["type"] == type:
				count += 1
		if g.y > 0: #N
			if world_grid[g - Vector2(0, 1)]["type"] == type:
				count += 1
		if g.y < grid_height-1: #S
			if world_grid[g + Vector2(0, 1)]["type"] == type:
				count += 1
		if g.x > 0 and g.y > 0: #NW
			if world_grid[g - Vector2(1, 1)]["type"] == type:
				count += 1
		if g.x < grid_width-1 and g.y < grid_height-1: #SE
			if world_grid[g + Vector2(1, 1)]["type"] == type:
				count += 1
		if g.x < grid_width-1 and g.y > 0: #NE
			if world_grid[g - Vector2(-1, 1)]["type"] == type:
				count += 1
		if g.x > 0 and g.y < grid_height-1: #SW
			if world_grid[g + Vector2(-1, 1)]["type"] == type:
				count += 1
		if count > threshold and randi_range(0, probability) > 0:
			world_grid[g]["type"] = type

func cardinal(curr):
	var neighbors = [curr + Vector2.UP, curr + Vector2.DOWN,
					 curr + Vector2.LEFT, curr + Vector2.RIGHT]
	if neighbors[3].x > 1 and neighbors[2].y > 1 and neighbors[1].x < grid_width-2 and neighbors[0].y < grid_height-2:
		neighbors = [curr + Vector2.UP, curr + Vector2.DOWN,
					 curr + Vector2.LEFT, curr + Vector2.RIGHT]
		return(neighbors)
	elif neighbors[2].x < 1 :#and neighbors[n].y > 2 and neighbors[n].y < grid_height-2:
		neighbors = [curr + Vector2.RIGHT, curr + Vector2.UP, curr + Vector2.DOWN]
		return(neighbors)
	elif neighbors[0].y < 1 :#and neighbors[n].x > 2 and neighbors[n].x < grid_width-2:
		neighbors = [curr + Vector2.DOWN, curr + Vector2.LEFT, curr + Vector2.RIGHT]
		return(neighbors)
	elif neighbors[3].x > grid_width-2 :#and neighbors[n].y > 2 and neighbors[n].y < grid_height-2:
		neighbors = [curr + Vector2.LEFT, curr + Vector2.UP, curr + Vector2.DOWN]
		return(neighbors)
	elif neighbors[1].y > grid_height-2 :#and neighbors[n].x > 2 and neighbors[n].x < grid_width-2:
		neighbors = [curr + Vector2.UP, curr + Vector2.LEFT, curr + Vector2.RIGHT]
		return(neighbors)
	else:
		print("invalid", neighbors)
		return(null)

func arrived(curr):
	if curr.distance_to(dojo_pos) > 3:
		return(false)

func generate_dojo():
	var choosen
	var list = []
	for g in world_grid:# must be near the center
		if (world_grid[g]["coord"].x > 31 and world_grid[g]["coord"].x < grid_width-32
		and world_grid[g]["coord"].y > 31 and world_grid[g]["coord"].y < grid_height-32):
			list.append(world_grid[g]["coord"])
	choosen = list.pick_random()
	dojo_pos = choosen
	#generate open area around dojo
	for i in 5:
		world_grid[choosen + Vector2(i-2, 3)]["type"] = type.DIRT
		world_grid[choosen + Vector2(i-2, -3)]["type"] = type.DIRT
	for k in 5:
		for l in 7:
			world_grid[choosen + Vector2(l-3, k-2)]["type"] = type.DIRT
	world_grid[choosen]["type"] = type.DOJO

func generate_edges():
	edges = [Vector2(randi_range(20, grid_width-20), grid_height-1), # top
			 Vector2(randi_range(20, grid_width-20), 0), # down
			 Vector2(grid_width-1, randi_range(20, grid_height-20)), # left
			 Vector2(0, randi_range(20, grid_height-20))] # right
	for edge in edges:
		world_grid[edge]["type"] = type.DIRT

func generate_road():
	#for each edge
	for edge in edges:
		var id = 0
		var current = edge
		#while not arrived
		while arrived(current) == false:
			id += 1
			var sorted = []
			var distance = {}
			#returns only 3 sides if near a edge
			var clamped = cardinal(current)
			#probe distance to dojo on four directions
			for dir in clamped.size():
				distance[dir] = {"coord": clamped[dir], "distance": clamped[dir].distance_to(dojo_pos),
				  "cost": (world_grid[clamped[dir]]["type"]*0.25) + clamped[dir].distance_to(dojo_pos)}
			#sort based on shortest path
			var short1 = distance[0]
			var short2 = distance[1]
			for sort1 in clamped.size():
				if distance[sort1]["cost"] < short1["cost"]:
					short1 = distance[sort1]
			for sort2 in clamped.size():
				if distance[sort2]["cost"] < short2["cost"] and distance[sort2]["cost"] > short1["cost"]:
					short2 = distance[sort2]
			sorted.append(short1)
			sorted.append(short2)
			#choose between the two closest paths
			var choosen = sorted.pick_random()
			world_grid[current]["type"] = type.DIRT
			world_grid[current]["adress"] = Vector3(edge.x, id, edge.y)
			current = choosen["coord"]

func draw_tiles():
	for children in world.get_children():
		children.queue_free()
	for i in world_grid:
		if world_grid[i]["type"] == type.GRASS:
			var new = GRASS.instantiate()
			new.position.x = i.x * tile_size
			new.position.z = i.y * tile_size
			world.add_child(new)
		elif world_grid[i]["type"] == type.FOREST:
			var new = FOREST.instantiate()
			new.position.x = i.x * tile_size
			new.position.z = i.y * tile_size
			world.add_child(new)
		elif world_grid[i]["type"] == type.DIRT:
			var new = DIRT.instantiate()
			new.position.x = i.x * tile_size
			new.position.z = i.y * tile_size
			world.add_child(new)
		elif world_grid[i]["type"] == type.EDGE:
			var new = DIRT.instantiate()
			new.position.x = i.x * tile_size
			new.position.z = i.y * tile_size
			world.add_child(new)
		elif world_grid[i]["type"] == type.DOJO:
			var new = DOJO.instantiate()
			new.position.x = i.x * tile_size
			new.position.z = i.y * tile_size
			world.add_child(new)

func draw_trees():
	for children in trees.get_children():
		children.queue_free()
	for g in world_grid:
		if world_grid[g]["type"] == type.FOREST:
			var rand = randi_range(0, 2)
			var rand_y = randf_range(-45, 45)
			if rand == 0:
				var new = TREE.instantiate()
				new.rotation_degrees.y = rand_y
				new.position.x = world_grid[g]["coord"].x * tile_size
				new.position.z = world_grid[g]["coord"].y * tile_size
				trees.add_child(new)
			elif rand >= 1:
				var new = TREES.instantiate()
				new.rotation_degrees.y = rand_y
				new.position.x = world_grid[g]["coord"].x * tile_size
				new.position.z = world_grid[g]["coord"].y * tile_size
				trees.add_child(new)

func save_grid():
	FileAccess.open(world_save_path, FileAccess.WRITE).store_var(world_grid)
	print("world saved")
	
func load_grid():
	if FileAccess.file_exists(world_save_path):
		world_grid = FileAccess.open(world_save_path, FileAccess.READ).get_var()
		print("world loaded")
	else:
		print("file not found")

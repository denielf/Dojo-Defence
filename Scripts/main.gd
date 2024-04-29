extends Node3D

const TREE = preload("res://Scenes/tree.tscn")
const TREES = preload("res://Scenes/trees.tscn")
const TREE_LOD = preload("res://Scenes/tree_lod.tscn")
const GRASS = preload("res://Scenes/grass.tscn")
const MOSS = preload("res://Scenes/moss.tscn")
const DIRT = preload("res://Scenes/dirt.tscn")

@onready var lod = $lod
@onready var trees = $trees
@onready var roads = $roads
@onready var ground = $ground
@onready var groundMesh = $MeshInstance3D
@onready var light = $DirectionalLight3D
@onready var cam_rig = $CamRig

var dojo_pos
var edges = []
var tile_size = 2
var grid_width = 192
var grid_height = 96
var grid_ground = {}
var grid_road = {}
enum type {DIRT, GRASS, MOSS, EDGE, DOJO}

func _ready():
	generate_ground()

func _process(_delta):
	if cam_rig.zoomTgt > 140:
		light.shadow_enabled = false
	else:
		light.shadow_enabled = true
	if cam_rig.zoomTgt > 180:
		lod.set_visible(true)
		trees.set_visible(false)
	else:
		lod.set_visible(false)
		trees.set_visible(true)

func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("reload"):
			get_tree().reload_current_scene()

#func generate_ground():
	#groundMesh.get_surface_override_material(0).set("albedo_texture", GROUND)
	#var texture = NoiseTexture2D.new()
	#texture.noise = FastNoiseLite.new()
	#texture.color_ramp = Gradient.new()
	#texture.color_ramp.set_color(0, Color("#6d6f26", 255))
	#texture.color_ramp.set_color(1, Color("#69601f", 255))
	#texture.noise.set("noise_type", "Perlin")
	#texture.noise.set("seed", randi())
	#texture.noise.set("frequency", 0.01)
	#texture.height = 2048
	#texture.width = 4096
	#await texture.changed

func generate_ground():
	init_tiles()
	spawn_moss_tile(2720)
	grow_moss_tiles()
	grow_grass_tiles()
	#collapse_tiles()
	road_seed()
	dojo_seed()
	draw_road()
	draw_tiles()
	draw_trees()

func init_tiles():
	for w in grid_width:
		for h in grid_height:
			grid_ground[Vector2(w, h)] = {
				"coord": Vector2(w, h),
				"type": type.GRASS}
			grid_road[Vector2(w, h)] = {
				"coord": Vector2(w, h),
				"type": null,
				"entity": 0}

func spawn_moss_tile(amount):
	var list = []
	for g in grid_ground:
		list.append(grid_ground[g]["coord"])
	for a in amount:
		var current = list.pick_random()
		grid_ground[current]["type"] = type.MOSS
		if current >= Vector2(0, 0) && current <= Vector2(grid_width-1, grid_height-1):
			if current.y > 0:
				grid_ground[current - Vector2(0,1)]["type"] = type.MOSS
			if current.y < grid_height-1:
				grid_ground[current + Vector2(0,1)]["type"] = type.MOSS
			if current.x > 0:
				grid_ground[current - Vector2(1, 0)]["type"] = type.MOSS
			if current.x < grid_width-1:
				grid_ground[current + Vector2(1, 0)]["type"] = type.MOSS

func grow_moss_tiles(): # 1 in 10 don't grow
	for g in grid_ground:
		var count = 0
		if g.x > 0: #W
			if grid_ground[g - Vector2(1, 0)]["type"] == type.MOSS:
				count += 1
		if g.x < grid_width-1: #E
			if grid_ground[g + Vector2(1, 0)]["type"] == type.MOSS:
				count += 1
		if g.y > 0: #N
			if grid_ground[g - Vector2(0, 1)]["type"] == type.MOSS:
				count += 1
		if g.y < grid_height-1: #S
			if grid_ground[g + Vector2(0, 1)]["type"] == type.MOSS:
				count += 1
		if g.x > 0 and g.y > 0: #NW
			if grid_ground[g - Vector2(1, 1)]["type"] == type.MOSS:
				count += 1
		if g.x < grid_width-1 and g.y < grid_height-1: #SE
			if grid_ground[g + Vector2(1, 1)]["type"] == type.MOSS:
				count += 1
		if g.x < grid_width-1 and g.y > 0: #NE
			if grid_ground[g - Vector2(-1, 1)]["type"] == type.MOSS:
				count += 1
		if g.x > 0 and g.y < grid_height-1: #SW
			if grid_ground[g + Vector2(-1, 1)]["type"] == type.MOSS:
				count += 1
		if count > 3 && randi_range(0, 10) > 0:
			grid_ground[g]["type"] = type.MOSS

func grow_grass_tiles(): # 1 in 10 don't grow
	for g in grid_ground:
		var count = 0
		if g.x > 0: #W
			if grid_ground[g - Vector2(1, 0)]["type"] == type.GRASS:
				count += 1
		if g.x < grid_width-1: #E
			if grid_ground[g + Vector2(1, 0)]["type"] == type.GRASS:
				count += 1
		if g.y > 0: #N
			if grid_ground[g - Vector2(0, 1)]["type"] == type.GRASS:
				count += 1
		if g.y < grid_height-1: #S
			if grid_ground[g + Vector2(0, 1)]["type"] == type.GRASS:
				count += 1
		if g.x > 0 and g.y > 0: #NW
			if grid_ground[g - Vector2(1, 1)]["type"] == type.GRASS:
				count += 1
		if g.x < grid_width-1 and g.y < grid_height-1: #SE
			if grid_ground[g + Vector2(1, 1)]["type"] == type.GRASS:
				count += 1
		if g.x < grid_width-1 and g.y > 0: #NE
			if grid_ground[g - Vector2(-1, 1)]["type"] == type.GRASS:
				count += 1
		if g.x > 0 and g.y < grid_height-1: #SW
			if grid_ground[g + Vector2(-1, 1)]["type"] == type.GRASS:
				count += 1
		if count > 2 && randi_range(0, 10) > 0:
			grid_ground[g]["type"] = type.GRASS

func collapse_tiles(): # 1 in 100 don't collapse
	for g in grid_ground:
		var count = 0
		if g.x > 0: #W
			if grid_ground[g - Vector2(1, 0)]["type"] == type.GRASS:
				count += 1
		if g.x < grid_width-1: #E
			if grid_ground[g + Vector2(1, 0)]["type"] == type.GRASS:
				count += 1
		if g.y > 0: #N
			if grid_ground[g - Vector2(0, 1)]["type"] == type.GRASS:
				count += 1
		if g.y < grid_height-1: #S
			if grid_ground[g + Vector2(0, 1)]["type"] == type.GRASS:
				count += 1
		if g.x > 0 and g.y > 0: #NW
			if grid_ground[g - Vector2(1, 1)]["type"] == type.GRASS:
				count += 1
		if g.x < grid_width-1 and g.y < grid_height-1: #SE
			if grid_ground[g + Vector2(1, 1)]["type"] == type.GRASS:
				count += 1
		if g.x < grid_width-1 and g.y > 0: #NE
			if grid_ground[g - Vector2(-1, 1)]["type"] == type.GRASS:
				count += 1
		if g.x > 0 and g.y < grid_height-1: #SW
			if grid_ground[g + Vector2(-1, 1)]["type"] == type.GRASS:
				count += 1
		if count > 4 && randi_range(0, 100) > 0:
			grid_ground[g]["type"] = type.GRASS

func dojo_seed():
	var list = []
	var choosen
	for g in grid_ground:# must be near the center
		if grid_ground[g]["coord"].x > 31 and grid_ground[g]["coord"].x < grid_width-32 and grid_ground[g]["coord"].y > 31 and grid_ground[g]["coord"].y < grid_height-32:
			list.append(grid_ground[g]["coord"])
	choosen = list.pick_random()
	grid_ground[choosen + Vector2(-1,-1)]["type"] = type.DIRT
	grid_ground[choosen + Vector2(0,-1)]["type"] = type.DIRT
	grid_ground[choosen + Vector2(1,-1)]["type"] = type.DIRT
	grid_ground[choosen + Vector2(-1,0)]["type"] = type.DIRT
	grid_ground[choosen + Vector2(1,0)]["type"] = type.DIRT
	grid_ground[choosen + Vector2(-1,1)]["type"] = type.DIRT
	grid_ground[choosen + Vector2(0,1)]["type"] = type.DIRT
	grid_ground[choosen + Vector2(1,1)]["type"] = type.DIRT
	grid_ground[choosen]["type"] = type.DOJO
	
	dojo_pos = choosen

func road_seed():
	edges = [Vector2(randi_range(20, grid_width-20), 2), # top
			 Vector2(randi_range(20, grid_width-20),grid_height-3), # down
			 Vector2(grid_width-3, randi_range(20, grid_height-20)), # left
			 Vector2(2, randi_range(20, grid_height-20))] # right
	# edge-cases. ha! get it?
	var cases = [Vector2(0, -1), Vector2(0, -2),# top
				Vector2(0, 1), Vector2(0, 2),# down
				Vector2(1, 0), Vector2(2, 0),# left
				Vector2(-1, 0), Vector2(-2, 0),]# right
	for edge in edges.size():
		grid_ground[edges[edge]]["type"] = type.EDGE
		grid_ground[edges[edge]+cases[edge*2]]["type"] = type.EDGE
		grid_ground[edges[edge]+cases[(edge*2)+1]]["type"] = type.EDGE

func draw_road():
	for children in roads.get_children():
		children.queue_free()
	#for each edge
	for edge in edges:
		var current = edge
		#while not arrived
		while arrived(current) == false:
			#probe distance to dojo on four directions
			var sorted = []
			var clamped = []
			var distance = {}
			var cardinal = [current + Vector2.UP,
							current + Vector2.DOWN,
							current + Vector2.LEFT,
							current + Vector2.RIGHT]
			for c in cardinal:
				clamped.append(Vector2(clamp(c.x, 1, grid_width-1), clamp(c.y, 1, grid_height-1)))
			for dir in 4:
				distance[dir] = {"coord": clamped[dir],
								 "distance": clamped[dir].distance_to(dojo_pos),
								 "cost": grid_ground[clamped[dir]]["type"] + clamped[dir].distance_to(dojo_pos)}
			#sort based on shortest path
			var short1 = distance[0]
			var short2 = distance[1]
			for sort1 in 4:
				if distance[sort1]["cost"] < short1["cost"]:
					short1 = distance[sort1]
			for sort2 in 4:
				if distance[sort2]["cost"] < short2["cost"] and distance[sort2]["cost"] > short1["cost"]:
					short2 = distance[sort2]
			sorted.append(short1)
			sorted.append(short2)
			#choose between the two closest paths
			var choosen = sorted.pick_random()
			#instantiate tile on that choosen position
			var new = DIRT.instantiate()
			grid_road[current]["type"] = type.DIRT
			new.position.x = grid_road[current]["coord"].x * tile_size
			new.position.z = grid_road[current]["coord"].y * tile_size
			#name tile based on side and tile count
			new.name = str("edge_", edge,"_road_", current)
			roads.add_child(new)
			current = choosen["coord"]

func arrived(curr):
	if curr.distance_to(dojo_pos) > 3:
		return(false)

func probe_type(tile):
	return(grid_ground[tile]["type"])

func draw_trees():
	for g in grid_ground:
		if grid_ground[g]["type"] == type.MOSS and grid_road[g]["type"] == null:
			var rand = randi_range(0, 4)
			var rand_y = randf_range(-45, 45)
			var new_lod = TREE_LOD.instantiate()
			new_lod.position.x = grid_ground[g]["coord"].x * tile_size
			new_lod.position.z = grid_ground[g]["coord"].y * tile_size
			new_lod.rotation_degrees.y = rand_y
			lod.add_child(new_lod)
			if rand == 0:
				var new = TREE.instantiate()
				new.rotation_degrees.y = rand_y
				new.position.x = grid_ground[g]["coord"].x * tile_size
				new.position.z = grid_ground[g]["coord"].y * tile_size
				trees.add_child(new)
			elif rand >= 1:
				var new = TREES.instantiate()
				new.rotation_degrees.y = rand_y
				new.position.x = grid_ground[g]["coord"].x * tile_size
				new.position.z = grid_ground[g]["coord"].y * tile_size
				trees.add_child(new)

func draw_tiles():
	for children in ground.get_children():
		children.queue_free()
	for i in grid_ground:
		if grid_ground[i]["type"] == type.GRASS:
			var new = GRASS.instantiate()
			new.position.x = i.x * tile_size
			new.position.z = i.y * tile_size
			ground.add_child(new)
		elif grid_ground[i]["type"] == type.MOSS:
			var new = MOSS.instantiate()
			new.position.x = i.x * tile_size
			new.position.z = i.y * tile_size
			ground.add_child(new)
		elif grid_ground[i]["type"] == type.DIRT:
			var new = DIRT.instantiate()
			new.position.x = i.x * tile_size
			new.position.z = i.y * tile_size
			ground.add_child(new)
		elif grid_ground[i]["type"] == type.EDGE:
			var new = DIRT.instantiate()
			new.position.x = i.x * tile_size
			new.position.z = i.y * tile_size
			ground.add_child(new)
		elif grid_ground[i]["type"] == type.DOJO:
			var new = DIRT.instantiate()
			new.position.x = (i.x * tile_size) - 2
			new.position.z = (i.y * tile_size) - 2
			ground.add_child(new)

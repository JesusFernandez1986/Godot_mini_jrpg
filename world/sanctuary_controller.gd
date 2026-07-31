class_name SanctuaryController
extends Node2D

signal interaction_requested(kind: String)

const WALK_SPEED := 150.0
const RUN_SPEED := 235.0
const START_POSITION := Vector2(315, 400)
const COLLISION_TILE_TEXTURE: Texture2D = preload("res://assets/forest_sanctuary_hd2d.png")
const WORLD_BOUNDS := Rect2(76, 84, 808, 402)
const OBSTACLES := [
	Rect2(350, 86, 142, 76),
	Rect2(622, 188, 116, 78),
	Rect2(354, 296, 92, 58),
	Rect2(720, 356, 96, 66)
]
const OCCLUSION_RECTS := [
	Rect2(345, 75, 155, 98),
	Rect2(612, 176, 140, 102),
	Rect2(708, 343, 118, 89)
]
const INTERACTIONS := {
	"chest": Vector2(255, 235),
	"mechanism": Vector2(575, 205),
	"altar": Vector2(485, 124)
}
const WORLD_PROFILES := {
	"sanctuary": {
		"bounds": WORLD_BOUNDS,
		"obstacles": OBSTACLES,
		"occlusion": OCCLUSION_RECTS,
		"interactions": INTERACTIONS,
		"start": START_POSITION
	},
	"valdoria": {
		"bounds": Rect2(62, 86, 836, 410),
		"obstacles": [Rect2(76, 91, 205, 118), Rect2(680, 92, 202, 112), Rect2(340, 88, 128, 73), Rect2(512, 88, 107, 72)],
		"occlusion": [Rect2(70, 84, 220, 136), Rect2(670, 84, 220, 132)],
		"interactions": {
			"npc_captain": Vector2(477, 180), "npc_archivist": Vector2(304, 255),
			"npc_healer": Vector2(605, 253), "npc_guard": Vector2(773, 304),
			"npc_blacksmith": Vector2(203, 329), "npc_baker": Vector2(358, 363),
			"npc_child": Vector2(518, 334), "npc_mason": Vector2(648, 374),
			"npc_veteran": Vector2(792, 423), "npc_minister": Vector2(145, 421),
			"dungeon_gate": Vector2(477, 112), "world_gate": Vector2(477, 474)
		},
		"start": Vector2(477, 438)
	},
	"dungeon": {
		"bounds": Rect2(52, 70, 856, 428),
		"obstacles": [Rect2(255, 72, 76, 105), Rect2(530, 72, 88, 105), Rect2(700, 260, 72, 92), Rect2(350, 365, 120, 70)],
		"occlusion": [Rect2(250, 66, 88, 118), Rect2(522, 66, 104, 118), Rect2(692, 252, 88, 108)],
		"interactions": {
			"seal_west": Vector2(216, 192), "seal_east": Vector2(752, 191),
			"lost_ledger": Vector2(362, 286), "moonleaf": Vector2(604, 401),
			"dungeon_exit": Vector2(105, 452)
		},
		"start": Vector2(112, 438)
	}
}

var player: CharacterBody2D
var navigation_agent: NavigationAgent2D
var collision_tilemap: TileMapLayer
var collision_source_id := -1
var pathfinder := AStarGrid2D.new()
var active := false
var movement_state := "idle"
var facing_direction := "south"
var animation_elapsed := 0.0
var last_input := Vector2.ZERO
var is_running := false
var active_profile := "sanctuary"
var world_bounds: Rect2 = WORLD_BOUNDS
var obstacles: Array = OBSTACLES.duplicate()
var occlusion_rects: Array = OCCLUSION_RECTS.duplicate()
var interaction_points: Dictionary = INTERACTIONS.duplicate()
var world_collision_nodes: Array[StaticBody2D] = []

func _ready() -> void:
	create_player()
	create_collision_tilemap()
	create_boundaries()
	create_navigation_grid()
	set_active(false)

func configure_world(profile_id: String) -> bool:
	if not WORLD_PROFILES.has(profile_id):
		return false
	active_profile = profile_id
	var profile: Dictionary = WORLD_PROFILES[profile_id]
	world_bounds = profile["bounds"] as Rect2
	obstacles = (profile["obstacles"] as Array).duplicate(true)
	occlusion_rects = (profile["occlusion"] as Array).duplicate(true)
	interaction_points = (profile["interactions"] as Dictionary).duplicate(true)
	if is_inside_tree():
		for body in world_collision_nodes:
			if is_instance_valid(body):
				body.queue_free()
		world_collision_nodes.clear()
		if collision_tilemap != null:
			collision_tilemap.clear()
		create_boundaries()
		create_navigation_grid()
	return true

func profile_start_position(profile_id: String = active_profile) -> Vector2:
	if not WORLD_PROFILES.has(profile_id):
		return START_POSITION
	return WORLD_PROFILES[profile_id]["start"] as Vector2

func create_player() -> void:
	player = CharacterBody2D.new()
	player.name = "ArenCharacterBody2D"
	player.collision_layer = 1
	player.collision_mask = 1
	var shape := CollisionShape2D.new()
	var capsule := CapsuleShape2D.new()
	capsule.radius = 8.0
	capsule.height = 20.0
	shape.shape = capsule
	shape.position = Vector2(0, -4)
	player.add_child(shape)
	navigation_agent = NavigationAgent2D.new()
	navigation_agent.name = "NavigationAgent2D"
	navigation_agent.path_desired_distance = 8.0
	navigation_agent.target_desired_distance = 12.0
	player.add_child(navigation_agent)
	add_child(player)
	player.position = START_POSITION

func create_collision_tilemap() -> void:
	collision_tilemap = TileMapLayer.new()
	collision_tilemap.name = "SanctuaryCollisionTileMap"
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(32, 32)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, 1)
	tile_set.set_physics_layer_collision_mask(0, 1)
	var atlas_source := TileSetAtlasSource.new()
	atlas_source.texture = COLLISION_TILE_TEXTURE
	atlas_source.texture_region_size = Vector2i(32, 32)
	atlas_source.create_tile(Vector2i.ZERO)
	collision_source_id = tile_set.add_source(atlas_source)
	var tile_data := atlas_source.get_tile_data(Vector2i.ZERO, 0)
	tile_data.set_collision_polygons_count(0, 1)
	tile_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-16, -16), Vector2(16, -16), Vector2(16, 16), Vector2(-16, 16)
	]))
	collision_tilemap.tile_set = tile_set
	collision_tilemap.visible = false
	add_child(collision_tilemap)
	move_child(collision_tilemap, 0)

func create_boundaries() -> void:
	var thickness := 32.0
	create_static_rect(Rect2(world_bounds.position - Vector2(thickness, thickness), Vector2(world_bounds.size.x + thickness * 2.0, thickness)))
	create_static_rect(Rect2(Vector2(world_bounds.position.x - thickness, world_bounds.end.y), Vector2(world_bounds.size.x + thickness * 2.0, thickness)))
	create_static_rect(Rect2(Vector2(world_bounds.position.x - thickness, world_bounds.position.y), Vector2(thickness, world_bounds.size.y)))
	create_static_rect(Rect2(Vector2(world_bounds.end.x, world_bounds.position.y), Vector2(thickness, world_bounds.size.y)))
	for obstacle in obstacles:
		create_static_rect(obstacle)

func create_static_rect(rectangle: Rect2) -> void:
	var body := StaticBody2D.new()
	body.name = "WorldCollision"
	body.collision_layer = 1
	body.collision_mask = 1
	var collision := CollisionShape2D.new()
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = rectangle.size
	collision.shape = rectangle_shape
	collision.position = rectangle.get_center()
	body.add_child(collision)
	add_child(body)
	world_collision_nodes.append(body)

func create_navigation_grid() -> void:
	pathfinder.region = Rect2i(0, 0, 30, 17)
	pathfinder.cell_size = Vector2(32, 32)
	pathfinder.offset = Vector2(16, 16)
	pathfinder.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	pathfinder.update()
	for y in pathfinder.region.size.y:
		for x in pathfinder.region.size.x:
			var id := Vector2i(x, y)
			var center := pathfinder.get_point_position(id)
			var blocked := not world_bounds.has_point(center)
			if not blocked:
				for obstacle in obstacles:
					if obstacle.grow(10.0).has_point(center):
						blocked = true
						break
			pathfinder.set_point_solid(id, blocked)
			if blocked:
				collision_tilemap.set_cell(id, collision_source_id, Vector2i.ZERO, 0)

func set_active(value: bool) -> void:
	active = value
	set_physics_process(value)
	if player != null:
		player.collision_layer = 1 if value else 0
		player.collision_mask = 1 if value else 0
		if not value:
			player.velocity = Vector2.ZERO

func set_player_position(value: Vector2) -> void:
	if player != null:
		player.position = value

func player_position() -> Vector2:
	return player.position if player != null else START_POSITION

func _physics_process(_delta: float) -> void:
	if not active or player == null:
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	apply_input(input_vector, Input.is_action_pressed("run"))
	player.move_and_slide()

func apply_input(input_vector: Vector2, running: bool) -> void:
	last_input = input_vector
	var iso_direction := isometric_direction(input_vector)
	is_running = running and iso_direction.length_squared() > 0.01
	if iso_direction.length_squared() <= 0.01:
		player.velocity = Vector2.ZERO
		movement_state = "idle"
		return
	var direction := iso_direction.normalized()
	facing_direction = CharacterAnimationSystem.direction_from_vector(direction, facing_direction)
	movement_state = "run" if is_running else "walk"
	player.velocity = direction * (RUN_SPEED if is_running else WALK_SPEED)

static func isometric_direction(input_vector: Vector2) -> Vector2:
	return Vector2(input_vector.x - input_vector.y, (input_vector.x + input_vector.y) * 0.52)

func safe_motion_step(current: Vector2, input_vector: Vector2, running: bool, delta: float) -> Vector2:
	var iso_direction := isometric_direction(input_vector)
	if iso_direction.length_squared() <= 0.01:
		return current
	var speed := RUN_SPEED if running else WALK_SPEED
	var motion := iso_direction.normalized() * speed * maxf(delta, 0.0)
	var candidate := current + motion
	if not collides_with_world(candidate):
		return candidate
	var slide_x := current + Vector2(motion.x, 0)
	if not collides_with_world(slide_x):
		return slide_x
	var slide_y := current + Vector2(0, motion.y)
	return slide_y if not collides_with_world(slide_y) else current

func update_animation(delta: float) -> void:
	animation_elapsed += maxf(delta, 0.0)

func nearest_interaction(maximum_distance: float = 48.0) -> String:
	var closest := ""
	var closest_distance := maximum_distance
	for kind in interaction_points:
		var distance := player_position().distance_to(interaction_points[kind])
		if distance <= closest_distance:
			closest = str(kind)
			closest_distance = distance
	return closest

func request_interaction() -> String:
	var kind := nearest_interaction()
	if not kind.is_empty():
		interaction_requested.emit(kind)
	return kind

func navigation_path_to(target: Vector2) -> PackedVector2Array:
	var start_id := world_to_grid(player_position())
	var target_id := world_to_grid(target)
	if pathfinder.is_point_solid(start_id) or pathfinder.is_point_solid(target_id):
		return PackedVector2Array()
	return pathfinder.get_point_path(start_id, target_id)

func world_to_grid(world_position: Vector2) -> Vector2i:
	var local := world_position - pathfinder.offset
	return Vector2i(
		clampi(int(floor(local.x / pathfinder.cell_size.x)), pathfinder.region.position.x, pathfinder.region.end.x - 1),
		clampi(int(floor(local.y / pathfinder.cell_size.y)), pathfinder.region.position.y, pathfinder.region.end.y - 1)
	)

func collides_with_world(point: Vector2) -> bool:
	if not world_bounds.has_point(point):
		return true
	for obstacle in obstacles:
		if obstacle.has_point(point):
			return true
	return false

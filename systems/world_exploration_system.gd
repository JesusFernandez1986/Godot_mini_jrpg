class_name WorldExplorationSystem
extends RefCounted

const MAP_BOUNDS := Rect2(72, 102, 816, 352)
const WALK_SPEED := 92.0
const RUN_SPEED := 138.0
const MINUTES_PER_SECOND := 5.0
const PERIODS := ["amanecer", "día", "atardecer", "noche"]

const REGIONS := {
	"heartlands": {"name":"Campiñas de Ámbar", "weather":["despejado", "bruma", "lluvia suave"]},
	"highlands": {"name":"Cumbres de Ceniza", "weather":["ceniza", "viento", "tormenta"]},
	"coast": {"name":"Costa Astral", "weather":["despejado", "lluvia", "temporal"]},
	"forest": {"name":"Bosque de los Nombres", "weather":["bruma", "lluvia suave", "luceros"]},
	"sanctuary": {"name":"Corazón de Eryndor", "weather":["aurora", "bruma prismática", "despejado"]}
}

const LANDMARKS := [
	{"id":"ember_grotto", "name":"Gruta de las Ascuas", "type":"landmark", "kind":"cueva", "position":Vector2(382, 174), "region":"highlands", "required_chapter":2, "hidden":true, "transport":"land", "enemy":"amber_wisp", "description":"Una cueva donde el mineral canta antes de fundirse."},
	{"id":"eira_ruins", "name":"Ruinas de Eira", "type":"landmark", "kind":"ruinas", "position":Vector2(354, 352), "region":"heartlands", "required_chapter":1, "hidden":true, "transport":"land", "enemy":"hollow_sentinel", "description":"Columnas borradas rodean un juramento escrito bajo el musgo."},
	{"id":"star_tower", "name":"Torre de las Estrellas", "type":"landmark", "kind":"torre", "position":Vector2(666, 178), "region":"coast", "required_chapter":3, "hidden":true, "transport":"land", "enemy":"stone_gargoyle", "description":"Un observatorio quebrado aún sigue el curso de una estrella imposible."},
	{"id":"moonwood", "name":"Bosque de la Luna Baja", "type":"landmark", "kind":"bosque", "position":Vector2(628, 394), "region":"forest", "required_chapter":4, "hidden":true, "transport":"land", "enemy":"shadow_ent", "description":"Sus senderos cambian cuando nadie pronuncia su nombre."},
	{"id":"iron_fortress", "name":"Fortaleza del Juramento", "type":"landmark", "kind":"fortaleza", "position":Vector2(760, 408), "region":"forest", "required_chapter":4, "hidden":false, "transport":"land", "enemy":"oathbreaker_knight", "description":"Un bastión fronterizo dividido entre la ley y la memoria."},
	{"id":"veiled_isle", "name":"Isla del Velo", "type":"landmark", "kind":"isla", "position":Vector2(866, 162), "region":"coast", "required_chapter":3, "hidden":true, "transport":"ship", "enemy":"veil_cultist", "description":"La marea revela sus escalinatas solamente bajo la luz astral."}
]

const DANGER_ZONES := [
	{"id":"wolves_road", "position":Vector2(294, 250), "radius":30.0, "region":"heartlands", "enemy":"lunar_wolf"},
	{"id":"ash_wisps", "position":Vector2(440, 205), "radius":27.0, "region":"highlands", "enemy":"amber_wisp"},
	{"id":"coastal_gargoyles", "position":Vector2(720, 250), "radius":29.0, "region":"coast", "enemy":"stone_gargoyle"},
	{"id":"named_roots", "position":Vector2(565, 408), "radius":30.0, "region":"forest", "enemy":"shadow_ent"}
]

const ROUTES := {
	"valdoria":["brumaforja", "eira_ruins"],
	"brumaforja":["valdoria", "ember_grotto", "star_tower"],
	"ember_grotto":["brumaforja"],
	"eira_ruins":["valdoria", "sylvaran", "sanctuary"],
	"star_tower":["brumaforja", "celestia"],
	"celestia":["star_tower", "iron_fortress", "veiled_isle"],
	"sylvaran":["eira_ruins", "moonwood", "sanctuary"],
	"moonwood":["sylvaran", "iron_fortress"],
	"iron_fortress":["moonwood", "celestia"],
	"sanctuary":["eira_ruins", "sylvaran"],
	"veiled_isle":["celestia"]
}

const BLOCKED_TERRAIN := [
	{"rect":Rect2(820, 102, 68, 352), "requires":"ship"},
	{"rect":Rect2(470, 102, 76, 46), "requires":"never"}
]

static func create_state() -> Dictionary:
	var state := {
		"position":[235.0, 300.0],
		"day":1,
		"clock_minutes":480.0,
		"weather_by_region":{},
		"discovered":["valdoria"],
		"explored":[],
		"camped_regions":[],
		"fast_travel":["valdoria"],
		"ship_unlocked":false,
		"danger_cooldowns":{},
		"defeated_encounters":[],
		"last_safe_location":"valdoria",
		"return_points":{},
		"steps":0
	}
	refresh_weather(state)
	return state

static func all_locations(base_locations: Array) -> Array:
	var result := base_locations.duplicate(true)
	for landmark in LANDMARKS:
		result.append(landmark.duplicate(true))
	for location in result:
		if not location.has("region"):
			location["region"] = region_for_position(location["position"] as Vector2)
		if not location.has("hidden"): location["hidden"] = false
		if not location.has("transport"): location["transport"] = "land"
	return result

static func position(state: Dictionary) -> Vector2:
	var stored: Variant = state.get("position", [235.0, 300.0])
	if stored is Vector2: return stored as Vector2
	if stored is Array and (stored as Array).size() >= 2:
		return Vector2(float(stored[0]), float(stored[1]))
	return Vector2(235, 300)

static func set_position(state: Dictionary, value: Vector2) -> void:
	state["position"] = [value.x, value.y]

static func region_for_position(value: Vector2) -> String:
	if value.distance_to(Vector2(480, 290)) < 78.0: return "sanctuary"
	if value.y < 235.0 and value.x < 610.0: return "highlands"
	if value.x > 650.0: return "coast"
	if value.y > 350.0: return "forest"
	return "heartlands"

static func move(state: Dictionary, input: Vector2, delta: float, running: bool = false) -> Vector2:
	if input.length_squared() <= 0.0001: return position(state)
	var direction := input.normalized()
	var speed := RUN_SPEED if running else WALK_SPEED
	var current := position(state)
	var target := current + direction * speed * maxf(0.0, delta)
	if can_occupy(target, state):
		set_position(state, target)
		state["steps"] = int(state.get("steps", 0)) + 1
		advance_time(state, delta * MINUTES_PER_SECOND * (1.35 if running else 1.0))
	return position(state)

static func can_occupy(value: Vector2, state: Dictionary) -> bool:
	if not MAP_BOUNDS.has_point(value): return false
	for terrain in BLOCKED_TERRAIN:
		if (terrain["rect"] as Rect2).has_point(value):
			var requirement := str(terrain["requires"])
			if requirement == "never" or (requirement == "ship" and not bool(state.get("ship_unlocked", false))):
				return false
	return true

static func advance_time(state: Dictionary, minutes: float) -> void:
	var clock := float(state.get("clock_minutes", 480.0)) + maxf(0.0, minutes)
	var previous_day := int(state.get("day", 1))
	while clock >= 1440.0:
		clock -= 1440.0
		state["day"] = int(state.get("day", 1)) + 1
	state["clock_minutes"] = clock
	if int(state["day"]) != previous_day: refresh_weather(state)

static func period(state: Dictionary) -> String:
	var hour := int(float(state.get("clock_minutes", 480.0)) / 60.0)
	if hour >= 5 and hour < 8: return "amanecer"
	if hour >= 8 and hour < 18: return "día"
	if hour >= 18 and hour < 21: return "atardecer"
	return "noche"

static func time_label(state: Dictionary) -> String:
	var total := int(float(state.get("clock_minutes", 480.0)))
	return "Día %d · %02d:%02d · %s" % [int(state.get("day", 1)), total / 60, total % 60, period(state).capitalize()]

static func refresh_weather(state: Dictionary) -> void:
	var weather: Dictionary = {}
	var day := int(state.get("day", 1))
	for region_id in REGIONS:
		var choices: Array = REGIONS[region_id]["weather"]
		var seed_value: int = absi((str(region_id) + ":" + str(day)).hash())
		weather[region_id] = choices[seed_value % choices.size()]
	state["weather_by_region"] = weather

static func weather(state: Dictionary, region: String = "") -> String:
	var resolved_region := region if REGIONS.has(region) else region_for_position(position(state))
	return str((state.get("weather_by_region", {}) as Dictionary).get(resolved_region, "despejado"))

static func synchronize_progress(state: Dictionary, unlocked: Array, chapter: int) -> void:
	if chapter >= 3: state["ship_unlocked"] = true
	for location_id in unlocked:
		discover(state, str(location_id))
	for landmark in LANDMARKS:
		if not bool(landmark["hidden"]) and chapter >= int(landmark["required_chapter"]):
			discover(state, str(landmark["id"]))

static func discover(state: Dictionary, location_id: String) -> bool:
	var discovered: Array = state.get("discovered", []) as Array
	if location_id in discovered: return false
	discovered.append(location_id)
	return true

static func discover_nearby(state: Dictionary, chapter: int, radius: float = 52.0) -> Array[String]:
	var found: Array[String] = []
	var current := position(state)
	for landmark in LANDMARKS:
		var id := str(landmark["id"])
		if id in (state.get("discovered", []) as Array): continue
		if chapter < int(landmark["required_chapter"]): continue
		if current.distance_to(landmark["position"] as Vector2) <= radius:
			discover(state, id)
			found.append(id)
	return found

static func nearest_location(state: Dictionary, locations: Array, allowed: Array = [], radius: float = 42.0) -> Dictionary:
	var nearest: Dictionary = {}
	var nearest_distance := radius
	for location in locations:
		var id := str(location.get("id", ""))
		if not allowed.is_empty() and id not in allowed: continue
		if bool(location.get("hidden", false)) and id not in (state.get("discovered", []) as Array): continue
		var distance := position(state).distance_to(location["position"] as Vector2)
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest = location as Dictionary
	return nearest

static func can_enter(state: Dictionary, location: Dictionary, chapter: int, unlocked: Array) -> bool:
	var id := str(location.get("id", ""))
	if chapter < int(location.get("required_chapter", 0)): return false
	if bool(location.get("hidden", false)) and id not in (state.get("discovered", []) as Array): return false
	if str(location.get("transport", "land")) == "ship" and not bool(state.get("ship_unlocked", false)): return false
	return id in unlocked or id in (state.get("discovered", []) as Array)

static func danger_at_position(state: Dictionary) -> Dictionary:
	var now := int(state.get("day", 1)) * 1440 + int(float(state.get("clock_minutes", 0.0)))
	for zone in DANGER_ZONES:
		var cooldown := int((state.get("danger_cooldowns", {}) as Dictionary).get(str(zone["id"]), 0))
		if now < cooldown: continue
		if position(state).distance_to(zone["position"] as Vector2) <= float(zone["radius"]): return zone
	return {}

static func resolve_danger(state: Dictionary, encounter_id: String) -> void:
	var now := int(state.get("day", 1)) * 1440 + int(float(state.get("clock_minutes", 0.0)))
	(state.get("danger_cooldowns", {}) as Dictionary)[encounter_id] = now + 360
	var defeated_encounters: Array = state.get("defeated_encounters", []) as Array
	if encounter_id not in defeated_encounters: defeated_encounters.append(encounter_id)

static func camp(state: Dictionary, locations: Array) -> Dictionary:
	if not danger_at_position(state).is_empty():
		return {"success":false, "message":"No es seguro acampar dentro de una zona de peligro."}
	var region := region_for_position(position(state))
	var camped: Array = state.get("camped_regions", []) as Array
	if region not in camped: camped.append(region)
	var nearest := nearest_location(state, locations, state.get("discovered", []) as Array, 105.0)
	if not nearest.is_empty():
		var id := str(nearest["id"])
		var fast: Array = state.get("fast_travel", []) as Array
		if id not in fast: fast.append(id)
		state["last_safe_location"] = id
	var clock := float(state.get("clock_minutes", 0.0))
	if clock >= 360.0: state["day"] = int(state.get("day", 1)) + 1
	state["clock_minutes"] = 360.0
	refresh_weather(state)
	return {"success":true, "message":"El grupo acampa hasta el amanecer. El campamento queda como punto de viaje rápido.", "region":region}

static func fast_travel(state: Dictionary, location: Dictionary) -> Dictionary:
	var id := str(location.get("id", ""))
	if id not in (state.get("fast_travel", []) as Array): return {"success":false, "message":"Aún no has establecido un campamento junto a ese destino."}
	if str(location.get("transport", "land")) == "ship" and not bool(state.get("ship_unlocked", false)): return {"success":false, "message":"Necesitas un barco para alcanzar ese destino."}
	set_position(state, location["position"] as Vector2)
	advance_time(state, 120.0)
	state["last_safe_location"] = id
	return {"success":true, "message":"Viaje rápido completado hasta %s." % str(location.get("name", id))}

static func explore_landmark(state: Dictionary, landmark_id: String) -> bool:
	var explored: Array = state.get("explored", []) as Array
	if landmark_id in explored: return false
	explored.append(landmark_id)
	return true

static func route_between(origin: String, destination: String, state: Dictionary, chapter: int) -> Array[String]:
	if origin == destination: return [origin]
	var queue: Array = [[origin]]
	var visited: Array[String] = [origin]
	while not queue.is_empty():
		var path: Array = queue.pop_front()
		var current := str(path[-1])
		for neighbor_value in ROUTES.get(current, []) as Array:
			var neighbor := str(neighbor_value)
			if neighbor in visited: continue
			var landmark := landmark_by_id(neighbor)
			if not landmark.is_empty():
				if chapter < int(landmark["required_chapter"]): continue
				if str(landmark["transport"]) == "ship" and not bool(state.get("ship_unlocked", false)): continue
			visited.append(neighbor)
			var next_path := path.duplicate()
			next_path.append(neighbor)
			if neighbor == destination: return next_path
			queue.append(next_path)
	return []

static func landmark_by_id(location_id: String) -> Dictionary:
	for landmark in LANDMARKS:
		if str(landmark["id"]) == location_id: return landmark
	return {}

static func validate(state: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for field in ["position", "day", "clock_minutes", "weather_by_region", "discovered", "explored", "camped_regions", "fast_travel", "ship_unlocked", "danger_cooldowns", "defeated_encounters", "last_safe_location", "return_points", "steps"]:
		if not state.has(field): errors.append("Estado mundial sin campo %s." % field)
	if not can_occupy(position(state), state): errors.append("La posición mundial está fuera del terreno transitable.")
	if float(state.get("clock_minutes", -1.0)) < 0.0 or float(state.get("clock_minutes", 1441.0)) >= 1440.0: errors.append("La hora mundial no es válida.")
	var known: Array[String] = ["valdoria", "brumaforja", "celestia", "sylvaran", "sanctuary"]
	for landmark in LANDMARKS: known.append(str(landmark["id"]))
	for id in (state.get("discovered", []) as Array) + (state.get("fast_travel", []) as Array) + (state.get("explored", []) as Array):
		if str(id) not in known: errors.append("Localización mundial desconocida: %s." % str(id))
	for region in REGIONS:
		if not (state.get("weather_by_region", {}) as Dictionary).has(region): errors.append("Falta clima para %s." % region)
	return errors

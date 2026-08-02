class_name DungeonExplorationSystem
extends RefCounted

const TILE_WALL := "#"
const TILE_FLOOR := "."
const TILE_START := "S"
const TILE_EXIT := "E"
const INTERACTIVE_TILES := ["K", "M", "P", "N", "R", "T", "C", "B", "X"]
const DUNGEON_IDS := ["eira_ruins", "ember_grotto", "star_tower", "moonwood", "iron_fortress", "veiled_isle"]
const DUNGEON_OPENINGS := {
	"eira_ruins":[[], [], []],
	"ember_grotto":[[Vector2i(4, 2)], [Vector2i(6, 1)], [Vector2i(6, 4)]],
	"star_tower":[[Vector2i(8, 3)], [Vector2i(8, 4)], [Vector2i(2, 3)]],
	"moonwood":[[Vector2i(4, 4)], [Vector2i(2, 4)], [Vector2i(6, 4)]],
	"iron_fortress":[[Vector2i(6, 2)], [Vector2i(6, 3)], [Vector2i(4, 2)]],
	"veiled_isle":[[Vector2i(2, 2)], [Vector2i(3, 2)], [Vector2i(8, 2)]]
}
const DUNGEON_THEMES := {
	"eira_ruins":{"floor":Color("31445a"), "hidden":Color("172231"), "line":Color("73879a"), "accent":Color("ffe18a")},
	"ember_grotto":{"floor":Color("593528"), "hidden":Color("281b1d"), "line":Color("b76848"), "accent":Color("ff9b63")},
	"star_tower":{"floor":Color("283d63"), "hidden":Color("141d38"), "line":Color("759de8"), "accent":Color("b899ff")},
	"moonwood":{"floor":Color("294b3b"), "hidden":Color("14271f"), "line":Color("67a780"), "accent":Color("81e5ad")},
	"iron_fortress":{"floor":Color("474b55"), "hidden":Color("20242c"), "line":Color("9a806d"), "accent":Color("ef726f")},
	"veiled_isle":{"floor":Color("234c59"), "hidden":Color("112730"), "line":Color("59bfd2"), "accent":Color("70dbe8")}
}
const PATROL_CELLS := [Vector2i(3, 1), Vector2i(4, 1), Vector2i(7, 1)]

const ABILITIES := {
	"aren": {"id":"push", "name":"Fuerza del juramento", "verb":"mover monolitos"},
	"lyra": {"id":"decipher", "name":"Lectura astral", "verb":"descifrar glifos"},
	"brom": {"id":"break", "name":"Martillo rúnico", "verb":"quebrar muros frágiles"},
	"seris": {"id":"track", "name":"Rastro lunar", "verb":"revelar sendas ocultas"},
	"naia": {"id":"sail", "name":"Paso de mareas", "verb":"cruzar corrientes interiores"},
	"kael": {"id":"shadowstep", "name":"Paso de sombra", "verb":"atravesar rejas veladas"},
	"mira": {"id":"attune", "name":"Canto de runas", "verb":"armonizar mecanismos antiguos"},
	"orin": {"id":"grapple", "name":"Garfio de reliquias", "verb":"alcanzar cornisas"}
}

const FLOOR_LAYOUTS := [
	[
		"###########",
		"#S..N.....#",
		"#.#.###.#.#",
		"#.#..K..#.#",
		"#...#.#...#",
		"#P..M.C..E#",
		"###########"
	],
	[
		"###########",
		"#S....#...#",
		"#.##P.#.#.#",
		"#..T..#R#.#",
		"#.#.###.#.#",
		"#...N.C..E#",
		"###########"
	],
	[
		"###########",
		"#S..B.....#",
		"#.#.###.#.#",
		"#.#..X..#.#",
		"#...#.#...#",
		"#N..P....E#",
		"###########"
	]
]

const DUNGEONS := {
	"eira_ruins": {"name":"Ruinas de Eira", "region":"praderas", "ability":"push", "floor_abilities":["push", "attune", "push"], "keeper":"La Matriarca de Piedra", "secret_boss":"Eira sin Rostro", "enemy":"stone_gargoyle"},
	"ember_grotto": {"name":"Gruta de las Ascuas", "region":"montaña", "ability":"break", "floor_abilities":["break", "grapple", "break"], "keeper":"Salamandra del Yunque", "secret_boss":"El Primer Fuelle", "enemy":"oathbreaker_knight"},
	"star_tower": {"name":"Torre de las Estrellas", "region":"costa", "ability":"decipher", "floor_abilities":["decipher", "grapple", "decipher"], "keeper":"Astrolabio Viviente", "secret_boss":"La Estrella Caída", "enemy":"amber_wisp"},
	"moonwood": {"name":"Bosque de la Luna Baja", "region":"bosque", "ability":"track", "floor_abilities":["track", "attune", "track"], "keeper":"Ciervo de Savia Gris", "secret_boss":"La Raíz que Sueña", "enemy":"shadow_ent"},
	"iron_fortress": {"name":"Fortaleza del Juramento", "region":"frontera", "ability":"shadowstep", "floor_abilities":["shadowstep", "push", "shadowstep"], "keeper":"Alcaide sin Bandera", "secret_boss":"El Juramento Encadenado", "enemy":"hollow_sentinel"},
	"veiled_isle": {"name":"Isla del Velo", "region":"mar", "ability":"sail", "floor_abilities":["sail", "decipher", "sail"], "keeper":"Leviatán de Cristal", "secret_boss":"La Marea sin Nombre", "enemy":"hollow_lion"}
}

static func create_state() -> Dictionary:
	return {
		"active_dungeon":"",
		"floor":0,
		"position":[1, 1],
		"visited":{},
		"opened_chests":[],
		"triggered_traps":[],
		"keys":[],
		"mechanisms":[],
		"solved_puzzles":[],
		"shortcuts":[],
		"defeated_minibosses":[],
		"defeated_secret_bosses":[],
		"completed_dungeons":[],
		"revealed_secrets":[],
		"steps":0
	}

static func dungeon(dungeon_id: String) -> Dictionary:
	return (DUNGEONS.get(dungeon_id, {}) as Dictionary).duplicate(true)

static func enter(state: Dictionary, dungeon_id: String) -> Dictionary:
	if not DUNGEONS.has(dungeon_id):
		return {"success":false, "message":"Mazmorra desconocida."}
	state["active_dungeon"] = dungeon_id
	state["floor"] = 0
	state["position"] = vector_to_array(find_tile(0, TILE_START, dungeon_id))
	visit(state, 0, array_to_vector(state["position"] as Array))
	return {"success":true, "message":"Entras en %s. El automapa registra la entrada." % DUNGEONS[dungeon_id]["name"]}

static func leave(state: Dictionary) -> void:
	state["active_dungeon"] = ""
	state["floor"] = 0
	state["position"] = [1, 1]

static func current_floor(state: Dictionary) -> int:
	return clampi(int(state.get("floor", 0)), 0, FLOOR_LAYOUTS.size() - 1)

static func position(state: Dictionary) -> Vector2i:
	var raw: Variant = state.get("position", [1, 1])
	return array_to_vector(raw as Array) if raw is Array else Vector2i(1, 1)

static func floor_layout(floor_index: int, dungeon_id: String = "eira_ruins") -> Array:
	var safe_floor := clampi(floor_index, 0, FLOOR_LAYOUTS.size() - 1)
	var layout: Array = FLOOR_LAYOUTS[safe_floor].duplicate()
	var openings: Array = (DUNGEON_OPENINGS.get(dungeon_id, DUNGEON_OPENINGS["eira_ruins"]) as Array)[safe_floor] as Array
	for opening in openings:
		var cell: Vector2i = opening
		var row := str(layout[cell.y])
		if cell.x > 0 and cell.x < row.length() - 1:
			layout[cell.y] = row.substr(0, cell.x) + TILE_FLOOR + row.substr(cell.x + 1)
	return layout

static func tile_at(floor_index: int, cell: Vector2i, dungeon_id: String = "eira_ruins") -> String:
	var layout := floor_layout(floor_index, dungeon_id)
	if cell.y < 0 or cell.y >= layout.size(): return TILE_WALL
	var row := str(layout[cell.y])
	if cell.x < 0 or cell.x >= row.length(): return TILE_WALL
	return row.substr(cell.x, 1)

static func is_walkable(floor_index: int, cell: Vector2i, dungeon_id: String = "eira_ruins") -> bool:
	return tile_at(floor_index, cell, dungeon_id) != TILE_WALL

static func move(state: Dictionary, direction: Vector2i) -> Dictionary:
	if str(state.get("active_dungeon", "")).is_empty():
		return {"success":false, "message":"No hay una mazmorra activa."}
	var step := Vector2i(clampi(direction.x, -1, 1), clampi(direction.y, -1, 1))
	if absi(step.x) + absi(step.y) != 1:
		return {"success":false, "message":"Movimiento inválido."}
	var target := position(state) + step
	var dungeon_id := str(state.get("active_dungeon", "eira_ruins"))
	if not is_walkable(current_floor(state), target, dungeon_id):
		return {"success":false, "message":"El paso está bloqueado por piedra antigua."}
	state["position"] = vector_to_array(target)
	state["steps"] = int(state.get("steps", 0)) + 1
	visit(state, current_floor(state), target)
	var tile := tile_at(current_floor(state), target, dungeon_id)
	var patrol := patrol_at(state, current_floor(state), target)
	if not patrol.is_empty():
		return {"success":true, "kind":"encounter", "message":"Una patrulla visible te corta el paso.", "tile":tile, "position":target, "encounter_id":patrol["id"], "enemy":patrol["enemy"]}
	return {"success":true, "message":tile_hint(tile), "tile":tile, "position":target}

static func interact(state: Dictionary, available_abilities: Array[String] = []) -> Dictionary:
	var dungeon_id := str(state.get("active_dungeon", ""))
	if dungeon_id.is_empty(): return {"success":false, "message":"No hay nada que explorar."}
	var floor_index := current_floor(state)
	var cell := position(state)
	var tile := tile_at(floor_index, cell, dungeon_id)
	var object_id := object_key(dungeon_id, floor_index, cell)
	match tile:
		TILE_START:
			if floor_index == 0: return {"success":true, "kind":"leave", "message":"La salida conduce de nuevo al mapa mundial."}
			state["floor"] = floor_index - 1
			state["position"] = vector_to_array(find_tile(floor_index - 1, TILE_EXIT, dungeon_id))
			visit(state, current_floor(state), position(state))
			return {"success":true, "kind":"floor", "message":"Desciendes a la planta anterior."}
		TILE_EXIT:
			if floor_index < FLOOR_LAYOUTS.size() - 1:
				state["floor"] = floor_index + 1
				state["position"] = vector_to_array(find_tile(floor_index + 1, TILE_START, dungeon_id))
				visit(state, current_floor(state), position(state))
				return {"success":true, "kind":"floor", "message":"Accedes a la planta %d." % (floor_index + 2)}
			var completed: Array = state.get("completed_dungeons", []) as Array
			if dungeon_id not in completed: completed.append(dungeon_id)
			return {"success":true, "kind":"complete", "message":"Has completado %s sin cerrar ninguna ruta." % DUNGEONS[dungeon_id]["name"]}
		"K":
			if object_id in (state.get("keys", []) as Array): return {"success":false, "message":"El pedestal de la llave está vacío."}
			(state["keys"] as Array).append(object_id)
			return {"success":true, "kind":"key", "message":"Obtienes una llave de mecanismo."}
		"M":
			if object_id in (state.get("mechanisms", []) as Array): return {"success":false, "message":"El mecanismo ya está activo."}
			if not has_floor_key(state, dungeon_id, floor_index): return {"success":false, "message":"Falta la llave de esta planta."}
			(state["mechanisms"] as Array).append(object_id)
			return {"success":true, "kind":"mechanism", "message":"El mecanismo desplaza una pared y deja estable el atajo."}
		"P":
			if object_id in (state.get("solved_puzzles", []) as Array): return {"success":false, "message":"El enigma ya ha sido resuelto."}
			var required := puzzle_ability(dungeon_id, floor_index)
			if required not in available_abilities:
				return {"success":false, "kind":"ability_required", "ability":required, "message":"Este secreto requiere %s." % ability_name(required)}
			(state["solved_puzzles"] as Array).append(object_id)
			if dungeon_id not in (state["revealed_secrets"] as Array): (state["revealed_secrets"] as Array).append(dungeon_id)
			return {"success":true, "kind":"puzzle", "message":"%s revela una cámara secreta." % ability_name(required)}
		"N", "R":
			if object_id in (state.get("opened_chests", []) as Array): return {"success":false, "message":"El cofre ya está vacío."}
			if tile == "R" and dungeon_id not in (state.get("revealed_secrets", []) as Array): return {"success":false, "message":"Solo distingues una pared cubierta de polvo."}
			(state["opened_chests"] as Array).append(object_id)
			return {"success":true, "kind":"secret_chest" if tile == "R" else "chest", "gold":80 if tile == "R" else 35, "item":"Fragmento prismático" if tile == "R" else "Poción menor", "message":"Abres un cofre %s." % ("secreto" if tile == "R" else "antiguo")}
		"T":
			if object_id in (state.get("triggered_traps", []) as Array): return {"success":false, "message":"La trampa desactivada ya no supone peligro."}
			(state["triggered_traps"] as Array).append(object_id)
			return {"success":true, "kind":"trap", "damage":8, "message":"¡Trampa de agujas! El grupo pierde parte de sus fuerzas."}
		"C":
			if object_id in (state.get("shortcuts", []) as Array): return {"success":false, "message":"El atajo permanece abierto."}
			if (state.get("mechanisms", []) as Array).filter(func(id: String): return id.begins_with("%s:%d:" % [dungeon_id, floor_index])).is_empty():
				return {"success":false, "message":"Un mecanismo de esta planta mantiene cerrada la compuerta."}
			(state["shortcuts"] as Array).append(object_id)
			return {"success":true, "kind":"shortcut", "message":"Atajo desbloqueado permanentemente."}
		"B":
			if object_id in (state.get("defeated_minibosses", []) as Array): return {"success":false, "message":"Solo quedan las huellas del guardián."}
			return {"success":true, "kind":"miniboss", "encounter_id":object_id, "enemy":str(DUNGEONS[dungeon_id]["enemy"]), "name":str(DUNGEONS[dungeon_id]["keeper"]), "message":"%s protege la cámara." % DUNGEONS[dungeon_id]["keeper"]}
		"X":
			if dungeon_id not in (state.get("revealed_secrets", []) as Array): return {"success":false, "message":"Una presencia oculta duerme tras el velo."}
			if object_id in (state.get("defeated_secret_bosses", []) as Array): return {"success":false, "message":"El altar del enemigo secreto está en silencio."}
			return {"success":true, "kind":"secret_boss", "encounter_id":object_id, "enemy":"hollow_lion", "name":str(DUNGEONS[dungeon_id]["secret_boss"]), "message":"Has despertado al jefe secreto: %s." % DUNGEONS[dungeon_id]["secret_boss"]}
	return {"success":false, "kind":"empty", "message":"No hay nada que activar en esta casilla."}

static func resolve_encounter(state: Dictionary, encounter_id: String, secret: bool = false) -> void:
	var collection := "defeated_secret_bosses" if secret else "defeated_minibosses"
	if encounter_id not in (state.get(collection, []) as Array): (state[collection] as Array).append(encounter_id)

static func available_abilities(party: Array) -> Array[String]:
	var result: Array[String] = []
	for member in party:
		if not member is Dictionary or not bool(member.get("joined", false)): continue
		var ability := str(member.get("exploration_ability", ABILITIES.get(str(member.get("id", "")), {}).get("id", "")))
		if not ability.is_empty() and ability not in result: result.append(ability)
	return result

static func map_percentage(state: Dictionary, dungeon_id: String = "") -> float:
	var resolved_id := dungeon_id if not dungeon_id.is_empty() else str(state.get("active_dungeon", ""))
	if resolved_id.is_empty(): return 0.0
	var total := 0
	var seen := 0
	var visited: Dictionary = state.get("visited", {}) as Dictionary
	for floor_index in FLOOR_LAYOUTS.size():
		for y in floor_layout(floor_index, resolved_id).size():
			for x in str(floor_layout(floor_index, resolved_id)[y]).length():
				if is_walkable(floor_index, Vector2i(x, y), resolved_id):
					total += 1
					if visit_key(resolved_id, floor_index, Vector2i(x, y)) in visited: seen += 1
	return 0.0 if total == 0 else float(seen) * 100.0 / float(total)

static func automap_cells(state: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dungeon_id := str(state.get("active_dungeon", ""))
	var floor_index := current_floor(state)
	var visited: Dictionary = state.get("visited", {}) as Dictionary
	for y in floor_layout(floor_index, dungeon_id).size():
		for x in str(floor_layout(floor_index, dungeon_id)[y]).length():
			var cell := Vector2i(x, y)
			if visit_key(dungeon_id, floor_index, cell) in visited:
				result.append({"position":cell, "tile":tile_at(floor_index, cell, dungeon_id)})
	return result

static func theme(dungeon_id: String) -> Dictionary:
	return (DUNGEON_THEMES.get(dungeon_id, DUNGEON_THEMES["eira_ruins"]) as Dictionary).duplicate(true)

static func patrol_at(state: Dictionary, floor_index: int, cell: Vector2i) -> Dictionary:
	var dungeon_id := str(state.get("active_dungeon", ""))
	if dungeon_id.is_empty() or floor_index < 0 or floor_index >= PATROL_CELLS.size() or cell != PATROL_CELLS[floor_index]: return {}
	var patrol_id := "%s:%d:patrol" % [dungeon_id, floor_index]
	if patrol_id in (state.get("defeated_minibosses", []) as Array): return {}
	return {"id":patrol_id, "position":cell, "enemy":str((DUNGEONS.get(dungeon_id, {}) as Dictionary).get("enemy", "hollow_sentinel"))}

static func visible_patrols(state: Dictionary) -> Array[Dictionary]:
	var patrol := patrol_at(state, current_floor(state), PATROL_CELLS[current_floor(state)])
	return [] if patrol.is_empty() else [patrol]

static func validate_definitions() -> Array[String]:
	var errors: Array[String] = []
	var used_abilities: Array[String] = []
	if DUNGEONS.size() != 6: errors.append("La fase 9 requiere seis mazmorras de mundo.")
	for dungeon_id in DUNGEON_IDS:
		if not DUNGEONS.has(dungeon_id): errors.append("Falta la mazmorra %s." % dungeon_id)
		elif str(DUNGEONS[dungeon_id].get("ability", "")) not in ability_ids(): errors.append("Habilidad desconocida en %s." % dungeon_id)
		else:
			for ability in DUNGEONS[dungeon_id].get("floor_abilities", []) as Array:
				if str(ability) not in ability_ids(): errors.append("Habilidad de planta desconocida en %s." % dungeon_id)
				elif str(ability) not in used_abilities: used_abilities.append(str(ability))
	for dungeon_id in DUNGEON_IDS:
		for floor_index in FLOOR_LAYOUTS.size():
			var layout := floor_layout(floor_index, dungeon_id)
			if layout.is_empty(): errors.append("Planta vacía %s/%d." % [dungeon_id, floor_index]); continue
			var width := str(layout[0]).length()
			for row in layout:
				if str(row).length() != width: errors.append("Planta %s/%d no rectangular." % [dungeon_id, floor_index])
			if count_tile(floor_index, TILE_START, dungeon_id) != 1 or count_tile(floor_index, TILE_EXIT, dungeon_id) != 1: errors.append("Planta %s/%d necesita entrada y salida." % [dungeon_id, floor_index])
			if not path_exists(floor_index, find_tile(floor_index, TILE_START, dungeon_id), find_tile(floor_index, TILE_EXIT, dungeon_id), dungeon_id): errors.append("Planta %s/%d no se puede completar." % [dungeon_id, floor_index])
	for ability_id in ability_ids():
		if ability_id not in used_abilities: errors.append("La habilidad %s no interviene en ninguna mazmorra." % ability_id)
	return errors

static func validate_state(state: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var active_id := str(state.get("active_dungeon", ""))
	if not active_id.is_empty() and not DUNGEONS.has(active_id): errors.append("Mazmorra activa desconocida.")
	var floor_index := int(state.get("floor", 0))
	if floor_index < 0 or floor_index >= FLOOR_LAYOUTS.size(): errors.append("Planta guardada fuera de rango.")
	if not active_id.is_empty() and floor_index >= 0 and floor_index < FLOOR_LAYOUTS.size() and not is_walkable(floor_index, position(state), active_id): errors.append("Posición guardada dentro de un muro.")
	for key in ["opened_chests", "triggered_traps", "keys", "mechanisms", "solved_puzzles", "shortcuts", "defeated_minibosses", "defeated_secret_bosses", "completed_dungeons", "revealed_secrets"]:
		if not state.get(key, []) is Array: errors.append("Colección de mazmorra inválida: %s." % key)
	if int(state.get("steps", 0)) < 0: errors.append("Contador de pasos negativo.")
	return errors

static func path_exists(floor_index: int, start: Vector2i, goal: Vector2i, dungeon_id: String = "eira_ruins") -> bool:
	var frontier: Array[Vector2i] = [start]
	var visited: Dictionary = {str(start):true}
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == goal: return true
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = current + (direction as Vector2i)
			if is_walkable(floor_index, next, dungeon_id) and not visited.has(str(next)):
				visited[str(next)] = true
				frontier.append(next)
	return false

static func visit(state: Dictionary, floor_index: int, cell: Vector2i) -> void:
	var visited: Dictionary = state.get("visited", {}) as Dictionary
	visited[visit_key(str(state.get("active_dungeon", "")), floor_index, cell)] = true

static func visit_key(dungeon_id: String, floor_index: int, cell: Vector2i) -> String:
	return "%s:%d:%d,%d" % [dungeon_id, floor_index, cell.x, cell.y]

static func object_key(dungeon_id: String, floor_index: int, cell: Vector2i) -> String:
	return visit_key(dungeon_id, floor_index, cell)

static func find_tile(floor_index: int, tile: String, dungeon_id: String = "eira_ruins") -> Vector2i:
	var layout := floor_layout(floor_index, dungeon_id)
	for y in layout.size():
		var x := str(layout[y]).find(tile)
		if x >= 0: return Vector2i(x, y)
	return Vector2i(1, 1)

static func count_tile(floor_index: int, tile: String, dungeon_id: String = "eira_ruins") -> int:
	var result := 0
	for row in floor_layout(floor_index, dungeon_id): result += str(row).count(tile)
	return result

static func has_floor_key(state: Dictionary, dungeon_id: String, floor_index: int) -> bool:
	for key_id in state.get("keys", []) as Array:
		if str(key_id).begins_with("%s:%d:" % [dungeon_id, floor_index]): return true
	return false

static func ability_ids() -> Array[String]:
	var result: Array[String] = []
	for hero_id in ABILITIES: result.append(str(ABILITIES[hero_id]["id"]))
	return result

static func ability_name(ability_id: String) -> String:
	for hero_id in ABILITIES:
		if str(ABILITIES[hero_id]["id"]) == ability_id: return str(ABILITIES[hero_id]["name"])
	return ability_id.capitalize()

static func puzzle_ability(dungeon_id: String, floor_index: int) -> String:
	var definition := dungeon(dungeon_id)
	var floor_abilities: Array = definition.get("floor_abilities", []) as Array
	if floor_abilities.is_empty(): return str(definition.get("ability", ""))
	return str(floor_abilities[clampi(floor_index, 0, floor_abilities.size() - 1)])

static func tile_hint(tile: String) -> String:
	return {
		"K":"Una llave descansa en un pedestal.", "M":"Un mecanismo espera una llave.",
		"P":"Las runas responden a una habilidad de exploración.", "N":"Has encontrado un cofre.",
		"R":"Una pared oculta algo.", "T":"El suelo parece inestable.", "C":"Hay una compuerta de atajo.",
		"B":"Una presencia poderosa bloquea la sala.", "X":"El aire vibra con un secreto.",
		"E":"Una escalera conecta con la siguiente planta.", "S":"Ves la escalera de regreso."
	}.get(tile, "Exploras un corredor de piedra.")

static func vector_to_array(value: Vector2i) -> Array:
	return [value.x, value.y]

static func array_to_vector(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1])) if value.size() >= 2 else Vector2i(1, 1)

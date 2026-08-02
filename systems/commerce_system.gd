class_name CommerceSystem
extends RefCounted

const CITIES := ["valdoria", "brumaforja", "celestia", "sylvaran"]
const MARKET_STOCK := {
	"valdoria":[["item", "Poción menor", 18, 8], ["item", "Pan de viaje", 8, 12], ["equipment", "iron_sword", 95, 1]],
	"brumaforja":[["item", "Hierro resonante", 22, 8], ["equipment", "lion_mail", 230, 1], ["equipment", "runic_hammer", 135, 1]],
	"celestia":[["item", "Éter estelar", 30, 6], ["item", "Fragmento prismático", 58, 3], ["equipment", "astral_robe", 210, 1]],
	"sylvaran":[["item", "Hilo lunar", 28, 6], ["item", "Pan de viaje", 7, 14], ["equipment", "swift_feather", 185, 1]]
}
const GATHERING_NODES := {
	"iron_vein":{"name":"Veta resonante", "item":"Hierro resonante", "amount":2},
	"moon_bloom":{"name":"Flor lunar", "item":"Hilo lunar", "amount":1},
	"prism_geode":{"name":"Geoda prismatica", "item":"Fragmento prismático", "amount":1},
	"old_cache":{"name":"Alijo antiguo", "item":"Poción menor", "amount":2},
	"forest_basket":{"name":"Cesta silvestre", "item":"Pan de viaje", "amount":3},
	"astral_pool":{"name":"Pozo astral", "item":"Éter estelar", "amount":1},
	"merchant_wreck":{"name":"Carromato perdido", "item":"Pan de viaje", "amount":2},
	"lion_shrine":{"name":"Santuario del leon", "item":"Hierro resonante", "amount":3}
}

static func create_state() -> Dictionary:
	var markets: Dictionary = {}
	for city_id in CITIES: markets[city_id] = {"day":0, "stock":_fresh_stock(city_id), "demand":{}, "reputation":0}
	return {"day":0, "markets":markets, "gathered":{}, "total_spent":0, "total_earned":0, "successful_negotiations":0}

static func _fresh_stock(city_id: String) -> Array:
	var result: Array = []
	for row in MARKET_STOCK.get(city_id, []):
		result.append({"kind":row[0], "id":row[1], "base_price":row[2], "quantity":row[3], "max_quantity":row[3]})
	return result

static func advance_day(state: Dictionary, days: int = 1) -> void:
	state["day"] = int(state.get("day", 0)) + maxi(1, days)
	for city_id in CITIES:
		var market: Dictionary = (state["markets"] as Dictionary)[city_id]
		if int(state["day"]) - int(market["day"]) >= 2:
			market["stock"] = _fresh_stock(city_id)
			market["day"] = state["day"]
			var demand: Dictionary = market["demand"]
			for product_id in demand: demand[product_id] = maxi(0, int(demand[product_id]) - 1)

static func stock(state: Dictionary, city_id: String) -> Array:
	if not (state.get("markets", {}) as Dictionary).has(city_id): return []
	return ((state["markets"] as Dictionary)[city_id] as Dictionary)["stock"]

static func price(state: Dictionary, city_id: String, product: Dictionary) -> int:
	var market: Dictionary = (state["markets"] as Dictionary).get(city_id, {})
	var demand := int((market.get("demand", {}) as Dictionary).get(str(product["id"]), 0))
	var reputation := int(market.get("reputation", 0))
	return maxi(1, roundi(float(product["base_price"]) * (1.0 + demand * 0.06) * (1.0 - mini(0.25, reputation * 0.005))))

static func buy(state: Dictionary, city_id: String, stock_index: int, gold: int, inventory: Dictionary, equipment_state: Dictionary) -> Dictionary:
	var products := stock(state, city_id)
	if products.is_empty() or stock_index < 0 or stock_index >= products.size(): return {"success":false, "gold":gold, "message":"Mercado no disponible."}
	var product: Dictionary = products[stock_index]
	if int(product["quantity"]) <= 0: return {"success":false, "gold":gold, "message":"Articulo agotado."}
	var cost := price(state, city_id, product)
	if gold < cost: return {"success":false, "gold":gold, "message":"Oro insuficiente."}
	var delivered := false
	if str(product["kind"]) == "item":
		var definition := GameDatabase.item_by_name(str(product["id"]))
		if definition != null: delivered = bool(InventorySystem.add_item(inventory, definition.display_name, definition, 1)["success"])
	else:
		delivered = EquipmentSystem.add_owned(equipment_state, str(product["id"]))
	if not delivered: return {"success":false, "gold":gold, "message":"No se pudo entregar el articulo."}
	product["quantity"] = int(product["quantity"]) - 1
	var market: Dictionary = (state["markets"] as Dictionary)[city_id]
	var demand: Dictionary = market["demand"]
	demand[str(product["id"])] = int(demand.get(str(product["id"]), 0)) + 1
	state["total_spent"] = int(state["total_spent"]) + cost
	return {"success":true, "gold":gold - cost, "message":"Compra realizada por %d oro." % cost}

static func sell_item(state: Dictionary, city_id: String, item_name: String, gold: int, inventory: Dictionary) -> Dictionary:
	if not inventory.has(item_name): return {"success":false, "gold":gold, "message":"No posees ese objeto."}
	var definition := GameDatabase.item_by_name(item_name)
	if definition == null or int(definition.kind) == int(ItemDefinition.ItemKind.KEY_ITEM): return {"success":false, "gold":gold, "message":"Este objeto no se puede vender."}
	var value := maxi(1, int(definition.price) / 2)
	var stack: Dictionary = inventory[item_name]
	stack["quantity"] = int(stack["quantity"]) - 1
	if int(stack["quantity"]) <= 0: inventory.erase(item_name)
	state["total_earned"] = int(state["total_earned"]) + value
	return {"success":true, "gold":gold + value, "message":"Venta realizada por %d oro." % value}

static func negotiate(state: Dictionary, city_id: String, charisma: int) -> Dictionary:
	var market: Dictionary = (state.get("markets", {}) as Dictionary).get(city_id, {})
	if market.is_empty(): return {"success":false, "message":"No hay mercader con quien negociar."}
	var target := 12 + int(state.get("day", 0)) % 8
	if charisma >= target:
		market["reputation"] = mini(50, int(market["reputation"]) + 2)
		state["successful_negotiations"] = int(state["successful_negotiations"]) + 1
		return {"success":true, "message":"El mercader concede un descuento permanente."}
	return {"success":false, "message":"El precio se mantiene."}

static func gather(state: Dictionary, node_id: String, inventory: Dictionary) -> Dictionary:
	if not GATHERING_NODES.has(node_id): return {"success":false, "message":"Nodo desconocido."}
	var key := "%s:%d" % [node_id, int(state.get("day", 0))]
	if bool((state.get("gathered", {}) as Dictionary).get(key, false)): return {"success":false, "message":"Este recurso ya se recogio hoy."}
	var node: Dictionary = GATHERING_NODES[node_id]
	var definition := GameDatabase.item_by_name(str(node["item"]))
	if definition == null: return {"success":false, "message":"Recurso sin definicion."}
	InventorySystem.add_item(inventory, definition.display_name, definition, int(node["amount"]))
	(state["gathered"] as Dictionary)[key] = true
	return {"success":true, "message":"Obtienes %s x%d." % [node["item"], node["amount"]]}

static func validate_state(state: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if int(state.get("day", -1)) < 0: errors.append("Dia comercial invalido.")
	if not state.get("markets", {}) is Dictionary: return ["Mercados invalidos."]
	for city_id in CITIES:
		if not (state["markets"] as Dictionary).has(city_id): errors.append("Falta el mercado de %s." % city_id)
		elif stock(state, city_id).size() != 3: errors.append("Stock invalido en %s." % city_id)
	return errors

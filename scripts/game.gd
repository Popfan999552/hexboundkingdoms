class_name KingdomGame
extends RefCounted

# Territory-based rules: roads join tile centers; beacons reward biome diversity.
const RESOURCES = ["Timber", "Grain", "Ore", "Reeds", "Ember"]
const COSTS = {"road": [1,0,1,0,0], "settlement": [1,1,0,1,0], "city": [0,2,3,0,0], "beacon": [0,0,1,1,2]}
const DIRS = [Vector2i(1,0),Vector2i(1,-1),Vector2i(0,-1),Vector2i(-1,0),Vector2i(-1,1),Vector2i(0,1)]
const TARGET = 12
var tiles: Array = []
var players: Array = []
var roads: Array = []
var active = 0
var round_number = 1
var actions = 2
var phase = "roll"
var blocked = -1
var last_roll = 0
var winner = -1
var difficulty = 1
var seed_value = 0
var rng = RandomNumberGenerator.new()
var history: Array = []
var last_error = ""

func new_game(count: int = 3, level: int = 1, map_seed: int = 0) -> void:
	seed_value = map_seed if map_seed != 0 else int(Time.get_unix_time_from_system())
	rng.seed = seed_value
	difficulty = clampi(level, 0, 2)
	tiles.clear(); players.clear(); roads.clear(); history.clear()
	active = 0; round_number = 1; actions = 2; phase = "roll"; blocked = -1; last_roll = 0; winner = -1
	var numbers = [2,3,4,5,6,8,9,10,11,12]
	for q in range(-3,4):
		for r in range(-3,4):
			if absi(q+r) <= 3:
				tiles.append({"q":q,"r":r,"biome":rng.randi_range(0,4),"number":numbers[rng.randi_range(0,9)],"owner":-1,"level":0,"beacon":false})
	for p in range(clampi(count,2,4)):
		players.append({"name":"You" if p == 0 else ["House Aster","House Tide","House Cinder"][p-1],"resources":[3,3,3,3,2],"points":0})
		var best = -1
		var score = -100000.0
		for i in range(tiles.size()):
			var separated = true
			for tile in tiles:
				if tile.owner >= 0 and distance(tile,tiles[i]) < 3:
					separated = false
			var value = tile_value(i,p) + rng.randf()
			if separated and value > score:
				score = value; best = i
		tiles[best].owner = p; tiles[best].level = 1
	recount()
	log_event("Found your kingdom. Reach %d prestige to win." % TARGET)

func distance(a: Dictionary,b: Dictionary) -> int:
	return maxi(maxi(absi(a.q-b.q),absi(a.r-b.r)),absi((a.q+a.r)-(b.q+b.r)))

func neighbors(i: int) -> Array:
	var result: Array = []
	for j in range(tiles.size()):
		if distance(tiles[i],tiles[j]) == 1: result.append(j)
	return result

func edge_exists(a: int,b: int) -> bool:
	for edge in roads:
		if (edge.a == a and edge.b == b) or (edge.a == b and edge.b == a): return true
	return false

func connected(i: int,p: int) -> bool:
	if tiles[i].owner == p: return true
	if tiles[i].owner >= 0: return false
	for edge in roads:
		if edge.owner == p and (edge.a == i or edge.b == i): return true
	return false

func affordable(p: int,cost: Array) -> bool:
	for k in range(5):
		if players[p].resources[k] < cost[k]: return false
	return true

func pay(p: int,cost: Array) -> void:
	for k in range(5): players[p].resources[k] -= cost[k]

func fail(message: String) -> bool:
	last_error = message
	return false

func can_build(kind: String,a: int,b: int = -1,p: int = -1) -> bool:
	if p < 0: p = active
	if not COSTS.has(kind) or a < 0 or a >= tiles.size(): return false
	if p < 0 or p >= players.size(): return false
	if not affordable(p,COSTS[kind]): return false
	match kind:
		"road":
			if b < 0 or b >= tiles.size() or distance(tiles[a],tiles[b]) != 1 or edge_exists(a,b): return false
			if (tiles[a].owner >= 0 and tiles[a].owner != p) or (tiles[b].owner >= 0 and tiles[b].owner != p): return false
			return connected(a,p) or connected(b,p)
		"settlement":
			if tiles[a].owner != -1 or not connected(a,p): return false
			for j in neighbors(a):
				if tiles[j].owner >= 0: return false
			return true
		"city": return tiles[a].owner == p and tiles[a].level == 1
		"beacon": return tiles[a].owner == p and tiles[a].level >= 1 and not tiles[a].beacon
	return false

func build(kind: String,a: int,b: int = -1) -> bool:
	if phase != "act" or winner >= 0 or actions <= 0: return fail("Roll first; construction needs an action.")
	if not can_build(kind,a,b): return fail("Illegal placement or insufficient resources.")
	pay(active,COSTS[kind]); actions -= 1
	match kind:
		"road": roads.append({"a":a,"b":b,"owner":active})
		"settlement": tiles[a].owner = active; tiles[a].level = 1
		"city": tiles[a].level = 2
		"beacon": tiles[a].beacon = true
	recount()
	log_event("%s built a %s." % [players[active].name,kind])
	return true

func roll(forced: int = 0) -> bool:
	if phase != "roll" or winner >= 0: return fail("Dice may be rolled once per turn.")
	if forced != 0 and (forced < 2 or forced > 12): return fail("Invalid dice sum.")
	last_roll = forced if forced != 0 else rng.randi_range(1,6)+rng.randi_range(1,6)
	log_event("%s rolled %d." % [players[active].name,last_roll])
	if last_roll == 7:
		phase = "block"
	else:
		produce(last_roll); phase = "act"
	return true

func produce(number: int) -> void:
	var season = (round_number-1) % 5
	for i in range(tiles.size()):
		var t = tiles[i]
		if t.owner < 0 or i == blocked or t.number != number: continue
		players[t.owner].resources[t.biome] += t.level + (1 if t.biome == season else 0)
	# A supply shipment guarantees forward progress without lucky dice.
	players[active].resources[season] += 1

func block_tile(i: int) -> bool:
	if phase != "block" or i < 0 or i >= tiles.size() or i == blocked: return fail("Choose a different territory for the storm.")
	blocked = i; phase = "act"
	# No random theft/discard: storms deny production, and grant one salvaged ember.
	players[active].resources[4] += 1
	log_event("The storm now blocks territory %d." % (i+1))
	return true

func bank_trade(give: int,receive: int) -> bool:
	if phase != "act" or actions <= 0 or winner >= 0: return fail("Trade needs an action after rolling.")
	if give < 0 or give > 4 or receive < 0 or receive > 4 or give == receive: return fail("Choose two different resources.")
	if players[active].resources[give] < 3: return fail("Bank trades cost three units for one.")
	players[active].resources[give] -= 3; players[active].resources[receive] += 1; actions -= 1
	log_event("%s traded with the bank." % players[active].name)
	return true

func accepts_trade(p: int,give: int,receive: int,amount: int) -> bool:
	if p == active or p < 0 or p >= players.size() or give == receive: return false
	if give < 0 or give > 4 or receive < 0 or receive > 4 or amount < 1 or amount > 5: return false
	return players[p].resources[receive] >= 1 and players[p].resources[give] + amount <= players[p].resources[receive] + 2

func player_trade(p: int,give: int,receive: int,amount: int = 2) -> bool:
	if phase != "act" or actions <= 0 or winner >= 0: return fail("Trade needs an action.")
	if not accepts_trade(p,give,receive,amount): return fail("That kingdom declines your offer; offer a scarce resource.")
	if players[active].resources[give] < amount: return fail("Insufficient resources for the offer.")
	players[active].resources[give] -= amount; players[p].resources[give] += amount
	players[p].resources[receive] -= 1; players[active].resources[receive] += 1
	actions -= 1
	log_event("%s traded with %s." % [players[active].name,players[p].name])
	return true

func recount() -> void:
	for p in range(players.size()):
		var points = 0
		var biomes: Array = []
		var beacons = 0
		for t in tiles:
			if t.owner != p: continue
			points += t.level
			if not biomes.has(t.biome): biomes.append(t.biome)
			if t.beacon: beacons += 1
		points += beacons * 2
		if beacons > 0: points += maxi(0,biomes.size()-2)
		players[p].points = points
	if winner < 0 and not players.is_empty() and players[active].points >= TARGET:
		winner = active; phase = "finished"
		log_event("%s wins with %d prestige!" % [players[active].name,players[active].points])

func end_turn() -> bool:
	if phase != "act" or winner >= 0: return fail("Resolve the dice and storm before ending your turn.")
	active = (active+1) % players.size()
	if active == 0: round_number += 1
	actions = 2; phase = "roll"
	recount()
	return true

func tile_value(i: int,p: int) -> float:
	var t = tiles[i]
	var value = float(6-absi(7-t.number))
	var owned: Array = []
	for other in tiles:
		if other.owner == p and not owned.has(other.biome): owned.append(other.biome)
	if not owned.has(t.biome): value += 3
	if t.biome == 2: value += 1
	return value

func legal_moves() -> Array:
	var result: Array = []
	for i in range(tiles.size()):
		for kind in ["city","beacon","settlement"]:
			if can_build(kind,i): result.append({"kind":kind,"a":i,"b":-1})
		for j in neighbors(i):
			if i < j and can_build("road",i,j): result.append({"kind":"road","a":i,"b":j})
	return result

func ai_turn() -> void:
	if winner >= 0: return
	if phase == "roll": roll()
	if phase == "block":
		var target = -1
		var score = -100.0
		for i in range(tiles.size()):
			if i == blocked: continue
			var value = tile_value(i,active) * tiles[i].level
			if tiles[i].owner == active: value = -50
			if value > score: score = value; target = i
		block_tile(target)
	while actions > 0 and winner < 0:
		var moves = legal_moves()
		if moves.is_empty():
			if not ai_bank_trade(): break
			continue
		var selected = moves[0]
		var best = -10000.0
		for move in moves:
			var value = {"city":9.0,"settlement":12.0,"beacon":10.0,"road":2.0}[move.kind]
			value += tile_value(move.a,active)*0.2
			if move.kind == "road":
				var dest = move.b if connected(move.a,active) else move.a
				value += tile_value(dest,active)*0.3
				var min_distance = 100
				for t in tiles:
					if t.owner >= 0: min_distance = mini(min_distance,distance(t,tiles[dest]))
				if min_distance >= 2: value += 5
				if difficulty == 2:
					for n in neighbors(dest):
						if tiles[n].owner == -1: value += 0.3
			if difficulty == 0: value = rng.randf()*20
			elif difficulty == 1: value += rng.randf()*3
			if value > best: best = value; selected = move
		if not build(selected.kind,selected.a,selected.b): break
	if winner < 0: end_turn()

func ai_bank_trade() -> bool:
	var inventory = players[active].resources
	var give = 0
	for k in range(5):
		if inventory[k] > inventory[give]: give = k
	if inventory[give] < 4: return false
	var target = [0,2,3,1,4]
	for receive in target:
		if receive != give and inventory[receive] < 2: return bank_trade(give,receive)
	return false

func log_event(message: String) -> void:
	history.append(message)
	if history.size() > 30: history.pop_front()

func snapshot() -> Dictionary:
	return {"version":1,"tiles":tiles.duplicate(true),"players":players.duplicate(true),"roads":roads.duplicate(true),"active":active,"round":round_number,"actions":actions,"phase":phase,"blocked":blocked,"roll":last_roll,"winner":winner,"difficulty":difficulty,"seed":seed_value,"rng":str(rng.state),"history":history.duplicate()}

func save_game(path: String = "user://kingdom.json") -> bool:
	var file = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null: return fail("Unable to write save file.")
	file.store_string(JSON.stringify(snapshot())); file.close()
	var err = DirAccess.rename_absolute(path+".tmp",path)
	if err != OK: return fail("Unable to replace save file.")
	return true

func load_game(path: String = "user://kingdom.json") -> bool:
	if not FileAccess.file_exists(path): return fail("No saved kingdom found.")
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not valid_snapshot(data): return fail("Save is invalid or from an unsupported version.")
	tiles = data.tiles; players = data.players; roads = data.roads
	# JSON numbers are floats: normalize every indexed/arithmetical field.
	for t in tiles:
		for key in ["q","r","biome","number","owner","level"]: t[key] = int(t[key])
	for p in players:
		for k in range(5): p.resources[k] = int(p.resources[k])
		p.points = int(p.points)
	for edge in roads:
		for key in ["a","b","owner"]: edge[key] = int(edge[key])
	active = int(data.active); round_number = int(data.round); actions = int(data.actions); phase = data.phase
	blocked = int(data.blocked); last_roll = int(data.roll); winner = int(data.winner); difficulty = int(data.difficulty)
	seed_value = int(data.seed); rng.seed = seed_value; rng.state = int(data.rng); history = data.history
	return true

func valid_snapshot(data: Variant) -> bool:
	if not data is Dictionary: return false
	for key in ["version","tiles","players","roads","active","round","actions","phase","blocked","roll","winner","difficulty","seed","rng","history"]:
		if not data.has(key): return false
	if data.version != 1 or not data.tiles is Array or data.tiles.size() != 37: return false
	if not data.players is Array or data.players.size() < 2 or data.players.size() > 4: return false
	if not data.roads is Array or not data.history is Array or not data.rng is String: return false
	for key in ["active","round","actions","blocked","roll","winner","difficulty","seed"]:
		if not (data[key] is float or data[key] is int): return false
	if data.active < 0 or data.active >= data.players.size() or data.active != int(data.active): return false
	if data.actions < 0 or data.actions > 2 or data.round < 1: return false
	if not data.phase in ["roll","block","act","finished"]: return false
	if data.blocked < -1 or data.blocked >= 37 or data.winner < -1 or data.winner >= data.players.size(): return false
	if data.difficulty < 0 or data.difficulty > 2 or not data.rng.is_valid_int(): return false
	var coords: Array = []
	for t in data.tiles:
		if not t is Dictionary: return false
		for key in ["q","r","biome","number","owner","level","beacon"]:
			if not t.has(key): return false
		for key in ["q","r","biome","number","owner","level"]:
			if not (t[key] is float or t[key] is int) or t[key] != int(t[key]): return false
		if absi(int(t.q)) > 3 or absi(int(t.r)) > 3 or absi(int(t.q+t.r)) > 3: return false
		var coord = "%d,%d" % [t.q,t.r]
		if coord in coords: return false
		coords.append(coord)
		if t.biome < 0 or t.biome > 4 or t.number < 2 or t.number > 12 or t.number == 7: return false
		if t.owner < -1 or t.owner >= data.players.size() or t.level < 0 or t.level > 2: return false
		if (t.owner == -1) != (t.level == 0) or not t.beacon is bool: return false
		if t.beacon and t.owner < 0: return false
	for p in data.players:
		if not p is Dictionary or not p.has("name") or not p.name is String or not p.has("resources") or not p.resources is Array or p.resources.size() != 5 or not p.has("points"): return false
		if not (p.points is float or p.points is int): return false
		for amount in p.resources:
			if not (amount is float or amount is int) or amount < 0 or amount != int(amount) or amount > 1000000: return false
	var edges: Array = []
	for e in data.roads:
		if not e is Dictionary: return false
		for key in ["a","b","owner"]:
			if not e.has(key) or not (e[key] is float or e[key] is int) or e[key] != int(e[key]): return false
		if e.a < 0 or e.a >= 37 or e.b < 0 or e.b >= 37 or e.owner < 0 or e.owner >= data.players.size(): return false
		if distance(data.tiles[int(e.a)],data.tiles[int(e.b)]) != 1: return false
		var edge_key = "%d,%d" % [mini(int(e.a),int(e.b)),maxi(int(e.a),int(e.b))]
		if edge_key in edges: return false
		edges.append(edge_key)
	for line in data.history:
		if not line is String: return false
	return true

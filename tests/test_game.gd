extends SceneTree
const Game = preload("res://scripts/game.gd")
var passed=0
var failed=0

func check(condition: bool,message: String) -> void:
	if condition: passed+=1
	else: failed+=1; push_error("FAIL: "+message)

func fresh() -> KingdomGame:
	var g=Game.new(); g.new_game(3,1,12345); return g

func home(g: KingdomGame,p: int=0) -> int:
	for i in range(g.tiles.size()):
		if g.tiles[i].owner==p: return i
	return -1

func rich(g: KingdomGame) -> void:
	g.players[g.active].resources=[50,50,50,50,50]; g.phase="act"; g.actions=2

func _init() -> void:
	call_deferred("run")

func run() -> void:
	map_tests(); construction_tests(); economy_tests(); turn_tests(); save_tests(); ai_tests()
	print("GAMEPLAY_TEST_RESULT: %d passed; %d failed" % [passed,failed])
	quit(1 if failed else 0)

func map_tests() -> void:
	for count in [2,3,4]:
		for seed_value in range(20):
			var g=Game.new(); g.new_game(count,1,seed_value+1)
			check(g.tiles.size()==37,"hex radius 3 has 37 territories")
			check(g.players.size()==count,"player count")
			var coords=[]
			for t in g.tiles:
				var coord=Vector2i(t.q,t.r)
				check(not coords.has(coord),"unique coordinates"); coords.append(coord)
				check(t.biome>=0 and t.biome<5 and t.number>=2 and t.number<=12 and t.number!=7,"valid production terrain")
			for p in range(count):
				check(g.players[p].points==1,"starting prestige")
				for other in range(p): check(g.distance(g.tiles[home(g,p)],g.tiles[home(g,other)])>=3,"separated initial homes")
	var a=fresh(); var b=fresh()
	check(a.snapshot()==b.snapshot(),"deterministic seeded generation")

func construction_tests() -> void:
	var g=fresh(); rich(g); var h=home(g)
	check(not g.build("road",-1,100),"invalid road indices rejected")
	check(not g.build("dragon",h),"unknown construction rejected")
	var moves=g.legal_moves(); var road={}
	for m in moves:
		if m.kind=="road": road=m; break
	check(not road.is_empty(),"starting road available")
	var before=g.players[0].resources.duplicate()
	check(g.build("road",road.a,road.b),"legal road built")
	check(g.players[0].resources[0]==before[0]-1 and g.players[0].resources[2]==before[2]-1 and g.actions==1,"road exact cost and action")
	check(not g.can_build("road",road.a,road.b),"duplicate road forbidden")
	check(not g.can_build("road",road.b,road.a),"reversed duplicate road forbidden")
	check(not g.can_build("settlement",h),"occupied settlement forbidden")
	var first=road.b if road.a==h else road.a
	check(not g.can_build("settlement",first),"neighbor distance restriction")
	var far=-1
	for n in g.neighbors(first):
		if g.distance(g.tiles[h],g.tiles[n])>=2 and g.can_build("road",first,n): far=n; break
	check(far>=0,"two-step expansion possible")
	check(g.build("road",first,far),"second connecting road")
	check(not g.build("settlement",far),"action exhaustion enforced")
	g.actions=2
	check(g.build("settlement",far),"connected separated settlement built")
	check(g.tiles[far].owner==0 and g.players[0].points==2,"settlement ownership and prestige")
	g.actions=2
	before=g.players[0].resources.duplicate()
	check(g.build("city",h),"city upgrade")
	check(g.players[0].resources[1]==before[1]-2 and g.players[0].resources[2]==before[2]-3,"city costs")
	check(not g.can_build("city",h),"city cannot upgrade twice")
	check(g.build("beacon",h),"beacon built")
	check(g.players[0].points>=5,"city and beacon prestige")
	check(not g.can_build("beacon",h),"one beacon per territory")
	check(not g.can_build("city",home(g,1)),"cannot upgrade opponent")
	check(not g.can_build("beacon",home(g,1)),"cannot beacon opponent")
	g.phase="roll"; check(not g.build("beacon",far),"must roll before building")
	g.phase="act"; g.players[0].resources=[0,0,0,0,0]
	check(not g.can_build("beacon",far),"cannot afford construction")
	var isolated=-1
	for i in range(g.tiles.size()):
		if not g.connected(i,0): isolated=i; break
	rich(g); check(not g.can_build("settlement",isolated),"disconnected settlement illegal")
	var enemy=home(g,1)
	for n in g.neighbors(enemy): check(not g.can_build("road",enemy,n),"opponent blocks road endpoints")

func economy_tests() -> void:
	var g=fresh(); var h=home(g)
	for t in g.tiles: t.number=12
	g.tiles[h].number=6; g.tiles[h].biome=0; g.tiles[h].level=2
	g.players[0].resources=[0,0,0,0,0]
	check(g.roll(6),"valid forced test roll")
	check(g.players[0].resources[0]==4,"city produces 2 + seasonal 1 + supply 1")
	check(not g.roll(6),"cannot roll twice")
	g.blocked=h; g.players[0].resources=[0,0,0,0,0]; g.phase="roll"; g.roll(6)
	check(g.players[0].resources[0]==1,"blocked city produces nothing; supply remains")
	g.phase="roll"; check(not g.roll(13),"invalid dice rejected")
	check(g.roll(7) and g.phase=="block","seven requires storm selection")
	check(not g.end_turn(),"cannot skip storm")
	check(not g.block_tile(h),"cannot leave storm unmoved")
	check(g.block_tile(0 if h!=0 else 1) and g.players[0].resources[4]==1,"storm move and salvage")
	rich(g); g.players[0].resources=[3,0,0,0,0]
	check(g.bank_trade(0,1),"bank trade success")
	check(g.players[0].resources==[0,1,0,0,0] and g.actions==1,"bank conservation and ratio")
	check(not g.bank_trade(0,1),"bank requires inventory")
	check(not g.bank_trade(-1,1) and not g.bank_trade(0,5),"trade bounds")
	check(not g.bank_trade(1,1),"same resource bank trade denied")
	rich(g); g.players[0].resources=[5,0,0,0,0]; g.players[1].resources=[0,4,0,0,0]
	check(g.player_trade(1,0,1,2),"accepted player trade")
	check(g.players[0].resources==[3,1,0,0,0] and g.players[1].resources==[2,3,0,0,0],"bilateral exchange conservation")
	check(not g.player_trade(0,0,1),"self-trade rejected")
	check(not g.player_trade(3,0,1),"invalid partner rejected")
	check(not g.player_trade(1,0,1,0),"invalid offer rejected")
	g.players[1].resources=[9,0,0,0,0]
	check(not g.player_trade(1,0,1),"AI can decline trade")
	g.phase="roll"; check(not g.bank_trade(0,1),"trade phase enforced")
	# Production applies to every kingdom, not just active player.
	g=fresh()
	for t in g.tiles: t.number=6
	var before=g.players[1].resources.duplicate(); var t=g.tiles[home(g,1)]
	g.roll(6)
	check(g.players[1].resources[t.biome]==before[t.biome]+1+(1 if t.biome==0 else 0),"simultaneous opponent production")

func turn_tests() -> void:
	var g=fresh()
	check(not g.end_turn(),"cannot skip dice")
	for p in range(3):
		g.roll(2); check(g.end_turn(),"valid turn advances")
		check(g.active==(p+1)%3 and g.actions==2 and g.phase=="roll","turn reset")
	check(g.round_number==2,"round advances after all players")
	var taken=0
	for t in g.tiles:
		if taken<4: t.owner=0; t.level=2; t.beacon=true; taken+=1
	g.recount(); check(g.winner==0 and g.phase=="finished","victory detection")
	check(not g.roll() and not g.end_turn() and not g.build("road",0,1),"terminal state prohibits actions")
	g=fresh(); var h=home(g); g.tiles[h].beacon=true
	var b1=-1; var b2=-1
	for i in range(g.tiles.size()):
		if g.tiles[i].owner==-1:
			if b1<0: b1=i
			else: b2=i; break
	g.tiles[h].biome=0; g.tiles[b1].owner=0; g.tiles[b1].level=1; g.tiles[b1].biome=1
	g.tiles[b2].owner=0; g.tiles[b2].level=1; g.tiles[b2].biome=2; g.recount()
	check(g.players[0].points==6,"three distinct biomes + beacon grant diversity bonus")

func save_tests() -> void:
	var g=fresh(); g.roll(6); rich(g); g.build("beacon",home(g))
	check(g.save_game("user://test-save.json"),"atomic save writes")
	var loaded=Game.new()
	check(loaded.load_game("user://test-save.json"),"load save")
	check(loaded.snapshot()==g.snapshot(),"complete state roundtrip")
	g.end_turn(); loaded.end_turn(); g.roll(); loaded.roll()
	check(g.last_roll==loaded.last_roll,"saved RNG continues identically")
	var unchanged=loaded.snapshot()
	var f=FileAccess.open("user://test-corrupt.json",FileAccess.WRITE); f.store_string('{"version":1}'); f.close()
	check(not loaded.load_game("user://test-corrupt.json"),"corrupt save rejected")
	check(loaded.snapshot()==unchanged,"failed load preserves current game")
	check(not loaded.load_game("user://nonexistent-save.json"),"missing save handled")
	for key in ["tiles","players","roads","active","phase","rng"]:
		var data=g.snapshot(); data[key]=null; check(not g.valid_snapshot(data),"malformed field "+key)
	var data=g.snapshot(); data.tiles[0].biome=9; check(not g.valid_snapshot(data),"corrupt biome rejected")
	data=g.snapshot(); data.players[0].resources[0]=-1; check(not g.valid_snapshot(data),"negative saved inventory rejected")
	data=g.snapshot(); data.tiles[1].q=data.tiles[0].q; data.tiles[1].r=data.tiles[0].r
	check(not g.valid_snapshot(data),"duplicate saved coordinate rejected")

func ai_tests() -> void:
	var wins=0
	for difficulty in range(3):
		for count in [2,3,4]:
			for seed_value in range(5):
				var g=Game.new(); g.new_game(count,difficulty,seed_value+123)
				var turns=0
				while g.winner < 0 and turns < 1600:
					var previous=g.active
					g.ai_turn(); turns+=1
					check(g.winner>=0 or g.active!=(previous),"AI finishes legal turn")
					for p in g.players:
						for amount in p.resources: check(amount>=0,"AI never spends below zero")
					if g.winner<0: check(g.phase=="roll" and g.actions==2,"AI progression resets phase")
				check(g.winner>=0,"AI match finishes before safety cap: level %d count %d seed %d" % [difficulty,count,seed_value])
				if g.winner>=0: wins+=1
	print("AI_SIMULATIONS: %d / 45 completed with a winner across three difficulties and 2–4 kingdoms" % wins)

extends Control
signal territory_selected(index: int)
const COLORS = [Color("36837b"),Color("b99a52"),Color("6e829e"),Color("568f5e"),Color("9d5a68")]
const PLAYER_COLORS = [Color("66e8d2"),Color("f4c66f"),Color("a99dff"),Color("ff879b")]
var game: KingdomGame
var selected = -1
var road_start = -1
var mode = "inspect"
var centers: Array[Vector2] = []
var radius = 43.0
var pulse = 0.0
var festival_glow = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_input_board)
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	pulse += delta
	if selected >= 0: queue_redraw()

func _input_board(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in range(centers.size()):
			if centers[i].distance_to(event.position) < radius*0.89:
				territory_selected.emit(i)
				accept_event()
				return

func hexagon(center: Vector2,scale_value: float = 1.0) -> PackedVector2Array:
	var polygon = PackedVector2Array()
	for k in range(6): polygon.append(center + Vector2.from_angle(deg_to_rad(60*k-30))*radius*scale_value)
	return polygon

func _draw() -> void:
	if game == null or game.tiles.is_empty(): return
	radius = minf(size.x / 13.0,size.y / 12.0)
	var origin = size/2 + Vector2(0,8)
	centers.clear()
	var font = ThemeDB.fallback_font
	for tile in game.tiles:
		centers.append(origin + Vector2(sqrt(3.0)*(tile.q+tile.r*0.5),1.5*tile.r)*radius)
	# The hinterland has subtle constellation-like specks.
	for i in range(65):
		var position_value = Vector2(fmod(i*137.1,size.x),fmod(i*93.7,size.y))
		draw_circle(position_value,1,Color(0.25,0.55,0.6,0.16))
	for i in range(game.tiles.size()):
		var tile = game.tiles[i]
		var c = centers[i]
		var polygon = hexagon(c,0.92)
		draw_colored_polygon(hexagon(c+Vector2(0,4),0.94),Color("08121f"))
		draw_colored_polygon(polygon,COLORS[tile.biome].darkened(0.3))
		draw_polyline(PackedVector2Array([polygon[0],polygon[1],polygon[2],polygon[3],polygon[4],polygon[5],polygon[0]]),COLORS[tile.biome],1.5,true)
		terrain(c,tile.biome,radius)
		if tile.owner >= 0:
			var color = PLAYER_COLORS[tile.owner]
			draw_circle(c+Vector2(0,-radius*0.24),radius*0.21,Color("101d2e"))
			var castle = PackedVector2Array([c+Vector2(-radius*0.16,0),c+Vector2(-radius*0.16,-radius*0.3),c+Vector2(-radius*0.05,-radius*0.3),c+Vector2(-radius*0.05,-radius*0.16),c+Vector2(radius*0.05,-radius*0.16),c+Vector2(radius*0.05,-radius*0.3),c+Vector2(radius*0.16,-radius*0.3),c+Vector2(radius*0.16,0)])
			draw_colored_polygon(castle,color)
			if tile.level == 2: draw_line(c+Vector2(-radius*0.2,3),c+Vector2(radius*0.2,3),color,3)
			if tile.beacon:
				if festival_glow: draw_circle(c+Vector2(radius*0.27,-radius*0.2),radius*0.23,Color(1,0.85,0.4,0.2))
				draw_circle(c+Vector2(radius*0.27,-radius*0.2),radius*0.09,Color("ffefb0"))
				draw_arc(c+Vector2(radius*0.27,-radius*0.2),radius*0.15,0,TAU,24,Color("ffefb0"),1,true)
		var label = str(tile.number)
		draw_circle(c+Vector2(0,radius*0.37),radius*0.2,Color("142337"))
		draw_string(font,c+Vector2(-font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x/2,radius*0.37+5),label,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("f7e6bd") if tile.number in [6,8] else Color("e4edf2"))
		if i == game.blocked:
			draw_circle(c,radius*0.48,Color(0.07,0.1,0.18,0.87))
			draw_string(font,c+Vector2(-radius*0.35,5),"STORM",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("b3b3da"))
	for edge in game.roads:
		draw_line(centers[edge.a],centers[edge.b],Color("111c28"),7,true)
		draw_line(centers[edge.a],centers[edge.b],PLAYER_COLORS[edge.owner],3,true)
	for i in [selected,road_start]:
		if i >= 0 and i < centers.size():
			var polygon = hexagon(centers[i],0.98+sin(pulse*3)*0.012)
			polygon.append(polygon[0]); draw_polyline(polygon,Color("f5e0ad"),3,true)
	# Selection hints show legal placements, rather than permitting invalid clicks.
	if game.active == 0 and game.phase == "act" and mode in ["settlement","city","beacon"]:
		for i in range(centers.size()):
			if game.can_build(mode,i): draw_arc(centers[i],radius*0.8,0,TAU,24,Color(0.7,1,0.85,0.8),2,true)

func terrain(c: Vector2,biome: int,r: float) -> void:
	var ink = COLORS[biome].lightened(0.12)
	match biome:
		0,3:
			for k in range(3):
				var p = c+Vector2((k-1)*r*0.36,-r*0.28+abs(k-1)*r*0.13)
				if biome == 0:
					draw_colored_polygon(PackedVector2Array([p+Vector2(0,-r*0.25),p+Vector2(-r*0.15,r*0.1),p+Vector2(r*0.15,r*0.1)]),ink)
				else:
					draw_line(p+Vector2(0,r*0.1),p+Vector2(r*0.08,-r*0.23),ink,2)
		1:
			for k in range(4):
				var p = c+Vector2((k-1.5)*r*0.25,-r*0.18)
				draw_line(p,p+Vector2(0,-r*0.22),ink,2)
				draw_line(p+Vector2(0,-r*0.1),p+Vector2(r*0.07,-r*0.18),ink,2)
		2:
			draw_colored_polygon(PackedVector2Array([c+Vector2(-r*0.5,-r*0.05),c+Vector2(-r*0.14,-r*0.55),c+Vector2(r*0.1,-r*0.19),c+Vector2(r*0.28,-r*0.4),c+Vector2(r*0.5,-r*0.05)]),ink)
		4:
			for k in range(3):
				var p = c+Vector2((k-1)*r*0.33,-r*0.22)
				draw_colored_polygon(PackedVector2Array([p+Vector2(0,-r*0.23),p+Vector2(-r*0.09,0),p+Vector2(0,r*0.08),p+Vector2(r*0.09,0)]),ink)

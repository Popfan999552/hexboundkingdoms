extends Control
const Game = preload("res://scripts/game.gd")
const Board = preload("res://scripts/board.gd")
var game = Game.new()
var board: Control
var sidebar: VBoxContainer
var root_box: BoxContainer
var side_panel: PanelContainer
var field: VBoxContainer
var status: Label
var inventory: Label
var details: Label
var scoreboard: Label
var log_label: Label
var tutorial_label: Label
var action_buttons: Array[Button] = []
var overlay: PanelContainer
var mode = "inspect"
var road_start = -1
var selected = -1
var busy = false
var tutorial = false
var tutorial_step = 0
var sound_enabled = true
var ads_enabled = false
var reduced_motion = false
var epoch = 0
var ads: Node
var reward_button: Button
var count_choice = 3
var difficulty_choice = 1
var sound: AudioStreamPlayer
var roll_button: Button
var end_button: Button
var give_choice: OptionButton
var receive_choice: OptionButton
var partner_choice: OptionButton
var amount_choice: SpinBox
var trade_panel: VBoxContainer
var preferences = ConfigFile.new()

func _ready() -> void:
	preferences.load("user://settings.cfg")
	sound_enabled = preferences.get_value("settings","sound",true)
	reduced_motion = preferences.get_value("settings","reduced_motion",false)
	# Ads remain disabled until native integration and consent have been device-verified.
	build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sound = AudioStreamPlayer.new(); add_child(sound)
	build_layout()
	if OS.get_name()=="Android" and Engine.has_singleton("PoingGodotAdMob"):
		ads=load("res://scripts/ads.gd").new(); add_child(ads)
		ads.reward_earned.connect(func():
			preferences.set_value("settings","festival_glow",true); preferences.save("user://settings.cfg"); board.festival_glow=true; board.queue_redraw())
		ads.availability_changed.connect(func():
			if is_instance_valid(reward_button): reward_button.disabled=not ads.can_reward(game.winner>=0))
	board.festival_glow=preferences.get_value("settings","festival_glow",false)
	show_menu()
	if "--qa-play" in OS.get_cmdline_user_args():
		start_game(false)
		roll_button.pressed.emit()
		if game.phase=="block": select_tile(0)
		await get_tree().process_frame
		assert(game.tiles.size()==37 and game.phase=="act")
		print("ANDROID_QA_GAMEPLAY_READY: territories=37 phase=act active=0 native_ads=",ads!=null)
	if "--smoke" in OS.get_cmdline_user_args():
		start_game(true)
		await get_tree().process_frame
		game.roll(6); refresh()
		await get_tree().process_frame
		if game.tiles.size() != 37 or board.centers.size() != 37:
			get_tree().quit(1); return
		print("UI_SMOKE_PASS: 37 rendered territory centers; menu, tutorial, inventory, and action controls mounted")
		get_tree().quit(0)
	if "--capture" in OS.get_cmdline_user_args():
		start_game(false)
		game.roll(6); selected = 18; refresh()
		if "--developed" in OS.get_cmdline_user_args():
			for turn in range(15):
				if game.winner<0: game.ai_turn()
			refresh()
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img = get_viewport().get_texture().get_image()
		var output = "res://google-play-release/screenshots/%s-%dx%d.png" % ["kingdoms" if "--developed" in OS.get_cmdline_user_args() else "gameplay",get_viewport().size.x,get_viewport().size.y]
		img.save_png(output)
		print("Captured actual running gameplay: ",output)
		get_tree().quit()

func build_theme() -> void:
	var t = Theme.new()
	t.default_font_size = 18
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color("102235")
	panel_style.border_color = Color("315061")
	panel_style.set_border_width_all(1); panel_style.set_corner_radius_all(14)
	panel_style.content_margin_left = 20; panel_style.content_margin_right = 20
	panel_style.content_margin_top = 16; panel_style.content_margin_bottom = 16
	t.set_stylebox("panel","PanelContainer",panel_style)
	for state in ["normal","hover","pressed","disabled"]:
		var s = StyleBoxFlat.new()
		s.bg_color = {"normal":Color("203c4b"),"hover":Color("315a65"),"pressed":Color("397569"),"disabled":Color("172b3a")}[state]
		s.set_corner_radius_all(8); s.content_margin_left=12; s.content_margin_right=12
		s.content_margin_top=10; s.content_margin_bottom=10
		t.set_stylebox(state,"Button",s)
	t.set_color("font_color","Label",Color("e4ebe9"))
	t.set_color("font_color","Button",Color("e6eee9"))
	t.set_color("font_disabled_color","Button",Color("687f86"))
	t.set_constant("separation","VBoxContainer",9)
	theme = t

func build_layout() -> void:
	var margin = MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,16)
	add_child(margin)
	root_box = BoxContainer.new(); root_box.add_theme_constant_override("separation",16); margin.add_child(root_box)
	field = VBoxContainer.new(); field.size_flags_vertical=Control.SIZE_EXPAND_FILL; field.size_flags_horizontal=Control.SIZE_EXPAND_FILL; root_box.add_child(field)
	var heading = label("HEXBOUND  /  KINGDOMS",26); heading.add_theme_color_override("font_color",Color("69dfcc")); field.add_child(heading)
	var navigation=HBoxContainer.new(); field.add_child(navigation)
	button("−",func(): board.set_zoom(board.zoom-0.25),navigation)
	button("Fit map",func(): board.set_zoom(1.0),navigation)
	button("+",func(): board.set_zoom(board.zoom+0.25),navigation)
	var map_hint=label("Pinch to zoom · drag when zoomed",14)
	map_hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	map_hint.custom_minimum_size.x=160
	navigation.add_child(map_hint)
	status = label("A realm of seasons, storms and signal fires",18); field.add_child(status)
	board = Board.new(); board.custom_minimum_size=Vector2(0,240); board.size_flags_vertical=Control.SIZE_EXPAND_FILL
	board.game=game; board.territory_selected.connect(select_tile); field.add_child(board)
	log_label = label("",16); log_label.custom_minimum_size.y=48; field.add_child(log_label)
	side_panel = PanelContainer.new(); side_panel.custom_minimum_size.x=340; root_box.add_child(side_panel)
	var scroll = ScrollContainer.new(); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; side_panel.add_child(scroll)
	sidebar = VBoxContainer.new(); sidebar.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroll.add_child(sidebar)
	scoreboard=label("",18); sidebar.add_child(scoreboard)
	sidebar.add_child(HSeparator.new())
	inventory=label("",18); sidebar.add_child(inventory)
	tutorial_label=label("",16); tutorial_label.add_theme_color_override("font_color",Color("f4d68c")); sidebar.add_child(tutorial_label)
	roll_button=button("Roll the dice",roll_dice,sidebar)
	var grid=GridContainer.new(); grid.columns=2; sidebar.add_child(grid)
	for kind in ["road","settlement","city","beacon"]:
		var b=button(kind.capitalize(),func(): choose_mode(kind),grid); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		action_buttons.append(b)
	details=label("Tap a territory to inspect it.",16); details.custom_minimum_size.y=80; sidebar.add_child(details)
	button("Trade resources",toggle_trade,sidebar)
	trade_panel=VBoxContainer.new(); sidebar.add_child(trade_panel); trade_panel.visible=false
	give_choice=resource_choice(trade_panel); receive_choice=resource_choice(trade_panel); receive_choice.select(1)
	partner_choice=OptionButton.new(); trade_panel.add_child(partner_choice)
	amount_choice=SpinBox.new(); amount_choice.min_value=1; amount_choice.max_value=5; amount_choice.value=2; trade_panel.add_child(amount_choice)
	button("Offer trade",execute_trade,trade_panel)
	end_button=button("End turn",end_turn,sidebar)
	button("Pause / Save / Settings",show_pause,sidebar)
	button("Rules & costs",show_rules,sidebar)
	resized.connect(adapt_layout)
	adapt_layout()

func adapt_layout() -> void:
	if not is_instance_valid(root_box): return
	var portrait=size.x<size.y
	root_box.vertical=portrait
	side_panel.custom_minimum_size=Vector2(0,320) if portrait else Vector2(340,0)
	side_panel.size_flags_vertical=Control.SIZE_EXPAND_FILL if portrait else Control.SIZE_FILL
	if is_instance_valid(overlay):
		overlay.offset_left=size.x*0.15; overlay.offset_right=-size.x*0.15

func label(text: String,font_size: int=18) -> Label:
	var l=Label.new(); l.text=text; l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; l.add_theme_font_size_override("font_size",font_size)
	return l

func button(text: String,callback: Callable,parent: Node) -> Button:
	var b=Button.new(); b.text=text; b.custom_minimum_size.y=88 if OS.get_name()=="Android" else 48; b.pressed.connect(callback); parent.add_child(b)
	return b

func resource_choice(parent: Node) -> OptionButton:
	var choice=OptionButton.new(); choice.custom_minimum_size.y=44
	for resource in Game.RESOURCES: choice.add_item(resource)
	parent.add_child(choice); return choice

func panel(title: String) -> VBoxContainer:
	if is_instance_valid(overlay): overlay.queue_free()
	overlay=PanelContainer.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left=size.x*0.15; overlay.offset_right=-size.x*0.15; overlay.offset_top=50; overlay.offset_bottom=-50
	add_child(overlay)
	var scroll=ScrollContainer.new(); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; overlay.add_child(scroll)
	var content=VBoxContainer.new(); content.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroll.add_child(content)
	content.add_child(label(title,30)); content.add_child(HSeparator.new())
	return content

func close_overlay() -> void:
	if is_instance_valid(overlay): overlay.queue_free()
	overlay=null

func show_menu() -> void:
	var content=panel("HEXBOUND KINGDOMS")
	content.add_child(label("Light the beacons. Bind the scattered realms.\n\nA strategy game of trade, changing seasons and connected territories.",22))
	var count=OptionButton.new()
	for value in [2,3,4]: count.add_item("%d kingdoms · you + %d AI" % [value,value-1])
	count.select(count_choice-2); count.item_selected.connect(func(i): count_choice=i+2); content.add_child(count)
	var level=OptionButton.new()
	for value in ["Wanderer · easy","Steward · normal","Sovereign · hard"]: level.add_item(value)
	level.select(difficulty_choice); level.item_selected.connect(func(i): difficulty_choice=i); content.add_child(level)
	button("Begin a new kingdom",func(): start_game(false),content)
	button("Learn by playing",func(): start_game(true),content)
	var resume=button("Resume saved kingdom",resume_game,content); resume.disabled=not FileAccess.file_exists("user://kingdom.json")
	button("Settings",show_settings,content)
	button("How to play",show_rules,content)
	button("Privacy & credits",show_credits,content)
	content.add_child(label("Original territory rules • Offline play • No account required\nDevelopment build 0.1.0 · advertisements disabled",15))

func start_game(learn: bool) -> void:
	epoch+=1
	close_overlay(); game.new_game(count_choice,difficulty_choice,104729 if learn or "--capture" in OS.get_cmdline_user_args() else 0)
	board.set_zoom(1.0)
	tutorial=learn; tutorial_step=0; selected=-1; road_start=-1; mode="inspect"; busy=false
	populate_partners(); refresh(); game.save_game()

func populate_partners() -> void:
	partner_choice.clear(); partner_choice.add_item("Bank: give 3, receive 1",-1)
	for p in range(1,game.players.size()): partner_choice.add_item(game.players[p].name,p)

func resume_game() -> void:
	if game.load_game():
		epoch+=1
		close_overlay(); tutorial=false; selected=-1; road_start=-1; busy=false; mode="inspect"; populate_partners(); refresh()
		if game.active != 0 and game.winner < 0: run_opponents()
	else:
		var content=panel("Save unavailable"); content.add_child(label(game.last_error)); button("Main menu",show_menu,content)

func refresh() -> void:
	if game.players.is_empty(): return
	board.game=game; board.selected=selected; board.road_start=road_start; board.mode=mode; board.set_process(not reduced_motion); board.queue_redraw()
	status.text="Round %d  •  %s season  •  %s  •  %d actions  •  Dice %s" % [game.round_number,Game.RESOURCES[(game.round_number-1)%5],game.players[game.active].name,game.actions,str(game.last_roll) if game.last_roll > 0 else "—"]
	scoreboard.text="PRESTIGE / %d\n" % Game.TARGET
	for p in range(game.players.size()): scoreboard.text+="%s%s   %d\n" % ["› " if p == game.active else "",game.players[p].name,game.players[p].points]
	inventory.text="YOUR STOCKPILE\n"
	for k in range(5): inventory.text+="%s: %d%s" % [Game.RESOURCES[k],game.players[0].resources[k],"  " if k%2==0 else "\n"]
	roll_button.disabled=busy or game.active != 0 or game.phase != "roll"
	end_button.disabled=busy or game.active != 0 or game.phase != "act"
	for b in action_buttons: b.disabled=busy or game.active != 0 or game.phase != "act" or game.actions <= 0
	log_label.text="\n".join(game.history.slice(maxi(0,game.history.size()-2)))
	tutorial_label.visible=tutorial
	if tutorial:
		var steps=["1 / 5 · Roll the dice. Matching territories produce resources; the season grants an extra supply.","2 / 5 · Tap your glowing home territory to inspect its biome and production number.","3 / 5 · Build a Beacon on your home: tap Beacon, then your home. It grants two prestige.","4 / 5 · Open Trade, choose different resources and make a bank trade (3 for 1).", "5 / 5 · End your turn. Watch rival kingdoms grow. Tutorial complete after they finish."]
		tutorial_label.text=steps[mini(tutorial_step,4)]
	if game.phase == "block": details.text="STORM: tap a different territory to block its production. Gain one salvaged Ember."
	if game.winner >= 0 and not is_instance_valid(overlay):
		var content=panel("%s wins!" % game.players[game.winner].name)
		content.add_child(label("%d prestige in %d rounds. Every beacon made a difference." % [game.players[game.winner].points,game.round_number],22))
		if ads and ads.enabled:
			reward_button=button("Watch a test ad: unlock beacon glow",func(): ads.show_reward(true),content)
			reward_button.disabled=not ads.can_reward(true)
		button("New kingdom",func():
			if ads: ads.match_to_menu(true)
			show_menu(),content)

func select_tile(i: int) -> void:
	if busy or is_instance_valid(overlay): return
	selected=i
	var t=game.tiles[i]
	details.text="Territory %d · %s · produces on %d\n%s%s" % [i+1,Game.RESOURCES[t.biome],t.number,"Unclaimed" if t.owner < 0 else game.players[t.owner].name + (" · City" if t.level == 2 else " · Settlement")," · Beacon" if t.beacon else ""]
	if tutorial and tutorial_step==1 and t.owner==0: tutorial_step=2
	if game.active==0:
		if game.phase=="block": perform(game.block_tile(i))
		elif mode=="road":
			if road_start < 0: road_start=i; details.text+="\nNow tap an adjacent territory to place the road."
			else:
				var ok=game.build("road",road_start,i); road_start=-1; perform(ok)
		elif mode in ["settlement","city","beacon"]:
			var ok=game.build(mode,i)
			if ok and tutorial and tutorial_step==2 and mode=="beacon": tutorial_step=3
			perform(ok)
	refresh()

func choose_mode(kind: String) -> void:
	mode=kind; road_start=-1
	var costs=[]
	for k in range(5):
		if Game.COSTS[kind][k] > 0: costs.append("%d %s" % [Game.COSTS[kind][k],Game.RESOURCES[k]])
	details.text="%s costs %s.\n%s" % [kind.capitalize(),", ".join(costs),"Tap a connected territory, then its neighbor." if kind=="road" else "Tap a legal territory (outlined)."]
	refresh()

func roll_dice() -> void:
	if busy or game.active != 0: return
	if game.roll():
		if tutorial and tutorial_step==0: tutorial_step=1
		play_tone(440)
		game.save_game(); refresh()

func perform(ok: bool) -> void:
	if ok:
		play_tone(620); game.save_game()
	else:
		details.text=game.last_error; play_tone(180)
	refresh()

func toggle_trade() -> void:
	trade_panel.visible=not trade_panel.visible
	mode="inspect"; road_start=-1; refresh()

func execute_trade() -> void:
	if busy or game.active != 0: return
	var p=-1 if partner_choice.selected==0 else partner_choice.get_selected_id()
	var ok=game.bank_trade(give_choice.selected,receive_choice.selected) if p == -1 else game.player_trade(p,give_choice.selected,receive_choice.selected,int(amount_choice.value))
	if ok and tutorial and tutorial_step==3: tutorial_step=4
	perform(ok)

func end_turn() -> void:
	if busy or game.active != 0: return
	if game.end_turn():
		mode="inspect"; road_start=-1; game.save_game(); run_opponents()
	else: perform(false)

func run_opponents() -> void:
	var current_epoch=epoch
	busy=true; refresh()
	while game.active != 0 and game.winner < 0:
		await get_tree().create_timer(0.35 if reduced_motion else 0.85).timeout
		if current_epoch!=epoch: return
		# A pause/menu overlay suspends AI until it is closed.
		while is_instance_valid(overlay):
			await get_tree().process_frame
			if current_epoch!=epoch: return
		game.ai_turn(); game.save_game(); refresh()
	busy=false
	if tutorial and tutorial_step==4:
		tutorial=false; game.log_event("Tutorial complete! Extend roads two hexes from settlements, claim land, and light diverse beacons.")
	refresh()

func show_pause() -> void:
	var content=panel("Kingdom paused")
	button("Return to the realm",close_overlay,content)
	button("Save kingdom",func():
		var ok=game.save_game(); content.add_child(label("Saved on this device." if ok else game.last_error)),content)
	button("Settings",show_settings,content)
	button("Main menu",func():
		game.save_game(); show_menu(),content)

func show_settings() -> void:
	var content=panel("Settings")
	var audio=CheckButton.new(); audio.text="Sound effects"; audio.button_pressed=sound_enabled; content.add_child(audio)
	audio.toggled.connect(func(value): sound_enabled=value; save_settings())
	var motion=CheckButton.new(); motion.text="Reduce motion"; motion.button_pressed=reduced_motion; content.add_child(motion)
	motion.toggled.connect(func(value): reduced_motion=value; save_settings(); refresh())
	if ads and ads.supported():
		var ad_toggle=CheckButton.new(); ad_toggle.text="Enable Google test advertisements"; ad_toggle.button_pressed=ads.enabled; content.add_child(ad_toggle)
		ad_toggle.toggled.connect(func(value): ads.set_enabled(value))
		if ads.privacy_options_required(): button("Advertising privacy choices",func(): ads.privacy_options(),content)
	content.add_child(label("Advertisements are off by default. Only test ads can be enabled in a native ad build. Purchases and ad removal are not offered. No account, analytics or cloud saves.",18))
	button("Back",func():
		if game.players.is_empty(): show_menu()
		else: show_pause(),content)

func save_settings() -> void:
	preferences.set_value("settings","sound",sound_enabled); preferences.set_value("settings","reduced_motion",reduced_motion)
	preferences.save("user://settings.cfg")

func show_rules() -> void:
	var content=panel("The realm's charter")
	content.add_child(label("GOAL\nReach 12 prestige: settlements 1, cities 2, beacons +2. With a beacon, each controlled biome beyond your second grants +1.\n\nTURN\nRoll two dice. All matching occupied territories produce their biome resource (cities twice). The current season adds one extra there. Your supply shipment grants one seasonal resource each non-storm roll. Seven moves the storm instead; blocked land produces nothing. You receive one Ember salvage. Then spend up to two actions building or trading. End your turn.\n\nTERRITORIES & ROADS\nRoads connect adjacent hex centers, extending your existing network. Opponent land blocks connections. Settlements require your road network and an empty adjacent ring: no occupied neighboring hexes. Upgrade your own settlement to a city, or light one beacon per occupied territory.\n\nCOSTS\nRoad: 1 Timber + 1 Ore\nSettlement: 1 Timber + 1 Grain + 1 Reeds\nCity: 2 Grain + 3 Ore\nBeacon: 1 Ore + 1 Reeds + 2 Ember\n\nTRADE\nBank: 3 of one resource for 1 different resource. Rivals evaluate offers by stock scarcity; offer 1–5 units for 1. Every accepted trade consumes one action.\n\nSTRATEGY\nBuild roads out beyond your home. Control diverse biomes, then light beacons. Seasons advance each complete round. Dice and terrain are seeded; difficulty changes AI planning, never resource bonuses.\n\nSAVES\nYour game saves after actions and each AI turn. One local save slot, no cloud synchronization.",18))
	button("Back",func():
		if game.players.is_empty(): show_menu()
		else: close_overlay(),content)

func play_tone(frequency: float) -> void:
	if not sound_enabled: return
	var audio=AudioStreamWAV.new(); audio.format=AudioStreamWAV.FORMAT_16_BITS; audio.mix_rate=22050
	var bytes=PackedByteArray(); var samples=3307; bytes.resize(samples*2)
	for i in range(samples):
		var amplitude=sin(TAU*frequency*i/22050.0)*exp(-float(i)/900.0)*0.16
		bytes.encode_s16(i*2,int(amplitude*32767))
	audio.data=bytes; sound.stream=audio; sound.play()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and not game.players.is_empty(): game.save_game()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST: show_pause() if not game.players.is_empty() else show_menu()

func show_credits() -> void:
	var content=panel("Privacy & credits")
	content.add_child(label("The offline game stores progress and settings only on this device. Clear app storage to delete them. No account, backend, cloud save or analytics. Optional native test ads are off by default and require a separate consent/privacy review before commercial release. Publisher contact and public privacy policy must be finalized before distribution.\n\nOriginal game art, rules and sound: Hexbound Kingdoms project. Engine: Godot. Optional ad/consent wrapper: Poing Studios. Store graphic type: DejaVu Sans.",18))
	for file in ["Godot-LICENSE.txt","Poing-AdMob-LICENSE.txt","DejaVu-COPYRIGHT.txt"]:
		content.add_child(label(FileAccess.get_file_as_string("res://third-party-licenses/"+file),14))
	button("Back",show_menu,content)

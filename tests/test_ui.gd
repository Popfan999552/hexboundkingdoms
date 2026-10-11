extends SceneTree
const Main=preload("res://scripts/main.gd")
var failures=0
var checks=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1; push_error("UI FAIL: "+message)
func _init() -> void:
	call_deferred("run")
func run() -> void:
	var app=Main.new(); root.add_child(app)
	await process_frame
	check(is_instance_valid(app.overlay),"main menu opens")
	app.start_game(true)
	await process_frame
	check(app.game.players.size()==3 and app.tutorial_step==0,"new tutorial starts")
	app.roll_button.pressed.emit()
	await process_frame
	check(app.tutorial_step==1 and app.game.phase in ["act","block"],"roll control advances tutorial")
	if app.game.phase=="block": app.select_tile(0)
	var h=-1
	for i in range(37):
		if app.game.tiles[i].owner==0: h=i; break
	# Exercise board hit testing, not just a direct game-model call.
	var click=InputEventMouseButton.new(); click.button_index=MOUSE_BUTTON_LEFT; click.pressed=true; click.position=app.board.centers[h]
	app.board._input_board(click)
	click.pressed=false; app.board._input_board(click)
	check(app.selected==h and app.tutorial_step==2,"mouse/touch emulation selects home")
	app.action_buttons[3].pressed.emit(); app.select_tile(h)
	check(app.game.tiles[h].beacon and app.tutorial_step==3,"Beacon button constructs and progresses lesson")
	app.toggle_trade(); app.execute_trade()
	check(app.tutorial_step==4 and app.game.actions==0,"actual trade finishes economy lesson")
	app.reduced_motion=true; app.end_button.pressed.emit()
	await create_timer(1.2).timeout
	check(app.game.active==0 and not app.busy and not app.tutorial,"opponent turn sequence completes tutorial")
	check(app.game.round_number==2,"AI advances a full round")
	app.show_pause(); check(is_instance_valid(app.overlay),"pause opens")
	app.close_overlay(); await process_frame
	check(not is_instance_valid(app.overlay),"pause closes")
	check(app.game.save_game(),"UI save supported")
	var before=app.game.snapshot(); app.game.new_game(2,0,99); app.resume_game()
	await process_frame
	check(app.game.snapshot()==before,"resume restores UI kingdom")
	# Replacing a game while an AI timer is pending must cancel the old coroutine.
	app.game.phase="act"; app.end_turn(); app.start_game(false)
	await create_timer(1.3).timeout
	check(app.game.active==0 and app.game.round_number==1 and app.game.phase=="roll" and not app.busy,"new game cancels stale AI work")
	for dimensions in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(2400,1080),Vector2i(800,1280)]:
		app.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		app.size=Vector2(dimensions)
		await process_frame; await process_frame
		check(app.board.centers.size()==37,"board mounted at %s" % dimensions)
		check(app.root_box.vertical==(dimensions.x<dimensions.y),"adaptive orientation at %s" % dimensions)
		var fits=true
		for center in app.board.centers:
			if center.x-app.board.radius<0 or center.x+app.board.radius>app.board.size.x or center.y-app.board.radius<0 or center.y+app.board.radius>app.board.size.y: fits=false
		check(fits,"all tiles fit board at %s" % dimensions)
		check(app.get_global_rect().encloses(app.board.get_global_rect()),"board stays inside screen at %s" % dimensions)
	app.board.set_zoom(1.7); await process_frame
	check(is_equal_approx(app.board.zoom,1.7),"map zoom works")
	app.board.pan=Vector2(40,20); app.board.set_zoom(1.0)
	check(app.board.pan==Vector2.ZERO,"fit map recenters")
	var touch_a=InputEventScreenTouch.new(); touch_a.index=0; touch_a.pressed=true; touch_a.position=Vector2(100,100)
	var touch_b=InputEventScreenTouch.new(); touch_b.index=1; touch_b.pressed=true; touch_b.position=Vector2(200,100)
	app.board._input_board(touch_a); app.board._input_board(touch_b)
	var drag=InputEventScreenDrag.new(); drag.index=1; drag.position=Vector2(250,100)
	app.board._input_board(drag)
	check(app.board.zoom>1.0 and not app.board.pointer_down,"two-finger pinch zooms without building")
	touch_a.pressed=false; touch_b.pressed=false; app.board._input_board(touch_a); app.board._input_board(touch_b)
	app.board.set_zoom(1.0)
	app.show_settings(); check(is_instance_valid(app.overlay),"settings opens")
	app.show_rules(); check(is_instance_valid(app.overlay),"rules opens")
	var Ads=load("res://scripts/ads.gd"); var ads=Ads.new(); root.add_child(ads)
	check(not ads.supported(),"desktop never claims native ads available")
	ads.set_enabled(true); check(not ads.enabled and not ads.show_reward(true),"unavailable native ads fail closed")
	ads.match_to_menu(false); check(ads.completed_matches==0,"active gameplay is not an ad transition")
	ads.queue_free(); app.queue_free(); await process_frame
	print("UI_TEST_RESULT: %d checks, %d failures" % [checks,failures]); quit(1 if failures else 0)

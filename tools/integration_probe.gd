extends SceneTree

func _initialize():
	call_deferred("_run")

func _run():
	var args = OS.get_cmdline_user_args()
	var requested: String = args[0] if args.size() else ""
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	game._start_new()
	game._on_action("")
	var output = {}
	if requested in ["cup_escape","cup_return_escape"]:
		if requested == "cup_return_escape":
			for action in ["mark","photo","mug","wash"]: game.story.apply_action(action)
			game.world.apply_story(game.story.phase,0)
		game._interact("mug")
		var escape = InputEventKey.new()
		escape.physical_keycode = KEY_ESCAPE
		escape.pressed = true
		game._unhandled_input(escape)
		output = {"phase":game.story.phase,"memories":game.story.memories,"mode":game.mode}
	elif requested == "pending_outcome":
		for action in ["mark","photo","mug"]: game.story.apply_action(action)
		game._on_action("wash")
		if game.has_method("_capture_save") and game.has_method("_restore_snapshot"):
			var saved = game._capture_save()
			output["pending"] = saved.get("pending_action","")
			game._on_action("")
			output["acknowledged"] = game._capture_save().get("pending_action","")
			output["restored"] = game._restore_snapshot(saved)
			output["mode"] = game.mode
			output["title"] = game.ui.modal_title.text
		else:
			output = {"pending":"","acknowledged":"","restored":false,"mode":game.mode}
	elif requested == "motion_clue":
		game._settings_changed(false,false,0.0023)
		var before: float = game.world._elapsed
		game._process(0.25)
		output = {"world_advanced":game.world._elapsed > before,"camera_bob":game.player.motion_enabled}
	print("INTEGRATION_JSON:" + JSON.stringify(output))
	game.queue_free()
	await process_frame
	quit(0)

extends SceneTree

const BASELINE = ["mark", "photo", "mug", "wash", "mug"]
var game

func _initialize():
	call_deferred("_run")

func state_at(actions: Array):
	game.story = load("res://scripts/story_state.gd").new()
	for action in actions:
		game.story.apply_action(action)
	game._create_world()
	game.ui.show_game()
	game._apply_mode("play")

func visible_world():
	return game.mode == "play" and game.player.enabled and not game.ui.modal.visible

func _run():
	var name = OS.get_cmdline_user_args()[0]
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await physics_frame
	game._start_new()
	var result = {}
	if name == "entry":
		result = {"continuous":visible_world(),"narration":not game.ui.subtitle.text.is_empty()}
	elif name == "observe":
		state_at([])
		var continuous = true
		for id in ["mark", "photo"]:
			game._interact(id)
			continuous = continuous and visible_world()
		result = {"continuous":continuous,"memories":game.story.memories}
	elif name == "mug":
		state_at([])
		game._interact("mug")
		result["continuous"] = visible_world()
		var meshes = game.player.camera.find_children("*", "MeshInstance3D", true, false)
		result["held_meshes"] = meshes.size()
		var escape = InputEventKey.new()
		escape.physical_keycode = KEY_ESCAPE
		escape.pressed = true
		game._unhandled_input(escape)
		result["collected"] = game.story.memories.has("mug")
	elif name == "curtain":
		state_at(BASELINE)
		var curtain = game.world._curtains[0]
		var initial = curtain.transform
		game._interact("curtain")
		game._interact("curtain")
		await create_timer(0.35).timeout
		var mid = curtain.transform
		var continuous = visible_world()
		await create_timer(3.0).timeout
		result = {"animated":not initial.is_equal_approx(mid) and not mid.is_equal_approx(curtain.transform),"continuous":continuous and visible_world(),"phase":game.story.phase,"commits":game.story.history.count("seal")}
	elif name == "appliances":
		state_at(BASELINE + ["seal"])
		var phases = []
		var continuous = true
		for id in ["sink", "wallpad", "tile"]:
			game._interact(id)
			await create_timer(0.1).timeout
			continuous = continuous and visible_world()
			await create_timer(3.6).timeout
			phases.append(game.story.phase)
		result = {"continuous":continuous,"phases":phases,"exposure":game.story.exposure}
	elif name == "alternate":
		state_at(BASELINE)
		game.active_target = "curtain"
		var event = InputEventKey.new()
		event.physical_keycode = KEY_Q
		event.pressed = true
		game._unhandled_input(event)
		await create_timer(3.5).timeout
		result = {"continuous":visible_world(),"phase":game.story.phase,"exposure":game.story.exposure,"look_count":game.story.history.count("look")}
	elif name == "resume":
		state_at(["mark", "photo", "mug"])
		game._on_action("wash")
		var saved = game._capture_save()
		result["pending"] = saved.get("pending_action", "")
		game._process(120.0)
		result["acknowledged"] = game._capture_save().get("pending_action", "")
		result["restored"] = game._restore_snapshot(saved)
		result["continuous"] = visible_world()
		result["narration"] = not game.ui.subtitle.text.is_empty()
	elif name == "audio":
		state_at(BASELINE)
		game._settings_changed(true, true, 0.0023)
		var point = game.world.targets.curtain.global_position
		game._interact("curtain")
		await create_timer(0.15).timeout
		var spatial_recording = false
		for source in game.find_children("*", "AudioStreamPlayer3D", true, false):
			if source.playing and source.stream != null and source.stream.resource_path.contains("/vendor/") and source.global_position.distance_to(point) < 0.75:
				spatial_recording = true
		game._settings_changed(false, true, 0.0023)
		await process_frame
		var audible = 0
		for kind in ["AudioStreamPlayer3D", "AudioStreamPlayer"]:
			for source in game.find_children("*", kind, true, false):
				if source.playing and source.volume_db > -60:
					audible += 1
		result = {"spatial_recording":spatial_recording,"audible_when_muted":audible}
	elif name == "darkness":
		state_at([])
		var environments = game.world.find_children("*", "WorldEnvironment", true, false)
		var lights = game.world.find_children("*", "Light3D", true, false)
		var local_light = false
		for light in lights:
			if not light is DirectionalLight3D and light.visible and light.light_energy > 0:
				local_light = true
		result = {"ambient":environments[0].environment.ambient_light_energy,"local_light":local_light,"fov":game.player.camera.fov}
	elif name == "mark":
		state_at([])
		var shapes = game.world.targets.mark.find_children("*", "CollisionShape3D", true, false)
		result = {"width":shapes[0].shape.size.x,"height":shapes[0].shape.size.y,"target_label":game.world.targets.mark.get_meta("label")}
	elif name == "materials":
		state_at([])
		var maps = []
		for id in ["plaster", "wood", "tile"]:
			var mat = game.world._materials.get(id)
			maps.append(mat != null and mat.albedo_texture != null and mat.normal_enabled and mat.normal_texture != null)
		result = {"mapped":maps}
	print("ATMOSPHERE_JSON:" + JSON.stringify(result))
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	quit()

extends SceneTree
func _initialize():
	call_deferred("_run")
func _run():
	var player = load("res://scripts/player.gd").new()
	root.add_child(player)
	await process_frame
	player.enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var motion = InputEventMouseMotion.new()
	motion.relative = Vector2(100,30)
	player._unhandled_input(motion)
	var idle = player.rotation.y
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	player._unhandled_input(motion)
	print("LOOK_JSON:" + JSON.stringify({"idle":idle,"yaw":player.rotation.y,"pitch":player.pitch}))
	player.queue_free()
	await process_frame
	quit()

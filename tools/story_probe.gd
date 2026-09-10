extends SceneTree

func _initialize():
	var script = load("res://scripts/story_state.gd")
	if script == null:
		push_error("Story state script unavailable")
		quit(1)
		return
	var story = script.new()
	var args = OS.get_cmdline_user_args()
	var request = JSON.parse_string(args[0]) if args.size() > 0 else {}
	for action in request.get("actions", []):
		story.apply_action(action)
	var result = story.snapshot()
	result["mug_state"] = story.mug_state()
	if request.has("restore"):
		var restored = script.new()
		result["restore_ok"] = restored.restore_state(request["restore"])
		result["restored"] = restored.snapshot()
	if request.get("roundtrip", false):
		var restored = script.new()
		result["restore_ok"] = restored.restore_state(JSON.stringify(story.snapshot()))
		result["restored"] = restored.snapshot()
	print("STORY_JSON:" + JSON.stringify(result))
	quit(0)

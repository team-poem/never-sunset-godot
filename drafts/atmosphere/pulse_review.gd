## Diagnostic of the approved visible/audible wall clue; not a frozen acceptance test.
extends SceneTree
var failures: Array[String] = []
var checked = 0
func _initialize():
	root.unfocusable = true
	call_deferred("run")
func check(value: bool, label: String):
	checked += 1
	if not value: failures.append(label)
func run():
	var game = load("res://scenes/main.tscn").instantiate()
	game.qa_mode = true
	root.add_child(game)
	await process_frame
	game.set_process(false)
	for action in ["mark","photo","mug","wash","mug","seal","cover","off"]:
		game.story.apply_action(action)
	game._create_world()
	game.sound_enabled = true
	game._apply_mode("play")
	check(game.room_sound.stream.loop_end == 264600, "12-second 22050 Hz ambience loops across all 264600 sample frames")
	check(game.pulse_sound.stream.get_length() <= 1.2, "pulse source contains one beat, not a repeating sequence")
	check(game.world.has_signal("pulse_beat"), "wall owns the shared visible and audible beat")
	if game.world.has_signal("pulse_beat"):
		var beats: Array = []
		game.world.pulse_beat.connect(func(): beats.append(game.world._pulse_elapsed))
		game.world.animate(0.0)
		check(beats.size() == 1 and game.pulse_sound.playing and is_equal_approx(game.world._pulse_tile.position.z, -0.012), "first sound coincides with the visible wall peak")
		game.pulse_sound.stop()
		game.world.animate(15.99)
		game._update_audio()
		check(beats.size() == 1 and not game.pulse_sound.playing, "no extra beat between slow pulses or after audio settings update")
		game.world.animate(0.01)
		check(beats.size() == 2 and is_equal_approx(float(beats[1]), 16.0) and game.pulse_sound.playing, "slow visible and audible cadence is 16 seconds")
		game.world.apply_story("escape", 0)
		game.story.apply_action("count")
		game.world.animate(0.0)
		game.sound_enabled = false
		game._update_audio()
		game.world.animate(5.4)
		check(beats.size() == 4 and not game.pulse_sound.playing, "escape cadence is 5.4 seconds and mute suppresses its sound")
		game.sound_enabled = true
		game._update_audio()
		check(not game.pulse_sound.playing, "unmute waits for the next visible beat")
		game.world.animate(5.4)
		check(beats.size() == 5 and game.pulse_sound.playing and is_equal_approx(game.world._pulse_tile.position.z, -0.012), "unmuted accelerated beat remains synchronized")
	print("PULSE_REVIEW:", JSON.stringify({"checked":checked,"failures":failures}))
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

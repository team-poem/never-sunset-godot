## Diagnostic rehearsal of approved manual criteria; not part of the frozen acceptance suite.
extends SceneTree
var game
var failures: Array = []
var checked = 0
const BASE = ["mark", "photo", "mug", "wash", "mug"]
func _initialize(): call_deferred("run")
func check(value: bool, label: String):
	checked += 1
	if not value: failures.append(label)
func state_at(actions: Array):
	game._clear_narration()
	game.narration_recent.clear()
	game.pending_action = ""
	game.story = load("res://scripts/story_state.gd").new()
	for action in actions: game.story.apply_action(action)
	game._create_world()
	game.ui.show_game()
	game._apply_mode("play")
func continuous() -> bool:
	return game.mode == "play" and game.player.enabled and not game.ui.modal.visible
func press(code: int):
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._unhandled_input(event)
func run():
	game = load("res://scenes/main.tscn").instantiate()
	game.qa_mode = true
	root.add_child(game)
	await process_frame
	game.saved_available = true
	game._on_command("start")
	game._on_action("__restart")
	game._interact("mug")
	press(KEY_ESCAPE)
	check(continuous(), "restart confirmation then cup release stays in game")
	state_at([])
	game._interact("mark")
	var first = game.ui.subtitle.text
	game._interact("photo")
	check(game.ui.subtitle.text == first and game.narration_queue.size() >= 2, "observations queue instead of overwrite")
	var queued_save = game._capture_save()
	var queue_count = game.narration_queue.size()
	game._process(120)
	game._restore_snapshot(queued_save)
	check(game.ui.subtitle.text == first and game.narration_queue.size() == queue_count and continuous(), "queued narration restores")
	state_at(["mark","photo","mug"])
	game._interact("wash")
	check(game.story.phase == "return" and continuous(), "direct wash is continuous")
	await create_timer(2.3).timeout
	game._interact("mug")
	var rotation_before = game.held_mug.rotation.y
	press(KEY_R)
	check(game.held_mug.rotation.y != rotation_before and continuous(), "held cup rotates without stopping movement")
	press(KEY_ESCAPE)
	check(game.story.phase == "dusk" and continuous(), "replacement cup release is continuous")
	for pair in [["seal","curtain"],["cover","sink"],["off","wallpad"],["count","tile"]]:
		game._interact(pair[1])
		var save = game._capture_save()
		check(save.pending_action == pair[0], "pending narration " + pair[0])
		game._process(120)
		check(game.pending_action.is_empty(), "narration naturally completes " + pair[0])
		check(game._restore_snapshot(save) and continuous() and not game.ui.subtitle.text.is_empty(), "restore continuous " + pair[0])
	game._interact("door")
	check(game.story.phase == "landing" and continuous(), "door exit is direct")
	game._interact("stairs")
	check(game.story.phase == "threshold" and continuous(), "stairs continue without modal")
	game._interact("worn")
	check(game.story.ending == "survivor", "direct worn key survivor")
	state_at(BASE + ["seal","cover","off","count","leave"])
	game._interact("archive")
	check(game.mode == "dialog", "optional archive remains readable")
	game._on_action("archive")
	check(continuous() and game.story.report, "archive returns to continuous story")
	game._interact("exit")
	game._interact("worn")
	check(game.story.ending == "witness", "direct witness route")
	state_at(BASE)
	for pair in [["curtain","look"],["sink","touch"],["wallpad","answer"],["tile","knock"]]:
		game.active_target = pair[0]
		press(KEY_Q)
		check(game.story.history.has(pair[1]) and continuous(), "Q branch " + pair[1])
		press(KEY_Q)
		check(game.story.history.count(pair[1]) == 1, "no duplicate Q " + pair[1])
		await create_timer(3.2).timeout
	check(game.story.voice, "voice evidence reachable")
	game._interact("door")
	game._interact("stairs")
	game._interact("new")
	check(game.story.ending == "registered", "direct registered route")
	print("FLOW_REVIEW:",JSON.stringify({"checked":checked,"failures":failures}))
	game.queue_free()
	await create_timer(0.2).timeout
	quit(0 if failures.is_empty() else 1)

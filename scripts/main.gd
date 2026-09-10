extends Node3D

const State = preload("res://scripts/story_state.gd")
const World = preload("res://scripts/world.gd")
const Player = preload("res://scripts/player.gd")
const GameUI = preload("res://scripts/game_ui.gd")
const Content = preload("res://scripts/story_content.gd")
const SAVE_PATH = "user://progress.json"
const SETTINGS_PATH = "user://settings.json"
const TIMES = {"home":"20:17","return":"20:26","dusk":"20:30","drain":"21:06","signal":"22:40","pulse":"00:03","escape":"00:09","landing":"00:11","threshold":"00:13","ending":"05:41"}

var story
var world
var player
var ui
var mode: String = "title"
var active_target: String = ""
var sound_enabled: bool = true
var motion_enabled: bool = true
var look_sensitivity: float = 0.0023
var sound_sources: Array = []
var room_sound: AudioStreamPlayer
var step_sound: AudioStreamPlayer3D
var pipe_sound: AudioStreamPlayer3D
var pulse_sound: AudioStreamPlayer3D
var curtain_sound: AudioStreamPlayer3D
var subtitle_remaining: float = 0.0
var narration_queue: Array = []
var narration_recent: Dictionary = {}
var contact_index: int = 0
var extra_step_pending: bool = false
var extra_step_done: bool = false
var previous_speed: float = 0.0
var auto_save_time: float = 0.0
var saved_available: bool = false
var dialog_return_mode: String = "play"
var pending_action: String = ""
var held_mug: Node3D
var qa_mode: bool = OS.get_cmdline_user_args().has("--qa-no-save")

func _ready():
	story = State.new()
	_load_settings()
	_create_world()
	ui = GameUI.new()
	add_child(ui)
	ui.action_requested.connect(_on_action)
	ui.command_requested.connect(_on_command)
	ui.settings_changed.connect(_settings_changed)
	ui.sound_enabled = sound_enabled
	ui.motion_enabled = motion_enabled
	ui.look_sensitivity = look_sensitivity
	saved_available = _valid_save() != null
	ui.show_title(saved_available)
	_apply_mode("title")
	_update_hud()

func _exit_tree():
	for source in sound_sources:
		if is_instance_valid(source):
			source.stop()
			source.stream = null

func _create_world():
	_release_mug()
	if player:
		remove_child(player)
		player.queue_free()
	if world:
		remove_child(world)
		world.queue_free()
	for source in sound_sources:
		if is_instance_valid(source):
			source.stop()
			source.stream = null
			source.queue_free()
	sound_sources.clear()
	world = World.new()
	add_child(world)
	if story.phase == "ending":
		if story.ending == "registered": world.build_apartment()
		else: world.build_dawn()
	elif story.phase == "threshold" and world.has_method("build_threshold"):
		world.build_threshold()
	elif story.phase in ["landing","threshold"]:
		world.build_landing()
	else:
		world.build_apartment()
	world.apply_story("home" if story.phase == "ending" and story.ending == "registered" else story.phase, story.exposure)
	player = Player.new()
	add_child(player)
	player.position = world.get_spawn()
	player.motion_enabled = motion_enabled
	player.sensitivity = look_sensitivity
	player.footstep.connect(_on_footstep)
	_setup_audio()

func _setup_audio():
	room_sound = AudioStreamPlayer.new()
	var room_stream: AudioStreamWAV = load("res://assets/audio/room.wav").duplicate()
	room_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	room_stream.loop_end = int(room_stream.data.size() / 2)
	room_sound.stream = room_stream
	room_sound.volume_db = -15
	add_child(room_sound)
	sound_sources.append(room_sound)
	step_sound = AudioStreamPlayer3D.new()
	step_sound.stream = load("res://assets/audio/step.wav")
	step_sound.volume_db = -13
	step_sound.max_distance = 10
	add_child(step_sound)
	sound_sources.append(step_sound)
	pipe_sound = AudioStreamPlayer3D.new()
	pipe_sound.stream = load("res://assets/audio/pipe.wav")
	pipe_sound.volume_db = -14
	pipe_sound.max_distance = 12
	pipe_sound.unit_size = 2.5
	add_child(pipe_sound)
	if world.targets.has("sink"):
		pipe_sound.global_position = world.targets["sink"].global_position
	sound_sources.append(pipe_sound)
	pipe_sound.finished.connect(func(): if is_instance_valid(pipe_sound) and story.phase == "drain": pipe_sound.play())
	pulse_sound = AudioStreamPlayer3D.new()
	pulse_sound.stream = load("res://assets/audio/pulse.wav")
	pulse_sound.volume_db = -13
	pulse_sound.max_distance = 14
	pulse_sound.unit_size = 3
	add_child(pulse_sound)
	if world.targets.has("tile"):
		pulse_sound.global_position = world.targets["tile"].global_position
	sound_sources.append(pulse_sound)
	pulse_sound.finished.connect(func(): if is_instance_valid(pulse_sound) and story.phase in ["pulse","escape"]: pulse_sound.play())
	curtain_sound = AudioStreamPlayer3D.new()
	curtain_sound.stream = load("res://assets/vendor/kenney/rpg-audio/cloth1.ogg")
	curtain_sound.volume_db = -13
	curtain_sound.max_distance = 10
	add_child(curtain_sound)
	if world.targets.has("curtain"):
		curtain_sound.global_position = world.targets["curtain"].global_position
	sound_sources.append(curtain_sound)
	_update_audio()

func _update_audio():
	var audible = sound_enabled and mode not in ["title","ending"]
	for source in sound_sources:
		if is_instance_valid(source):
			source.volume_db = -80 if not audible else float(source.get_meta("gain_db", -18 if source == room_sound else (-20 if source == curtain_sound or source == step_sound else -15)))
	if not audible:
		for source in sound_sources:
			if is_instance_valid(source): source.stop()
		return
	if not room_sound.playing: room_sound.play()
	if story.phase == "drain" and not pipe_sound.playing: pipe_sound.play()
	elif story.phase != "drain": pipe_sound.stop()
	if story.phase in ["pulse","escape"] and not pulse_sound.playing: pulse_sound.play()
	elif story.phase not in ["pulse","escape"]: pulse_sound.stop()

func _on_footstep(point: Vector3):
	if sound_enabled and mode == "play":
		var surface = "concrete" if world.room_at(point) == "욕실" or story.phase in ["landing", "threshold"] else "wood"
		if story.phase not in ["landing", "threshold"] and point.x < -2.0 and point.z > -2.5 and point.z < 0.5: surface = "carpet"
		var variants = 4 if surface == "wood" else (2 if surface == "carpet" else 3)
		contact_index += 1
		step_sound.stream = load("res://assets/vendor/kenney/impact-sounds/footstep_%s_%03d.ogg" % [surface, contact_index % variants])
		step_sound.global_position = point + Vector3(0, 0.2, 0)
		step_sound.pitch_scale = 0.94 + randf() * 0.1
		step_sound.play()

func _process(delta):
	if not is_instance_valid(ui): return
	if world.has_method("animate"):
		world.animate(delta)
	if mode == "play": _advance_narration(delta)
	if mode != "play":
		ui.set_target("")
		return
	_update_hud()
	active_target = ""
	var hit = player.interaction_hit()
	if not hit.is_empty() and hit.collider.has_meta("interact_id"):
		active_target = str(hit.collider.get_meta("interact_id"))
		ui.set_target(str(hit.collider.get_meta("label", active_target)))
		var alternative = _alternate_action(active_target)
		if not alternative.is_empty():
			var labels = {"look":"틈으로 보기", "touch":"손 뻗기", "answer":"통화", "knock":"두드리기"}
			ui.set_target(str(hit.collider.get_meta("label")) + " · [Q] " + labels[alternative])
	else: ui.set_target("")
	if is_instance_valid(held_mug):
		active_target = "mug"
		ui.set_target("컵 내려놓기 · Esc  /  [R] 돌려 보기")
	var current_speed = Vector2(player.velocity.x, player.velocity.z).length()
	if story.phase == "return" and previous_speed > 0.2 and current_speed < 0.03 and not extra_step_done and not extra_step_pending:
		extra_step_pending = true
		_extra_step()
	previous_speed = current_speed
	auto_save_time += delta
	if auto_save_time > 8:
		auto_save_time = 0
		_save()

func _extra_step():
	_later(0.4, func():
		extra_step_pending = false
		if mode == "play" and story.phase == "return" and not extra_step_done:
			extra_step_done = true
			_on_footstep(player.global_position + player.global_basis.z * 1.1)
			_later(1.8, func():
				if story.phase == "return": _say("방금, 내 발소리였나.", 4.0)))

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			if mode == "play" and is_instance_valid(held_mug): _on_action("mug")
			elif mode == "play": _open_settings()
			elif mode == "inspect": _on_action("mug")
			elif mode not in ["title","ending"]: _return_to_game()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_J and mode in ["play","journal"]:
			if mode == "journal": _return_to_game()
			else: _open_notebook()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_E and mode == "play":
			_interact(active_target)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_Q and mode == "play" and not is_instance_valid(held_mug):
			var action = _alternate_action(active_target)
			if not action.is_empty() and not world.action_busy(): _on_action(action)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_R and mode == "play" and is_instance_valid(held_mug):
			held_mug.rotate_y(PI / 4.0)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_F:
			var fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and mode == "play":
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else: _interact(active_target)

func _apply_mode(value: String):
	mode = value
	if player: player.enabled = value == "play"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if value == "play" else Input.MOUSE_MODE_VISIBLE
	if value == "play":
		get_viewport().gui_release_focus()
	_update_audio()

func _return_to_game():
	if mode in ["journal", "dialog"] and dialog_return_mode != "title": _contact("", "rpg-audio/bookClose", -27)
	if dialog_return_mode == "title":
		ui.show_title(saved_available)
		_apply_mode("title")
		return
	if story.phase == "ending":
		_show_ending()
		return
	ui.show_game()
	_apply_mode("play")

func _show_page(page: Dictionary, tag: String = "1504호 / 관찰"):
	dialog_return_mode = "title" if mode == "title" else "play"
	ui.show_page(page, tag)
	_apply_mode("dialog")

func _alternate_action(id: String) -> String:
	var pairs = {"dusk":{"curtain":"look"}, "drain":{"sink":"touch"}, "signal":{"wallpad":"answer"}, "pulse":{"tile":"knock"}}
	return str(pairs.get(story.phase, {}).get(id, ""))

func _interact(id: String):
	if is_instance_valid(held_mug):
		_on_action("mug")
		return
	if id.is_empty() or world.action_busy(): return
	if id == "mug":
		_inspect_mug()
		return
	if id in ["mark", "photo", "notice"]:
		story.apply_action(id)
		if id == "notice":
			_contact(id, "rpg-audio/bookOpen", -23)
			_show_page(Content.inspect(id, story.snapshot()))
		else:
			_contact(id, "impact-sounds/impactWood_light_000", -29)
			_say(Content.inspect(id, story.snapshot()).get("body", ""), 14)
		_update_hud()
		_save()
		return
	if id in ["archive", "report"]:
		_contact("archive", "rpg-audio/bookFlip1", -23)
		_show_page(Content.inspect(id, story.snapshot()))
		return
	var actions = {
		"home":{"wash":"wash" if story.memories.size() >= 3 else ""},
		"dusk":{"curtain":"seal"}, "drain":{"sink":"cover"},
		"signal":{"wallpad":"off"}, "pulse":{"tile":"count"},
		"escape":{"door":"leave"}, "landing":{"stairs":"exit", "exit":"exit", "elevator":"elevator"},
		"threshold":{"worn":"worn", "new":"new"}}
	var action = str(actions.get(story.phase, {}).get(id, ""))
	if not action.is_empty():
		_on_action(action)
	else:
		_say(Content.inspect(id, story.snapshot()).get("body", ""), 14)

func _inspect_mug():
	held_mug = world.create_mug_preview()
	held_mug.name = "HeldMug"
	player.camera.add_child(held_mug)
	held_mug.position = Vector3(0.22, -0.28, -0.5)
	held_mug.scale = Vector3.ONE * 1.15
	_contact("mug", "impact-sounds/impactGlass_light_000", -25)
	world.set_mug_held(true)
	ui.show_game()
	_apply_mode("play")
	_say(Content.inspect("mug", story.snapshot()).get("body", ""), 14.0)

func _release_mug():
	if not is_instance_valid(held_mug): return
	held_mug.get_parent().remove_child(held_mug)
	held_mug.queue_free()
	held_mug = null
	if is_instance_valid(world): world.set_mug_held(false)

func _on_action(action: String):
	if action == "mug": _release_mug()
	if action.is_empty():
		_return_to_game()
		return
	if action == "__restart":
		_start_new()
		return
	if action == "__resume":
		_resume()
		return
	var old_phase = story.phase
	if not story.apply_action(action):
		_return_to_game()
		return
	if old_phase != story.phase and story.phase in ["landing", "threshold", "ending"]:
		_create_world()
	else:
		world.begin_action(action)
		world.apply_story(story.phase, story.exposure, action in ["seal", "look"])
	_update_hud()
	if story.phase == "ending":
		_clear_narration()
		pending_action = ""
		_save()
		_show_ending()
		return
	var page = Content.outcome(action, story.snapshot())
	pending_action = "" if action == "mug" and old_phase == "home" else action
	ui.show_game()
	_apply_mode("play")
	_say("손잡이를 오른쪽으로 두면, 빠진 자리는 왼쪽." if action == "mug" and old_phase == "home" else page.get("body", ""), 14)
	_action_sound(action)
	_save()

func _contact(id: String, clip: String, gain: float = -22.0):
	if not sound_enabled or mode in ["title", "ending"]: return
	var source = AudioStreamPlayer3D.new()
	source.stream = load("res://assets/vendor/kenney/" + clip + ".ogg")
	source.max_distance = 10.0
	source.unit_size = 1.5
	source.volume_db = gain
	source.set_meta("gain_db", gain)
	add_child(source)
	source.global_position = world.targets[id].global_position if world.targets.has(id) else player.global_position
	sound_sources = sound_sources.filter(func(item): return is_instance_valid(item))
	sound_sources.append(source)
	source.finished.connect(source.queue_free)
	source.play()

func _later(seconds: float, action: Callable):
	# Delayed effects belong to this world and disappear with it on restart/restore.
	var timer = Timer.new()
	timer.one_shot = true
	world.add_child(timer)
	timer.timeout.connect(func():
		action.call()
		timer.queue_free())
	timer.start(seconds)

func _contact_after(seconds: float, id: String, clip: String, gain: float = -22.0):
	if sound_enabled: _later(seconds, func(): _contact(id, clip, gain))

func _action_sound(action: String):
	match action:
		"seal", "look":
			if sound_enabled: curtain_sound.play()
			_contact_after(0.65, "curtain", "rpg-audio/cloth2", -23)
			_contact_after(1.15, "curtain", "rpg-audio/cloth3", -24)
			_contact_after(2.0, "curtain", "rpg-audio/cloth4", -23)
		"cover", "touch":
			_contact("sink", "rpg-audio/metalPot2", -27)
			_contact_after(1.9, "sink", "rpg-audio/metalPot1", -25)
		"off", "answer":
			_contact("wallpad", "rpg-audio/metalClick", -26)
			_contact_after(2.8, "wallpad", "rpg-audio/metalLatch", -29)
		"mug": _contact("mug", "impact-sounds/impactGlass_light_001", -25)
		"wash":
			_contact("wash", "rpg-audio/metalClick", -28)
			_contact_after(1.1, "mug", "impact-sounds/impactGlass_light_000", -22)
		"count", "knock": _contact("tile", "impact-sounds/impactWood_light_000", -30)
		"leave", "exit":
			_contact("door", "rpg-audio/doorOpen_1", -25)
			_contact_after(0.8, "door", "rpg-audio/doorClose_1", -28)
		"elevator":
			_contact("elevator", "rpg-audio/creak1", -26)
			_contact_after(1.2, "elevator", "rpg-audio/creak2", -27)
		"archive": _contact("archive", "rpg-audio/bookFlip1", -25)

func _on_command(command: String):
	match command:
		"start":
			if saved_available:
				_show_page({"title":"다시 귀가하기","body":"현재 진행 기록을 새 귀가 기록으로 바꿉니다.","choices":[{"text":"처음부터 시작한다","action":"__restart"},{"text":"이전 기록 이어서","action":"__resume"}]})
			else: _start_new()
		"resume": _resume()
		"title":
			_save()
			saved_available = _valid_save() != null
			ui.show_title(saved_available)
			_apply_mode("title")

func _start_new():
	dialog_return_mode = "play"
	_clear_narration()
	narration_recent.clear()
	story = State.new()
	pending_action = ""
	extra_step_done = false
	extra_step_pending = false
	previous_speed = 0.0
	_create_world()
	ui.show_game()
	_apply_mode("play")
	_say("야근을 마치고 돌아왔다. 보리차 냄새가 났다.\n열쇠는 신발장 오른쪽 접시에 놓았다. 손을 씻기 전에 집 안을 잠깐 둘러보기로 했다.", 14.0)
	_save()

func _valid_save():
	if qa_mode: return null
	if not FileAccess.file_exists(SAVE_PATH): return null
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(SAVE_PATH)) != OK: return null
	var stored = parser.data
	if not stored is Dictionary or not stored.get("story") is Dictionary: return null
	var verified = State.new()
	if not verified.restore_state(JSON.stringify(stored.story)): return null
	return stored

func _resume():
	dialog_return_mode = "play"
	var stored = _valid_save()
	if stored == null:
		_start_new()
		return
	_restore_snapshot(stored)

func _restore_snapshot(stored: Dictionary) -> bool:
	var verified = State.new()
	if not stored.get("story") is Dictionary or not verified.restore_state(JSON.stringify(stored.story)):
		return false
	story = verified
	dialog_return_mode = "play"
	pending_action = ""
	_clear_narration()
	narration_recent.clear()
	_create_world()
	var position_data = stored.get("position", [])
	if position_data is Array and position_data.size() == 3 and position_data.all(func(value): return value is float or value is int):
		var point = Vector3(float(position_data[0]),float(position_data[1]),float(position_data[2]))
		if point.is_finite() and absf(point.x) < 20 and absf(point.z) < 20 and point.y > -1 and point.y < 6:
			player.position = point
	var yaw_value = stored.get("yaw", 0)
	var pitch_value = stored.get("pitch", 0)
	var yaw = float(yaw_value) if yaw_value is float or yaw_value is int else 0.0
	var pitch = float(pitch_value) if pitch_value is float or pitch_value is int else 0.0
	if is_finite(yaw) and is_finite(pitch): player.set_view(yaw, clampf(pitch,-1.25,1.25))
	var pending = stored.get("pending_action", "")
	if pending is String and not story.history.is_empty() and pending == story.history.back():
		pending_action = pending
	_apply_mode("play")
	if story.phase == "ending": _show_ending()
	elif _restore_narration(stored):
		ui.show_game()
	elif not pending_action.is_empty():
		ui.show_game()
		_say(Content.outcome(pending_action, story.snapshot()).get("body", ""), 14.0)
	else: _return_to_game()
	return true

func _capture_save() -> Dictionary:
	var point = player.position
	return {"story":story.snapshot(),"position":[point.x,point.y,point.z],"yaw":player.rotation.y,"pitch":player.pitch,"pending_action":pending_action,"narration_current":ui.subtitle.text,"narration_remaining":subtitle_remaining,"narration_queue":narration_queue.duplicate(true)}

func _save():
	if qa_mode: return
	if not player or not story: return
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		if ui: _say("이 환경에서는 자동 저장을 사용할 수 없습니다.", 5)
		return
	file.store_string(JSON.stringify(_capture_save()))
	file.close()

func _load_settings():
	if qa_mode: return
	if not FileAccess.file_exists(SETTINGS_PATH): return
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(SETTINGS_PATH)) != OK: return
	var settings = parser.data
	if not settings is Dictionary: return
	sound_enabled = settings.get("sound", true) == true
	motion_enabled = settings.get("motion", true) == true
	var value = float(settings.get("sensitivity",0.0023))
	look_sensitivity = clampf(value,0.0005,0.006) if is_finite(value) else 0.0023

func _settings_changed(sound: bool, motion: bool, sensitivity: float):
	sound_enabled = sound
	motion_enabled = motion
	look_sensitivity = sensitivity
	player.motion_enabled = motion
	player.sensitivity = sensitivity
	var file = null if qa_mode else FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"sound":sound,"motion":motion,"sensitivity":sensitivity}))
		file.close()
	_update_audio()

func _open_settings():
	ui.show_settings()
	_apply_mode("pause")
	_save()

func _open_notebook():
	_contact("", "rpg-audio/bookOpen", -26)
	_show_page({"title":"내가 기억하는 것","body":Content.notebook(story.snapshot()),"choices":[{"text":"수첩을 덮는다","action":""}]}, "개인 기록 / 원래 상태")
	_apply_mode("journal")

func _show_ending():
	var ending = Content.ending(story.snapshot())
	_show_page({"title":ending.get("title",""),"body":ending.get("body","")+"\n\n"+ending.get("footnote",""),"choices":[{"text":"다시 귀가하기","action":"__restart"}]}, "귀가 기록 / 끝")
	_apply_mode("ending")
	ui.hud.hide()

func _update_hud():
	if not ui or not player: return
	ui.set_hud(story.phase,world.room_at(player.position),Content.objective(story.phase,story.memories.size()),TIMES.get(story.phase,""))

func _clear_narration():
	narration_queue.clear()
	subtitle_remaining = 0.0
	if ui: ui.subtitle.text = ""

func _say(text: String, seconds: float = 4):
	if not ui or text.is_empty(): return
	var now = Time.get_ticks_msec()
	if now - int(narration_recent.get(text, -10000)) < 6000: return
	narration_recent[text] = now
	for part in text.replace("\n\n", "\n").split("\n", false):
		narration_queue.append({"text":part, "seconds":clampf(float(part.length()) / 12.0 + 1.2, 3.5, minf(seconds, 10.0))})
	if subtitle_remaining <= 0: _next_narration()

func _next_narration():
	if narration_queue.is_empty():
		ui.subtitle.text = ""
		subtitle_remaining = 0.0
		if not pending_action.is_empty():
			pending_action = ""
			_save()
		return
	var line = narration_queue.pop_front()
	ui.subtitle.text = line.text
	subtitle_remaining = line.seconds

func _advance_narration(delta: float):
	var remaining = delta
	while subtitle_remaining > 0.0 and remaining >= subtitle_remaining:
		remaining -= subtitle_remaining
		_next_narration()
	if subtitle_remaining > 0.0: subtitle_remaining -= remaining

func _restore_narration(stored: Dictionary) -> bool:
	var current = stored.get("narration_current", "")
	var remaining = stored.get("narration_remaining", 0.0)
	var queued = stored.get("narration_queue", [])
	if not current is String or current.is_empty() or current.length() > 2000: return false
	if not (remaining is float or remaining is int) or not is_finite(float(remaining)) or remaining <= 0 or remaining > 15: return false
	if not queued is Array or queued.size() > 128: return false
	for line in queued:
		if not line is Dictionary or not line.get("text") is String or line.text.length() > 2000: return false
		var duration = line.get("seconds", 0)
		if not (duration is float or duration is int) or not is_finite(float(duration)) or duration <= 0 or duration > 15: return false
	ui.subtitle.text = current
	subtitle_remaining = float(remaining)
	narration_queue = queued.duplicate(true)
	return true

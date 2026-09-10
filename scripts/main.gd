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
var subtitle_remaining: float = 0.0
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
	room_sound.stream = load("res://assets/audio/room.wav")
	room_sound.volume_db = -15
	add_child(room_sound)
	sound_sources.append(room_sound)
	room_sound.finished.connect(func(): if is_instance_valid(room_sound): room_sound.play())
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
	_update_audio()

func _update_audio():
	var audible = sound_enabled and mode not in ["title","ending"]
	for source in sound_sources:
		if is_instance_valid(source):
			source.volume_db = -80 if not audible else (-15 if source == room_sound else -13)
	if not audible:
		return
	if not room_sound.playing: room_sound.play()
	if story.phase == "drain" and not pipe_sound.playing: pipe_sound.play()
	elif story.phase != "drain": pipe_sound.stop()
	if story.phase in ["pulse","escape"] and not pulse_sound.playing: pulse_sound.play()
	elif story.phase not in ["pulse","escape"]: pulse_sound.stop()

func _on_footstep(point: Vector3):
	if sound_enabled and mode == "play":
		step_sound.global_position = point + Vector3(0, 0.2, 0)
		step_sound.pitch_scale = 0.94 + randf() * 0.1
		step_sound.play()

func _process(delta):
	if not is_instance_valid(ui): return
	if world.has_method("animate"):
		world.animate(delta)
	if subtitle_remaining > 0 and mode == "play":
		subtitle_remaining -= delta
		if subtitle_remaining <= 0:
			ui.subtitle.text = ""
			if not pending_action.is_empty():
				pending_action = ""
				_save()
	if mode != "play":
		ui.set_target("")
		return
	_update_hud()
	active_target = ""
	var hit = player.interaction_hit()
	if not hit.is_empty() and hit.collider.has_meta("interact_id"):
		active_target = str(hit.collider.get_meta("interact_id"))
		ui.set_target(str(hit.collider.get_meta("label", active_target)))
		if active_target == "curtain" and story.phase == "dusk":
			ui.set_target("암막 커튼 · [Q] 틈으로 바깥을 본다")
	else: ui.set_target("")
	if is_instance_valid(held_mug):
		active_target = "mug"
		ui.set_target("컵 내려놓기 · Esc")
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
	await get_tree().create_timer(0.4).timeout
	if not is_inside_tree(): return
	extra_step_pending = false
	if mode == "play" and story.phase == "return" and not extra_step_done:
		extra_step_done = true
		_on_footstep(player.global_position + player.global_basis.z * 1.1)
		_say("멈췄는데, 한 걸음이 더 들렸다.", 5.0)

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
		elif event.physical_keycode == KEY_Q and mode == "play" and active_target == "curtain" and story.phase == "dusk" and not is_instance_valid(held_mug):
			_on_action("look")
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
	if dialog_return_mode == "title":
		ui.show_title(saved_available)
		_apply_mode("title")
		return
	if story.phase == "ending":
		_show_ending()
		return
	if mode == "dialog" and not pending_action.is_empty():
		pending_action = ""
		_save()
	ui.show_game()
	_apply_mode("play")

func _show_page(page: Dictionary, tag: String = "1504호 / 관찰"):
	dialog_return_mode = "title" if mode == "title" else "play"
	ui.show_page(page, tag)
	_apply_mode("dialog")

func _interact(id: String):
	if is_instance_valid(held_mug):
		_on_action("mug")
		return
	if id.is_empty(): return
	if id in ["sink", "wallpad", "tile"]:
		if id == "sink" and story.phase == "drain":
			_on_action("cover")
		elif id == "wallpad" and story.phase == "signal":
			_on_action("off")
		elif id == "tile" and story.phase == "pulse":
			_on_action("count")
		else:
			_say(Content.inspect(id, story.snapshot()).get("body", ""), 14.0)
		return
	if id == "curtain":
		if story.phase == "dusk":
			_on_action("seal")
		elif not world.curtains_closing():
			_say(Content.inspect(id, story.snapshot()).get("body", ""), 14.0)
		return
	if id == "mug":
		_inspect_mug()
		return
	if id in ["mark","photo","notice"]:
		story.apply_action(id)
		_save()
		var contents = Content.inspect(id, story.snapshot())
		if id in ["mark","photo"]:
			_say(contents.get("body", ""), 14.0)
			_update_hud()
		else:
			_show_page(contents)
		return
	if id in ["worn","new"]:
		var name = "닳은 열쇠" if id == "worn" else "새 열쇠"
		var body = "엄지가 오래 닳은 자리에 들어간다. 오른쪽 접시에 놓던 열쇠다." if id == "worn" else "흠집 하나 없이 반듯하다. 출입문 안내에는 이 열쇠를 쓰라고 되어 있다."
		_show_page({"title":name,"body":body,"choices":[{"text":name+"를 쥔다","action":id},{"text":"다시 살펴본다","action":""}]}, "1층 / 출입 확인")
		return
	_show_page(Content.inspect(id, story.snapshot()))

func _inspect_mug():
	held_mug = world.create_mug_preview()
	held_mug.name = "HeldMug"
	player.camera.add_child(held_mug)
	held_mug.position = Vector3(0.22, -0.32, -0.55)
	world.set_mug_held(true)
	ui.show_game()
	_apply_mode("play")
	_say(Content.inspect("mug", story.snapshot()).get("body", "") + "\n[E / Esc] 컵을 내려놓는다.", 14.0)

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
	var changed = story.apply_action(action)
	if not changed:
		_return_to_game()
		return
	if old_phase != story.phase and story.phase in ["landing","threshold","ending"]:
		_create_world()
	else:
		world.apply_story(story.phase, story.exposure, action in ["seal", "look"])
	var page = Content.outcome(action, story.snapshot())
	pending_action = action if story.phase != "ending" and not (action == "mug" and old_phase == "home") and not page.get("body", "").is_empty() else ""
	if action in ["seal", "look", "cover", "off", "count"]: pending_action = ""
	_save()
	_update_hud()
	_update_audio()
	if story.phase == "ending":
		_show_ending()
		return
	if action in ["wash", "seal", "look", "cover", "off", "count"]:
		ui.show_game()
		_apply_mode("play")
		_say(page.get("body", ""), 14.0)
		return
	if action == "mug" and old_phase == "home":
		_say("손잡이를 오른쪽으로 두면, 빠진 자리는 왼쪽.", 5.0)
		_return_to_game()
		return
	if page.get("body", "").is_empty():
		_return_to_game()
	else:
		_show_page(page)

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
	story = State.new()
	pending_action = ""
	extra_step_done = false
	_create_world()
	_save()
	ui.show_game()
	_apply_mode("play")
	_say("야근을 마치고 돌아왔다. 보리차 냄새가 났다.\n열쇠는 신발장 오른쪽 접시에 놓았다. 손을 씻기 전에 집 안을 잠깐 둘러보기로 했다.", 14.0)

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
	subtitle_remaining = 0.0
	ui.subtitle.text = ""
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
	elif not pending_action.is_empty():
		ui.show_game()
		_say(Content.outcome(pending_action, story.snapshot()).get("body", ""), 14.0)
	else: _return_to_game()
	return true

func _capture_save() -> Dictionary:
	var point = player.position
	return {"story":story.snapshot(),"position":[point.x,point.y,point.z],"yaw":player.rotation.y,"pitch":player.pitch,"pending_action":pending_action}

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

func _say(text: String, seconds: float = 4):
	if not ui: return
	ui.subtitle.text = text
	subtitle_remaining = seconds

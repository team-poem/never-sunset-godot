extends CanvasLayer

signal action_requested(action: String)
signal command_requested(command: String)
signal settings_changed(sound: bool, motion: bool, sensitivity: float)

var root: Control
var hud: Control
var title_layer: Control
var modal: PanelContainer
var modal_title: Label
var modal_body: RichTextLabel
var modal_choices: VBoxContainer
var modal_tag: Label
var chapter: Label
var room: Label
var clock_label: Label
var objective_label: Label
var target_label: Label
var subtitle: Label
var crosshair: Label
var resume_button: Button
var preview_container: SubViewportContainer
var preview: SubViewport
var preview_root: Node3D
var preview_camera: Camera3D
var preview_object: Node3D
var preview_rotation: float = 0.0
var is_inspecting: bool = false
var sound_enabled: bool = true
var motion_enabled: bool = true
var look_sensitivity: float = 0.0023

func _ready():
	layer = 10
	var theme = Theme.new()
	var readable_font = FontVariation.new()
	readable_font.base_font = load("res://assets/korean.ttf")
	readable_font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 450.0}
	theme.default_font = readable_font
	theme.default_font_size = 18
	theme.set_color("font_shadow_color", "Label", Color(0.02, 0.03, 0.02, 0.9))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_constant("shadow_outline_size", "Label", 0)
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color("#273328")
	button_style.border_color = Color("#777b5c")
	button_style.set_border_width_all(1)
	button_style.content_margin_left = 18
	button_style.content_margin_right = 18
	button_style.content_margin_top = 12
	button_style.content_margin_bottom = 12
	theme.set_stylebox("normal", "Button", button_style)
	var hover = button_style.duplicate()
	hover.bg_color = Color("#3c4837")
	hover.border_color = Color("#c6b98b")
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("focus", "Button", hover)
	var pressed = button_style.duplicate()
	pressed.bg_color = Color("#566047")
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_color("font_color", "Button", Color("#ece4cb"))
	theme.set_color("default_color", "RichTextLabel", Color("#d4d8c5"))
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.theme = theme
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_hud()
	_build_title()
	_build_modal()

func label(text: String, font_size: int, color: Color = Color("#e4dfc9")) -> Label:
	var node = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	return node

func button(text: String, callback: Callable) -> Button:
	var node = Button.new()
	node.text = text
	node.alignment = HORIZONTAL_ALIGNMENT_LEFT
	node.pressed.connect(callback)
	return node

func _build_hud():
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var left = VBoxContainer.new()
	left.position = Vector2(38, 28)
	left.size = Vector2(370, 180)
	hud.add_child(left)
	chapter = label("104동 / 1504호", 12, Color("#c1b58f"))
	left.add_child(chapter)
	room = label("현관", 27)
	left.add_child(room)
	var gap = Control.new()
	gap.custom_minimum_size.y = 15
	left.add_child(gap)
	objective_label = label("", 15, Color("#bbc5b0"))
	objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_label.custom_minimum_size.x = 325
	left.add_child(objective_label)
	clock_label = label("20:17", 25)
	clock_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	clock_label.position = Vector2(-150, 30)
	hud.add_child(clock_label)
	var hints = label("WASD 이동   ·   마우스 / 드래그 / 방향키 시선   ·   E 행동 · Q 다른 행동   ·   J 수첩   ·   Esc 설정", 13, Color("#c3ccb7"))
	hints.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	hints.position = Vector2(38, -43)
	hud.add_child(hints)
	target_label = label("", 18, Color("#e5d5a7"))
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	target_label.position = Vector2(-250, 37)
	target_label.size = Vector2(500, 45)
	hud.add_child(target_label)
	crosshair = label("·", 30, Color("#dbd9beaa"))
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-5, -23)
	hud.add_child(crosshair)
	subtitle = label("", 18)
	subtitle.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	subtitle.offset_left = 190
	subtitle.offset_right = -190
	subtitle.offset_top = -113
	subtitle.offset_bottom = -61
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(subtitle)

func _build_title():
	title_layer = Control.new()
	title_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(title_layer)
	var veil = ColorRect.new()
	veil.color = Color(0.025, 0.043, 0.031, 0.76)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_layer.add_child(veil)
	var box = VBoxContainer.new()
	box.position = Vector2(95, 115)
	box.size = Vector2(470, 490)
	box.add_theme_constant_override("separation", 17)
	title_layer.add_child(box)
	box.add_child(label("104동 · 1504호       /       귀가 기록", 13, Color("#c6b689")))
	var heading = label("해가 지지\n않는 동", 60)
	heading.add_theme_constant_override("line_spacing", -3)
	box.add_child(heading)
	box.add_child(label("모든 것이 제자리에 있었다.\n내가 기억하는 흠집만 빼고.", 20, Color("#c1cbb3")))
	box.add_child(button("집에 들어가기    ↗", func(): command_requested.emit("start")))
	resume_button = button("이전 기록 이어서    →", func(): command_requested.emit("resume"))
	box.add_child(resume_button)
	box.add_child(label("1인칭 이야기 탐색 · 약 15분\n이어폰 권장 · 소리 없이도 모든 단서를 확인할 수 있습니다.", 13, Color("#98a68f")))
	var foot = label("밤 8시 이후의 빛은 태양광이 아닙니다.", 14, Color("#b3b99d"))
	foot.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	foot.position = Vector2(95, -48)
	title_layer.add_child(foot)

func _build_modal():
	modal = PanelContainer.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	modal.position = Vector2(-350, -284)
	modal.size = Vector2(700, 568)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.085, 0.12, 0.085, 0.98)
	style.border_color = Color("#687155")
	style.set_border_width_all(1)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 26
	style.content_margin_bottom = 25
	modal.add_theme_stylebox_override("panel", style)
	root.add_child(modal)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	modal.add_child(box)
	modal_tag = label("104 / 기록", 12, Color("#b8ad83"))
	box.add_child(modal_tag)
	modal_title = label("", 29)
	modal_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(modal_title)
	preview_container = SubViewportContainer.new()
	preview_container.custom_minimum_size = Vector2(0, 220)
	preview_container.stretch = true
	preview_container.gui_input.connect(_preview_input)
	box.add_child(preview_container)
	preview = SubViewport.new()
	preview.size = Vector2i(640, 220)
	preview.own_world_3d = true
	preview.transparent_bg = true
	preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview_container.add_child(preview)
	preview_root = Node3D.new()
	preview.add_child(preview_root)
	preview_camera = Camera3D.new()
	preview_root.add_child(preview_camera)
	preview_camera.position = Vector3(0, 0.22, 0.7)
	preview_camera.look_at(Vector3(0, 0.11, 0))
	preview_camera.fov = 38
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-32, -25, 0)
	light.light_energy = 1.3
	preview_root.add_child(light)
	var environment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("#121d14")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("#b4bca2")
	environment.environment.ambient_light_energy = 0.6
	preview_root.add_child(environment)
	modal_body = RichTextLabel.new()
	modal_body.bbcode_enabled = false
	modal_body.scroll_active = true
	modal_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_body.custom_minimum_size.y = 110
	modal_body.add_theme_font_size_override("normal_font_size", 18)
	modal_body.add_theme_constant_override("normal_font_spacing", 1)
	box.add_child(modal_body)
	modal_choices = VBoxContainer.new()
	modal_choices.add_theme_constant_override("separation", 8)
	box.add_child(modal_choices)
	modal.hide()

func _preview_input(event):
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		preview_rotation += event.relative.x * 0.013
		if preview_object:
			preview_object.rotation.y = preview_rotation

func _process(delta):
	if is_inspecting and preview_object:
		if Input.is_physical_key_pressed(KEY_LEFT): preview_rotation -= delta * 1.5
		if Input.is_physical_key_pressed(KEY_RIGHT): preview_rotation += delta * 1.5
		preview_object.rotation.y = preview_rotation

func _clear_choices():
	for child in modal_choices.get_children():
		modal_choices.remove_child(child)
		child.queue_free()

func show_title(can_resume: bool):
	title_layer.show()
	hud.hide()
	modal.hide()
	preview_container.hide()
	is_inspecting = false
	resume_button.visible = can_resume

func show_game():
	title_layer.hide()
	modal.hide()
	preview_container.hide()
	is_inspecting = false
	hud.show()

func show_page(page: Dictionary, tag: String = "1504호 / 관찰"):
	title_layer.hide()
	modal.show()
	modal_tag.text = tag
	modal_title.text = page.get("title", "")
	modal_body.text = page.get("body", "")
	modal_body.scroll_to_line(0)
	preview_container.hide()
	is_inspecting = false
	_clear_choices()
	for choice in page.get("choices", [{"text":"계속", "action":""}]):
		var action = str(choice.get("action", ""))
		var node = button(str(choice.get("text", "계속")), func(): action_requested.emit(action))
		modal_choices.add_child(node)
	if modal_choices.get_child_count() > 0:
		modal_choices.get_child(0).grab_focus()

func show_inspection(page: Dictionary, model: Node3D):
	show_page(page, "사물 관찰 / 드래그 또는 ← → 로 돌려보기")
	is_inspecting = true
	preview_container.show()
	preview_rotation = 0.0
	if preview_object:
		preview_root.remove_child(preview_object)
		preview_object.queue_free()
	preview_object = model
	if model:
		preview_root.add_child(model)
		model.position = Vector3.ZERO
		model.rotation = Vector3.ZERO

func show_settings():
	show_page({"title":"잠시 멈추기", "body":"시간은 행동할 때만 흐릅니다.\n\nWASD 이동 · 마우스 또는 방향키 시선\nE / 왼쪽 클릭 행동 · Q 다른 행동 · R 컵 회전 · J 수첩 · F 전체 화면\n\n아래 설정은 저장됩니다.", "choices":[]}, "104 / 환경 설정")
	var sound = CheckButton.new()
	sound.text = "환경음"
	sound.button_pressed = sound_enabled
	sound.toggled.connect(func(value): sound_enabled = value; settings_changed.emit(sound_enabled, motion_enabled, look_sensitivity))
	modal_choices.add_child(sound)
	var motion = CheckButton.new()
	motion.text = "시점의 작은 흔들림"
	motion.button_pressed = motion_enabled
	motion.toggled.connect(func(value): motion_enabled = value; settings_changed.emit(sound_enabled, motion_enabled, look_sensitivity))
	modal_choices.add_child(motion)
	modal_choices.add_child(button("계속하기", func(): action_requested.emit("")))
	modal_choices.add_child(button("기록을 저장하고 처음 화면으로", func(): command_requested.emit("title")))

func set_hud(phase: String, location: String, objective: String, time: String):
	chapter.text = "104동 / " + ("귀가" if phase == "home" else "야간 기록")
	room.text = location
	objective_label.text = objective
	clock_label.text = time

func set_target(name: String):
	target_label.text = "[ E ]  " + name if not name.is_empty() else ""
	crosshair.modulate = Color("#f1dda6") if not name.is_empty() else Color("#aeb7a0")

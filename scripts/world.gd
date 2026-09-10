extends Node3D
## Original procedural apartment. All measurements are in metres.
## Interaction metadata belongs to actual physical prop bodies, never room volumes.

var targets: Dictionary = {}
var _materials: Dictionary = {}
var _mode: String = "apartment"
var _phase: String = "home"
var _elapsed: float = 0.0
var _cup: Node3D
var _bandage: Node3D
var _curtains: Array[Node3D] = []
var _reverse_shadows: Node3D
var _sink_pot: Node3D
var _wallpad_screen: Node3D
var _wallpad_map: Node3D
var _tile_trace: Node3D
var _sunlight: DirectionalLight3D
var _window_light: OmniLight3D
var _archive_door: Node3D
var _floor_noise: NoiseTexture2D

func build_apartment() -> void:
	_mode = "apartment"
	_palette()
	_environment(false)
	_architecture()
	_living_room()
	_kitchen()
	_bathroom()
	_entrance()
	_outside_window()
	apply_story("home", 0)

func build_landing() -> void:
	_mode = "landing"
	_palette()
	_environment(false)
	_box("LandingFloor", Vector3(0, -0.12, 0), Vector3(7.6, 0.24, 13.0), "stone", true)
	_box("Ceiling", Vector3(0, 2.9, 0), Vector3(7.6, 0.2, 13.0), "plaster")
	_wall(Vector3(-3.8, 1.4, 0), Vector3(0.2, 2.8, 13.0), "plaster")
	_wall(Vector3(3.8, 1.4, 0), Vector3(0.2, 2.8, 13.0), "plaster")
	_wall(Vector3(0, 1.4, 6.5), Vector3(7.6, 2.8, 0.2), "plaster")
	_wall(Vector3(-2.35, 1.4, -6.5), Vector3(2.9, 2.8, 0.2), "plaster")
	_wall(Vector3(2.35, 1.4, -6.5), Vector3(2.9, 2.8, 0.2), "plaster")
	_wall(Vector3(0, 2.52, -6.5), Vector3(1.8, 0.56, 0.2), "plaster")
	for i in range(13):
		_box("TerrazzoSeam", Vector3(0, 0.006, float(i) - 6.0), Vector3(7.3, 0.012, 0.014), "grout")
	for side in [-1.0, 1.0]:
		_box("PaintedSkirting", Vector3(float(side) * 3.66, 0.48, 0), Vector3(0.03, 0.86, 12.7), "green")
		_box("Handrail", Vector3(float(side) * 3.61, 0.96, 0), Vector3(0.055, 0.055, 12.7), "brass")
	for z in [3.5, -2.5]:
		_ceiling_lamp(Vector3(0, 2.78, float(z)), 1.1, 5.8)
	# Familiar apartment door behind the player, rendered into the same corridor wall.
	_box("Apartment104Door", Vector3(0, 1.08, 6.32), Vector3(1.05, 2.16, 0.12), "door", true)
	_box("ApartmentPlaque", Vector3(0, 1.79, 6.245), Vector3(0.37, 0.12, 0.018), "brass")
	_label("1504", Vector3(0, 1.795, 6.226), 0.0048, Color("e5dbc0"), PI)
	# Archive nook: a door left ajar, with an accessible desk facing the main corridor.
	_wall(Vector3(-2.3, 1.4, -2.3), Vector3(2.8, 2.8, 0.16), "plaster")
	_box("ArchiveDoorFrame", Vector3(-0.86, 1.18, -2.3), Vector3(0.09, 2.36, 0.24), "wood_dark", true)
	_archive_door = Node3D.new()
	_archive_door.name = "ArchiveDoorAjar"
	_archive_door.position = Vector3(-0.9, 0, -2.3)
	_archive_door.rotation.y = deg_to_rad(-65.0)
	add_child(_archive_door)
	_box("ArchiveDoor", Vector3(-0.52, 1.1, 0), Vector3(1.04, 2.2, 0.075), "door", true, _archive_door)
	_table(Vector3(-2.35, 0, -4.8), Vector3(1.8, 0.78, 0.8), "wood_dark")
	for i in range(5):
		_box("ArchivePaperStack", Vector3(-2.75 + float(i) * 0.25, 0.82, -4.93), Vector3(0.2, 0.06 + float(i % 2) * 0.03, 0.31), "paper")
	var report: StaticBody3D = _target("archive", "비공개 감리 일지", Vector3(-2.25, 0.845, -4.59), Vector3(0.66, 0.07, 0.47))
	_box("ReportCover", Vector3.ZERO, Vector3(0.64, 0.035, 0.45), "file", false, report)
	_box("ReportLabel", Vector3(0, 0.02, 0), Vector3(0.4, 0.008, 0.24), "paper", false, report)
	for i in range(4):
		_box("TypewrittenLine", Vector3(-0.02, 0.025, -0.06 + float(i) * 0.04), Vector3(0.25 - float(i % 2) * 0.06, 0.005, 0.007), "ink", false, report)
	_desk_lamp(Vector3(-1.72, 0.82, -4.9))
	# Main threshold, alternate elevator and stairs all have their own physical target.
	var exit_body: StaticBody3D = _target("exit", "비상구", Vector3(0, 1.1, -6.42), Vector3(1.65, 2.2, 0.12))
	_box("EmergencyDoor", Vector3.ZERO, Vector3(1.64, 2.2, 0.11), "exit", false, exit_body)
	_box("PanicBar", Vector3(0, -0.06, 0.09), Vector3(1.15, 0.075, 0.09), "metal", false, exit_body)
	_box("DoorWindow", Vector3(0, 0.51, 0.068), Vector3(0.8, 0.49, 0.025), "dawn", false, exit_body)
	_exit_sign(Vector3(0, 2.54, -6.29))
	var lift: StaticBody3D = _target("elevator", "엘리베이터", Vector3(3.64, 1.16, 0.0), Vector3(0.13, 2.32, 1.7))
	_box("ElevatorSteel", Vector3.ZERO, Vector3(0.12, 2.32, 1.68), "steel", false, lift)
	_box("ElevatorCenterSeam", Vector3(-0.065, 0, 0), Vector3(0.009, 2.3, 0.018), "ink", false, lift)
	_box("ElevatorDisplay", Vector3(3.54, 2.44, 0), Vector3(0.05, 0.17, 0.35), "ink")
	_box("ElevatorAmberNumber", Vector3(3.506, 2.44, 0), Vector3(0.01, 0.075, 0.12), "amber")
	var stairs: StaticBody3D = _target("stairs", "계단실 문", Vector3(-3.64, 1.12, 2.0), Vector3(0.13, 2.24, 1.3))
	_box("StairsDoor", Vector3.ZERO, Vector3(0.12, 2.24, 1.29), "green", false, stairs)
	_box("StairsHandle", Vector3(0.095, -0.05, -0.43), Vector3(0.06, 0.23, 0.04), "metal", false, stairs)
	# Empty shoes outside a neighbouring door suggest occupancy without another person.
	_box("NeighbourDoor", Vector3(-3.65, 1.09, 4.6), Vector3(0.12, 2.18, 1.1), "door", true)
	_shoe_pair(Vector3(-3.05, 0.06, 4.48), -PI / 2.0)

func build_dawn() -> void:
	_mode = "dawn"
	_palette()
	_environment(true)
	_box("Courtyard", Vector3(0, -0.13, -7), Vector3(40, 0.26, 45), "stone", true)
	for i in range(17):
		_box("PathSeam", Vector3(0, 0.005, float(i) * -1.5 + 4.0), Vector3(15, 0.01, 0.015), "grout")
	for x in [-10.0, 10.0]:
		_box("Planter", Vector3(float(x), 0.25, -8), Vector3(7, 0.5, 22), "concrete", true)
		_box("Soil", Vector3(float(x), 0.515, -8), Vector3(6.7, 0.035, 21.7), "soil")
		for z in [-1.0, -8.0, -15.0]:
			_tree(Vector3(float(x), 0.5, float(z)), 1.25)
	_box("BenchSeat", Vector3(-4.0, 0.45, -3), Vector3(2.2, 0.13, 0.52), "wood", true)
	_box("BenchBack", Vector3(-4.0, 0.8, -3.22), Vector3(2.2, 0.58, 0.08), "wood", true)
	for x in [-4.85, -3.15]:
		_box("BenchLeg", Vector3(float(x), 0.22, -3), Vector3(0.09, 0.44, 0.4), "metal")
	for x in [-19.0, 16.0]:
		_tower(Vector3(float(x), 0, -24), Vector3(8, 27, 7), "concrete", false)
	# Distant 104 remains intact. A fine horizontal red line survives the dawn.
	_tower(Vector3(0, 0, -35), Vector3(10, 34, 8), "concrete", false)
	_box("SinglePersistentWindow", Vector3(1.6, 25.4, -30.96), Vector3(2.7, 0.12, 0.018), "red_glow")
	_label("104", Vector3(0, 30.5, -30.9), 0.07, Color("67766d"))
	_sunlight.light_color = Color("efd2ad")
	_sunlight.light_energy = 1.1
	_sunlight.rotation_degrees = Vector3(-24, -30, 0)

func build_threshold() -> void:
	_mode = "threshold"
	_palette()
	_environment(true)
	_box("VestibuleFloor", Vector3(0, -0.12, 0), Vector3(8, 0.24, 12), "stone", true)
	_box("VestibuleCeiling", Vector3(0, 3.1, 0), Vector3(8, 0.2, 12), "plaster")
	_wall(Vector3(-4, 1.5, 0), Vector3(0.2, 3, 12), "green")
	_wall(Vector3(4, 1.5, 0), Vector3(0.2, 3, 12), "green")
	_wall(Vector3(0, 1.5, 6), Vector3(8, 3, 0.2), "plaster")
	for x in [-3.8, -1.1, 1.1, 3.8]:
		_box("VestibuleGlazingMullion", Vector3(float(x), 1.5, -4.6), Vector3(0.08, 3, 0.10), "metal")
	_box("VestibuleGlazingHeader", Vector3(0, 2.9, -4.6), Vector3(7.8, 0.12, 0.1), "metal")
	_solid("ClosedGlassExit", Vector3(0, 1.4, -4.6), Vector3(8, 2.8, 0.05))
	_box("ExitGlassHandle", Vector3(0.14, 1.2, -4.48), Vector3(0.055, 0.69, 0.05), "steel")
	_box("ExitDoorSeam", Vector3(0, 1.44, -4.6), Vector3(0.035, 2.88, 0.05), "metal")
	_box("OutsidePaving", Vector3(0, -0.1, -15), Vector3(25, 0.2, 25), "concrete")
	_tree(Vector3(-5.5, 0, -10), 1.0)
	_tree(Vector3(5.3, 0, -11.7), 1.2)
	_tower(Vector3(-10, 0, -24), Vector3(6, 23, 6), "concrete", false)
	_tower(Vector3(12, 0, -29), Vector3(7, 27, 6), "concrete", false)
	_table(Vector3(0, 0, -0.55), Vector3(1.65, 0.86, 0.76), "wood")
	_sphere("KeyDish", Vector3(0, 0.918, -0.51), Vector3(0.66, 0.029, 0.29), "ceramic")
	for id in ["new", "worn"]:
		var x: float = -0.35 if id == "new" else 0.35
		var key: StaticBody3D = _target(id, "새 열쇠" if id == "new" else "닳은 열쇠", Vector3(x, 0.957, -0.49), Vector3(0.22, 0.045, 0.16))
		var metal: String = "brass" if id == "new" else "wood_dark"
		var ring: TorusMesh = TorusMesh.new()
		ring.inner_radius = 0.035
		ring.outer_radius = 0.053
		ring.rings = 16
		ring.ring_segments = 8
		var ring_visual: MeshInstance3D = MeshInstance3D.new()
		ring_visual.mesh = ring
		ring_visual.material_override = _materials[metal]
		ring_visual.position = Vector3(-0.058, 0, 0)
		key.add_child(ring_visual)
		_box("KeyShaft", Vector3(0.032, 0, 0), Vector3(0.13, 0.015, 0.025), metal, false, key)
		for i in range(3):
			_box("KeyTooth", Vector3(0.036 + float(i) * 0.025, 0, 0.02), Vector3(0.013, 0.015, 0.036 - float(i % 2) * 0.015), metal, false, key)
		if id == "worn":
			_box("RememberedKeyScratch", Vector3(-0.064, 0.014, 0.041), Vector3(0.028, 0.008, 0.008), "paper", false, key)
	_ceiling_lamp(Vector3(0, 2.98, -0.55), 0.8, 5.0)
	_exit_sign(Vector3(0, 2.65, -4.48))
	_sunlight.light_color = Color("efd2ad")
	_sunlight.light_energy = 0.8
	_sunlight.rotation_degrees = Vector3(-24, -30, 0)

func create_mug_preview() -> Node3D:
	if not is_instance_valid(_cup):
		return Node3D.new()
	var preview: Node3D = _cup.duplicate() as Node3D
	preview.position = Vector3.ZERO
	preview.rotation = Vector3.ZERO
	return preview

func get_spawn() -> Vector3:
	if _mode == "landing":
		return Vector3(0, 0.05, 4.5)
	if _mode == "dawn":
		return Vector3(0, 0.05, 4.0)
	return Vector3(0, 0.05, 4.5)

func room_at(point: Vector3) -> String:
	if _mode == "threshold":
		return "공동현관 · 두 개의 열쇠"
	if _mode == "landing":
		return "관리사무소 자료실" if point.x < -0.8 and point.z < -2.3 else "104동 · 공동 복도"
	if _mode == "dawn":
		return "단지 앞 · 새벽"
	if point.x > 1.35 and point.z > 0.75:
		return "욕실"
	if point.x > 1.2 and point.z < -1.0:
		return "주방"
	if point.z > 1.5:
		return "현관"
	return "거실"

func apply_story(phase: String, exposure: int) -> void:
	_phase = phase
	if _mode != "apartment":
		return
	var late: bool = phase in ["signal", "pulse", "escape"]
	var sunset: bool = phase in ["dusk", "drain", "signal", "pulse", "escape"]
	_make_mug(-1 if phase == "home" else (1 if late else 0))
	if is_instance_valid(_bandage):
		_bandage.position.x = 0.115 if late else -0.115
	for i in range(_curtains.size()):
		_curtains[i].position.x = -3.51 if i == 0 else -1.49
		_curtains[i].scale.x = 1.0 if sunset else 0.27
		if not sunset:
			_curtains[i].position.x = -4.65 if i == 0 else -0.35
	_reverse_shadows.visible = sunset
	_sink_pot.visible = phase in ["drain", "signal", "pulse", "escape"]
	_wallpad_map.visible = phase in ["signal", "pulse", "escape"]
	_tile_trace.visible = phase in ["pulse", "escape"]
	_window_light.light_color = Color("db593b") if sunset else Color("d8b37c")
	_window_light.light_energy = 0.8 + minf(float(exposure) * 0.07, 0.35) if sunset else 0.55
	_sunlight.light_color = Color("df7351") if sunset else Color("aab8ac")
	_sunlight.light_energy = 0.17 if sunset else 0.28

func animate(delta: float) -> void:
	_elapsed += delta
	if _mode == "apartment" and is_instance_valid(_tile_trace) and _tile_trace.visible:
		# A slow change in grout alignment, without camera motion or flashes.
		_tile_trace.position.z = 5.675 + sin(_elapsed * 0.36) * 0.006
	if _mode == "apartment" and is_instance_valid(_sink_pot) and _sink_pot.visible:
		_sink_pot.rotation.z = sin(_elapsed * 0.48) * 0.006

func _palette() -> void:
	var colors: Dictionary = {
		"plaster": "b7b5a3", "green": "657c70", "green_dark": "41574e",
		"wood": "97724c", "wood_dark": "493e30", "trim": "d4c7aa",
		"floor_a": "94734e", "floor_b": "a27d52", "floor_c": "896947",
		"sofa": "787764", "sofa_dark": "5c6459", "fabric": "ad9b7b",
		"curtain": "6f7665", "paper": "d8cfb6", "ink": "282f2a",
		"ceramic": "d0cbb8", "tile": "a5b5ab", "tile_dark": "7e9289",
		"grout": "646f65", "stone": "929b8f", "concrete": "89988e",
		"metal": "3a423d", "steel": "84918a", "brass": "a5905e",
		"door": "55443a", "file": "596c5c", "exit": "4d6c5d",
		"plant": "4b6550", "plant_light": "708367", "soil": "3d4032",
		"cup": "b9c5b5", "chip": "665643", "coffee": "302a21",
		"photo_bg": "929b82", "skin": "c5ad88", "hair": "41483b",
		"shirt": "7d8e84", "red": "843c30", "sky": "75877b"
	}
	for key in colors:
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color(String(colors[key]))
		material.roughness = 0.86
		_materials[key] = material
	_materials["steel"].metallic = 0.55
	_materials["steel"].roughness = 0.35
	_materials["brass"].metallic = 0.45
	_materials["ceramic"].roughness = 0.3
	_materials["cup"].roughness = 0.28
	# Small original seamless grain, shared by all boards. No external texture file.
	var noise: FastNoiseLite = FastNoiseLite.new()
	noise.seed = 104
	noise.frequency = 0.075
	noise.fractal_octaves = 3
	_floor_noise = NoiseTexture2D.new()
	_floor_noise.width = 128
	_floor_noise.height = 128
	_floor_noise.seamless = true
	_floor_noise.noise = noise
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(0.62, 0.56, 0.47))
	ramp.set_color(1, Color(1, 0.94, 0.83))
	_floor_noise.color_ramp = ramp
	for key in ["wood", "floor_a", "floor_b", "floor_c"]:
		_materials[key].albedo_texture = _floor_noise
		_materials[key].uv1_scale = Vector3(1.0, 9.0, 1.0)
	_emissive("warm", Color("ffe1a5"), 1.5)
	_emissive("amber", Color("bd7b45"), 0.75)
	_emissive("red_glow", Color("bf4f39"), 0.6)
	_emissive("dawn", Color("c4d2c2"), 0.65)
	_emissive("screen", Color("5c776b"), 0.4)
	_emissive("screen_line", Color("b1c3ad"), 0.6)
	_emissive("exit_glow", Color("75ab81"), 0.8)
	var shadow: StandardMaterial3D = StandardMaterial3D.new()
	shadow.albedo_color = Color(0.10, 0.12, 0.09, 0.64)
	shadow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_materials["shadow"] = shadow

func _emissive(key: String, color: Color, energy: float) -> void:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	_materials[key] = material

func _environment(dawn: bool) -> void:
	var environment: WorldEnvironment = WorldEnvironment.new()
	var settings: Environment = Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("a6b5aa") if dawn else Color("283c35")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("bcc8b5") if dawn else Color("a0b0a0")
	settings.ambient_light_energy = 0.6 if dawn else 0.42
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	add_child(environment)
	_sunlight = DirectionalLight3D.new()
	_sunlight.rotation_degrees = Vector3(-32, -18, 0)
	_sunlight.light_color = Color("c5b690")
	_sunlight.light_energy = 0.28
	_sunlight.shadow_enabled = true
	_sunlight.directional_shadow_max_distance = 26.0
	add_child(_sunlight)

func _architecture() -> void:
	_box("StructuralFloor", Vector3(0, -0.15, 0), Vector3(12, 0.3, 12), "wood_dark", true)
	# A staggered parquet board layout gives scale and familiar wear underfoot.
	for row in range(32):
		var z: float = -5.82 + float(row) * 0.37
		for col in range(9):
			var x: float = -5.7 + float(col) * 1.4 + (0.7 if row % 2 == 1 else 0.0)
			if x > 5.9 or (x > 1.2 and z > 0.8):
				continue
			var width: float = minf(1.39, 6.0 - x + 0.69)
			_box("Floorboard", Vector3(x, 0.008, z), Vector3(width, 0.016, 0.362), ["floor_a", "floor_b", "floor_c"][(row * 7 + col * 3 + row % 3) % 3])
	_wall(Vector3(-6, 1.4, 0), Vector3(0.2, 2.8, 12), "green")
	_wall(Vector3(6, 1.4, 0), Vector3(0.2, 2.8, 12), "plaster")
	_wall(Vector3(0, 1.4, 6), Vector3(12, 2.8, 0.2), "plaster")
	_wall(Vector3(3.0, 1.4, -6), Vector3(6, 2.8, 0.2), "plaster")
	# North-facing balcony glazing is framed by real masonry, never a painted door.
	_wall(Vector3(-5.57, 1.4, -6), Vector3(0.86, 2.8, 0.2), "green")
	_wall(Vector3(-0.23, 1.4, -6), Vector3(0.46, 2.8, 0.2), "green")
	_wall(Vector3(-2.7, 0.31, -6), Vector3(4.9, 0.62, 0.2), "green")
	_wall(Vector3(-2.7, 2.6, -6), Vector3(4.9, 0.4, 0.2), "green")
	_box("Ceiling", Vector3(0, 2.9, 0), Vector3(12, 0.2, 12), "plaster")
	# Front hall with shoe-storage/closed bedroom mass to its west.
	_wall(Vector3(-1.3, 1.4, 3.85), Vector3(0.18, 2.8, 4.3), "green")
	_wall(Vector3(-3.65, 1.4, 1.65), Vector3(4.7, 2.8, 0.18), "green")
	_box("BedroomDoor", Vector3(-1.185, 1.08, 3.05), Vector3(0.04, 2.16, 0.95), "door")
	_box("BedroomHandle", Vector3(-1.13, 1.01, 2.71), Vector3(0.09, 0.035, 0.18), "brass")
	# Kitchen partition and two independent wide entrances.
	_wall(Vector3(1.2, 1.4, -4.94), Vector3(0.16, 2.8, 1.92), "plaster")
	_wall(Vector3(1.2, 1.4, -1.76), Vector3(0.16, 2.8, 1.48), "plaster")
	_wall(Vector3(1.2, 2.53, -3.3), Vector3(0.16, 0.54, 1.4), "plaster")
	_wall(Vector3(1.87, 1.4, -1), Vector3(1.5, 2.8, 0.16), "plaster")
	_wall(Vector3(5.06, 1.4, -1), Vector3(1.72, 2.8, 0.16), "plaster")
	_wall(Vector3(3.41, 2.53, -1), Vector3(1.58, 0.54, 0.16), "plaster")
	# Bathroom opening x=1.4, z=2.0..3.3: 1.3 m clear.
	_wall(Vector3(1.4, 1.4, 1.38), Vector3(0.16, 2.8, 1.24), "plaster")
	_wall(Vector3(1.4, 1.4, 4.6), Vector3(0.16, 2.8, 2.6), "plaster")
	_wall(Vector3(1.4, 2.53, 2.65), Vector3(0.16, 0.54, 1.3), "plaster")
	_wall(Vector3(3.7, 1.4, 0.8), Vector3(4.6, 2.8, 0.16), "plaster")
	_box("BathroomThreshold", Vector3(1.4, 0.025, 2.65), Vector3(0.2, 0.05, 1.29), "stone")
	_ceiling_lamp(Vector3(0, 2.77, 3.2), 0.6, 3.6)
	_ceiling_lamp(Vector3(3.7, 2.77, -3.4), 0.95, 4.6)
	_ceiling_lamp(Vector3(3.7, 2.77, 3.1), 0.85, 4.1)

func _living_room() -> void:
	# Sofa backs against the west wall, leaving the middle of the room walkable.
	_box("Rug", Vector3(-3.5, 0.027, -1.2), Vector3(3.6, 0.02, 3.0), "fabric")
	for i in range(9):
		_box("RugWeave", Vector3(-3.5, 0.039, -2.55 + float(i) * 0.32), Vector3(3.52, 0.004, 0.018), "sofa")
	var sofa: StaticBody3D = _target("sofa", "소파", Vector3(-5.02, 0.4, -1.2), Vector3(1.15, 0.8, 2.7))
	_box("SofaBase", Vector3.ZERO, Vector3(1.05, 0.42, 2.6), "sofa_dark", false, sofa)
	_box("SofaBack", Vector3(-0.39, 0.3, 0), Vector3(0.28, 0.76, 2.6), "sofa", false, sofa)
	for z in [-0.83, 0.0, 0.83]:
		_box("SofaCushion", Vector3(0.04, 0.25, float(z)), Vector3(0.82, 0.2, 0.79), "sofa", false, sofa)
	for z in [-1.24, 1.24]:
		_box("SofaArm", Vector3(0, 0.19, float(z)), Vector3(1.02, 0.6, 0.19), "sofa_dark", false, sofa)
	var pillow: MeshInstance3D = _box("CreasedPillow", Vector3(-4.88, 0.91, -2.02), Vector3(0.36, 0.38, 0.47), "fabric")
	pillow.rotation.z = -0.24
	_table(Vector3(-3.15, 0, -1.2), Vector3(1.35, 0.43, 0.85), "wood")
	_box("Book", Vector3(-3.3, 0.465, -1.34), Vector3(0.32, 0.04, 0.23), "file")
	_box("Remote", Vector3(-2.77, 0.465, -1.06), Vector3(0.065, 0.024, 0.21), "ink")
	for i in range(4):
		_box("RemoteButton", Vector3(-2.77, 0.48, -1.1 + float(i) * 0.03), Vector3(0.035, 0.008, 0.011), "stone")
	# Media unit facing the room, a black screen reflecting nothing.
	_box("MediaCabinet", Vector3(0.44, 0.34, -2.18), Vector3(0.56, 0.68, 2.03), "wood_dark", true)
	_box("Television", Vector3(0.39, 1.18, -2.18), Vector3(0.09, 0.95, 1.72), "ink", true)
	_box("TelevisionGlass", Vector3(0.335, 1.18, -2.18), Vector3(0.008, 0.84, 1.59), "green_dark")
	_box("TelevisionStand", Vector3(0.42, 0.76, -2.18), Vector3(0.32, 0.16, 0.35), "metal")
	# Family photograph: bandage is an actual movable patch on the printed image.
	_box("PhotoSideboard", Vector3(-4.24, 0.51, -4.37), Vector3(2.05, 1.02, 0.61), "wood", true)
	for x in [-4.73, -3.76]:
		_box("SideboardDrawer", Vector3(float(x), 0.65, -4.053), Vector3(0.9, 0.44, 0.018), "wood_dark")
		_box("DrawerPull", Vector3(float(x), 0.65, -4.02), Vector3(0.23, 0.025, 0.03), "brass")
	var photo: StaticBody3D = _target("photo", "가족사진", Vector3(-4.06, 1.32, -4.30), Vector3(0.62, 0.52, 0.08))
	_box("PhotoFrame", Vector3.ZERO, Vector3(0.61, 0.51, 0.075), "wood_dark", false, photo)
	_box("Photograph", Vector3(0, 0, 0.045), Vector3(0.53, 0.43, 0.014), "photo_bg", false, photo)
	for x in [-0.12, 0.12]:
		_sphere("PortraitHead", Vector3(float(x), 0.073, 0.06), Vector3(0.07, 0.09, 0.008), "skin", photo)
		_box("PortraitShoulders", Vector3(float(x), -0.095, 0.059), Vector3(0.19, 0.17, 0.008), "shirt", false, photo)
		_box("PortraitHair", Vector3(float(x), 0.134, 0.064), Vector3(0.127, 0.041, 0.006), "hair", false, photo)
	_bandage = _box("BandageInPhotograph", Vector3(-0.115, -0.1, 0.068), Vector3(0.071, 0.037, 0.009), "paper", false, photo)
	_box("PhotoFrameFoot", Vector3(-4.06, 1.06, -4.30), Vector3(0.51, 0.038, 0.23), "wood_dark")
	_vase(Vector3(-4.96, 1.04, -4.37))
	_floor_lamp(Vector3(-5.25, 0, 0.78))
	_plant(Vector3(-0.4, 0, -5.14), 0.83)
	# Quiet household history: pencil lines, paper clock, a folded throw.
	_box("ThrowOnSofa", Vector3(-4.71, 0.78, -0.46), Vector3(0.6, 0.09, 0.57), "green_dark")
	_cylinder("WallClock", Vector3(-5.865, 1.96, -2.96), 0.22, 0.04, "wood_dark", Vector3(0, 0, PI / 2))
	_cylinder("ClockFace", Vector3(-5.838, 1.96, -2.96), 0.197, 0.012, "paper", Vector3(0, 0, PI / 2))
	_box("ClockMinuteHand", Vector3(-5.824, 2.015, -2.96), Vector3(0.009, 0.12, 0.014), "ink")
	_box("ClockHourHand", Vector3(-5.819, 1.96, -2.913), Vector3(0.009, 0.014, 0.095), "ink")

func _kitchen() -> void:
	# North counter, with recessed sink; table leaves a route on all four sides.
	_box("CounterCabinet", Vector3(3.52, 0.45, -5.39), Vector3(4.53, 0.9, 0.82), "green", true)
	_box("CounterStone", Vector3(3.52, 0.93, -5.39), Vector3(4.59, 0.08, 0.88), "ceramic")
	for i in range(6):
		var x: float = 1.67 + float(i) * 0.74
		_box("CabinetFront", Vector3(x, 0.48, -4.967), Vector3(0.70, 0.76, 0.025), "green_dark")
		_box("CabinetHandle", Vector3(x, 0.75, -4.94), Vector3(0.23, 0.024, 0.035), "brass")
	for i in range(15):
		_box("BacksplashTile", Vector3(1.47 + float(i) * 0.29, 1.24, -5.882), Vector3(0.28, 0.46, 0.025), "tile")
	var sink: StaticBody3D = _target("sink", "싱크대 배수구", Vector3(3.34, 0.994, -5.25), Vector3(0.79, 0.055, 0.58))
	_box("SinkSteelRim", Vector3.ZERO, Vector3(0.77, 0.02, 0.56), "steel", false, sink)
	_box("SinkBasin", Vector3(0, 0.012, 0), Vector3(0.64, 0.012, 0.43), "metal", false, sink)
	_cylinder("Drain", Vector3(0, 0.022, 0.03), 0.063, 0.012, "ink", Vector3.ZERO, sink)
	_cylinder("DrainGrid", Vector3(0, 0.03, 0.03), 0.041, 0.008, "steel", Vector3.ZERO, sink)
	_faucet(Vector3(3.34, 1.02, -5.54), self)
	_sink_pot = Node3D.new()
	_sink_pot.name = "WeightedSinkLid"
	_sink_pot.position = Vector3(3.34, 1.025, -5.25)
	add_child(_sink_pot)
	_cylinder("DrainLid", Vector3.ZERO, 0.29, 0.025, "steel", Vector3.ZERO, _sink_pot)
	_cylinder("HeavyPot", Vector3(0, 0.16, 0), 0.235, 0.28, "metal", Vector3.ZERO, _sink_pot)
	_cylinder("PotLid", Vector3(0, 0.305, 0), 0.243, 0.024, "steel", Vector3.ZERO, _sink_pot)
	_box("PotKnob", Vector3(0, 0.34, 0), Vector3(0.09, 0.05, 0.045), "ink", false, _sink_pot)
	for side in [-1.0, 1.0]:
		_box("PotHandle", Vector3(float(side) * 0.28, 0.23, 0), Vector3(0.14, 0.04, 0.09), "ink", false, _sink_pot)
	_box("Stovetop", Vector3(5.04, 0.985, -5.3), Vector3(0.83, 0.025, 0.63), "ink")
	for x in [4.83, 5.26]:
		_cylinder("StoveRing", Vector3(float(x), 1.004, -5.3), 0.14, 0.01, "metal")
	_box("RangeHood", Vector3(5.04, 2.0, -5.63), Vector3(0.97, 0.13, 0.56), "steel")
	_box("HoodDuct", Vector3(5.04, 2.4, -5.71), Vector3(0.45, 0.7, 0.32), "steel")
	_box("Fridge", Vector3(5.39, 1.02, -2.01), Vector3(0.83, 2.04, 0.81), "ceramic", true)
	_box("FreezerSeam", Vector3(5.39, 1.43, -1.595), Vector3(0.79, 0.018, 0.009), "grout")
	_box("FridgeHandle", Vector3(5.05, 1.15, -1.566), Vector3(0.04, 0.41, 0.05), "steel")
	_box("FridgeMemo", Vector3(5.35, 1.74, -1.582), Vector3(0.22, 0.18, 0.008), "paper")
	_sphere("FridgeMagnet", Vector3(5.35, 1.81, -1.566), Vector3(0.022, 0.022, 0.008), "red")
	_table(Vector3(3.46, 0, -3.22), Vector3(1.54, 0.78, 0.85), "wood")
	_chair(Vector3(3.4, 0, -2.32), 0)
	_chair(Vector3(3.4, 0, -4.10), PI)
	_box("WovenPlacemat", Vector3(3.57, 0.827, -3.14), Vector3(0.58, 0.009, 0.40), "fabric")
	var mug: StaticBody3D = _target("mug", "머그잔", Vector3(3.77, 0.95, -3.1), Vector3(0.36, 0.25, 0.25))
	_cup = Node3D.new()
	_cup.name = "MugVisual"
	_cup.position = Vector3(0, -0.12, 0)
	mug.add_child(_cup)
	_box("TeaTin", Vector3(2.03, 1.08, -5.4), Vector3(0.15, 0.21, 0.15), "file")
	_box("ChoppingBoard", Vector3(2.58, 0.984, -5.31), Vector3(0.37, 0.025, 0.43), "wood")
	_cylinder("Plate", Vector3(3.27, 0.838, -3.19), 0.17, 0.02, "ceramic")
	_box("Chopsticks", Vector3(3.20, 0.844, -2.98), Vector3(0.28, 0.012, 0.015), "wood_dark")
	_box("Chopsticks", Vector3(3.20, 0.844, -2.95), Vector3(0.28, 0.012, 0.015), "wood_dark")

func _bathroom() -> void:
	_box("BathroomFloor", Vector3(3.7, 0.025, 3.35), Vector3(4.44, 0.05, 4.95), "grout")
	for x in range(9):
		for z in range(10):
			_box("FloorTile", Vector3(1.72 + float(x) * 0.47, 0.058, 1.11 + float(z) * 0.47), Vector3(0.46, 0.014, 0.46), "tile_dark" if (x + z) % 5 == 0 else "tile")
	for row in range(6):
		for col in range(9):
			_box("BathroomWallTile", Vector3(1.72 + float(col) * 0.47, 0.27 + float(row) * 0.44, 5.88), Vector3(0.46, 0.43, 0.025), "tile")
	for row in range(6):
		for col in range(10):
			_box("EastBathroomTile", Vector3(5.885, 0.27 + float(row) * 0.44, 1.10 + float(col) * 0.47), Vector3(0.025, 0.43, 0.46), "tile")
	_box("VanityCabinet", Vector3(3.35, 0.43, 1.38), Vector3(1.32, 0.86, 0.75), "green_dark", true)
	_box("VanityTop", Vector3(3.35, 0.9, 1.37), Vector3(1.39, 0.08, 0.81), "ceramic")
	_box("BasinInner", Vector3(3.35, 0.948, 1.4), Vector3(0.63, 0.014, 0.42), "steel")
	var tap: StaticBody3D = _target("wash", "수도꼭지", Vector3(3.35, 1.08, 1.10), Vector3(0.25, 0.3, 0.3))
	_faucet(Vector3(0, -0.11, 0), tap)
	_box("MirrorFrame", Vector3(3.35, 1.77, 0.908), Vector3(1.37, 1.08, 0.048), "wood_dark")
	_box("SmokedMirror", Vector3(3.35, 1.77, 0.938), Vector3(1.27, 0.98, 0.015), "green_dark")
	# Abstract muted bands avoid pretending a flat plane is a functional reflection.
	_box("MirrorHaze", Vector3(3.35, 1.76, 0.951), Vector3(1.20, 0.017, 0.008), "grout")
	_box("SoapDish", Vector3(3.88, 0.968, 1.44), Vector3(0.17, 0.026, 0.11), "ceramic")
	_box("Soap", Vector3(3.88, 0.997, 1.44), Vector3(0.11, 0.032, 0.065), "paper")
	_cylinder("ToiletPedestal", Vector3(5.12, 0.26, 2.04), 0.24, 0.44, "ceramic")
	_sphere("ToiletBowl", Vector3(5.12, 0.47, 2.04), Vector3(0.33, 0.15, 0.44), "ceramic")
	_box("ToiletTank", Vector3(5.12, 0.68, 1.58), Vector3(0.58, 0.75, 0.26), "ceramic", true)
	_box("FlushButton", Vector3(5.12, 1.063, 1.58), Vector3(0.08, 0.016, 0.055), "steel")
	_box("BathMat", Vector3(2.54, 0.08, 2.4), Vector3(0.9, 0.028, 0.61), "fabric")
	# Dry shower space with a target on clear south tile, not behind a fixture.
	_box("ShowerPan", Vector3(4.89, 0.09, 4.9), Vector3(1.69, 0.08, 1.68), "ceramic")
	_cylinder("ShowerDrain", Vector3(4.89, 0.136, 4.9), 0.07, 0.008, "steel")
	_box("ShowerPipe", Vector3(5.80, 1.48, 4.9), Vector3(0.035, 1.3, 0.035), "steel")
	_box("ShowerArm", Vector3(5.59, 2.13, 4.9), Vector3(0.46, 0.035, 0.035), "steel")
	_cylinder("ShowerHead", Vector3(5.39, 2.10, 4.9), 0.13, 0.04, "steel")
	var tile: StaticBody3D = _target("tile", "욕실 벽 타일", Vector3(3.2, 1.37, 5.835), Vector3(0.77, 0.86, 0.06))
	_box("PulseTile", Vector3.ZERO, Vector3(0.76, 0.85, 0.055), "tile_dark", false, tile)
	_tile_trace = Node3D.new()
	_tile_trace.name = "ImpossibleGroutTrace"
	_tile_trace.position = Vector3(3.2, 1.37, 5.675)
	add_child(_tile_trace)
	for i in range(6):
		var line: MeshInstance3D = _box("FineHairline", Vector3(-0.32 + float(i) * 0.12, sin(float(i) * 1.7) * 0.10, 0), Vector3(0.15, 0.011, 0.004), "green_dark", false, _tile_trace)
		line.rotation.z = sin(float(i) * 1.7) * 0.38
	_box("TowelBar", Vector3(2.05, 1.44, 5.72), Vector3(0.7, 0.035, 0.055), "steel")
	_box("HungTowel", Vector3(2.05, 1.16, 5.69), Vector3(0.48, 0.59, 0.04), "fabric")

func _entrance() -> void:
	_box("EntryTile", Vector3(0, 0.02, 5.15), Vector3(2.36, 0.04, 1.5), "stone")
	_box("EntryThreshold", Vector3(0, 0.045, 4.39), Vector3(2.4, 0.065, 0.11), "wood_dark")
	var door: StaticBody3D = _target("door", "현관문", Vector3(0, 1.13, 5.84), Vector3(1.1, 2.26, 0.12))
	_box("EntranceDoor", Vector3.ZERO, Vector3(1.08, 2.25, 0.115), "door", false, door)
	for x in [-0.6, 0.6]:
		_box("DoorJamb", Vector3(float(x), 1.2, 5.77), Vector3(0.12, 2.4, 0.17), "wood_dark")
	_box("DoorHeader", Vector3(0, 2.36, 5.77), Vector3(1.31, 0.12, 0.17), "wood_dark")
	_box("DoorLock", Vector3(-0.35, 1.1, 5.753), Vector3(0.12, 0.3, 0.035), "metal")
	_box("DoorLever", Vector3(-0.27, 1.03, 5.71), Vector3(0.24, 0.035, 0.035), "steel")
	_sphere("Peephole", Vector3(0, 1.62, 5.769), Vector3(0.018, 0.018, 0.009), "brass")
	var mark: StaticBody3D = _target("mark", "문틀의 자국", Vector3(0.603, 1.39, 5.66), Vector3(0.14, 0.33, 0.055))
	_box("MarkedJamb", Vector3.ZERO, Vector3(0.13, 0.33, 0.042), "wood_dark", false, mark)
	for i in range(3):
		_box("PencilHeightMark", Vector3(-0.012, -0.10 + float(i) * 0.09, -0.025), Vector3(0.09 - float(i) * 0.015, 0.008, 0.008), "paper", false, mark)
	_box("ShoeCabinet", Vector3(-0.94, 0.57, 5.18), Vector3(0.43, 1.14, 1.15), "trim", true)
	_box("ShoeCabinetHandle", Vector3(-0.704, 0.69, 5.18), Vector3(0.025, 0.22, 0.034), "brass")
	_shoe_pair(Vector3(0.47, 0.09, 4.85), 0.0)
	_box("UmbrellaStand", Vector3(0.91, 0.29, 5.4), Vector3(0.29, 0.58, 0.29), "green_dark", true)
	_box("Umbrella", Vector3(0.89, 0.67, 5.4), Vector3(0.055, 0.69, 0.055), "ink")
	# West-facing hall wallpad can be examined from the entry or bathroom doorway.
	var pad: StaticBody3D = _target("wallpad", "월패드", Vector3(1.289, 1.48, 3.94), Vector3(0.08, 0.36, 0.48))
	_box("WallpadHousing", Vector3.ZERO, Vector3(0.08, 0.35, 0.47), "ceramic", false, pad)
	_wallpad_screen = _box("WallpadScreen", Vector3(-0.047, 0.025, 0.034), Vector3(0.012, 0.245, 0.33), "screen", false, pad)
	_box("WallpadButton", Vector3(-0.051, -0.135, 0.035), Vector3(0.016, 0.025, 0.075), "metal", false, pad)
	_wallpad_map = Node3D.new()
	_wallpad_map.name = "ImpossibleAerialFeed"
	pad.add_child(_wallpad_map)
	for i in range(5):
		_box("AerialBuilding", Vector3(-0.058, -0.05 + float(i % 2) * 0.11, -0.07 + float(i) * 0.043), Vector3(0.004, 0.07, 0.029), "screen_line", false, _wallpad_map)
	for i in range(12):
		var angle: float = float(i) * TAU / 12.0
		_box("AerialUnclosedContour", Vector3(-0.061, 0.023 + cos(angle) * 0.077, 0.02 + sin(angle) * 0.11), Vector3(0.004, 0.008, 0.02), "ink", false, _wallpad_map)
	# Notice board sits on the north-west-facing wall, at readable head height.
	var notice: StaticBody3D = _target("notice", "야간 차광 안내문", Vector3(-1.182, 1.57, 2.01), Vector3(0.065, 0.60, 0.43))
	_box("NoticeBacking", Vector3.ZERO, Vector3(0.06, 0.59, 0.42), "wood_dark", false, notice)
	_box("NoticePaper", Vector3(0.039, 0, 0), Vector3(0.015, 0.53, 0.36), "paper", false, notice)
	_box("NoticeRedHeader", Vector3(0.049, 0.17, 0), Vector3(0.005, 0.027, 0.28), "red", false, notice)
	for i in range(8):
		_box("NoticePrintedLine", Vector3(0.049, 0.095 - float(i) * 0.039, 0), Vector3(0.005, 0.008, 0.28 - float(i % 3) * 0.031), "ink", false, notice)

func _outside_window() -> void:
	# The balcony and silhouetted apartment blocks create depth beyond the curtains.
	_box("BalconySlab", Vector3(-2.7, 0.35, -6.8), Vector3(5.2, 0.2, 1.7), "concrete")
	_box("WindowSill", Vector3(-2.7, 0.64, -5.82), Vector3(5.03, 0.09, 0.32), "trim")
	for x in [-5.13, -2.68, -0.21]:
		_box("WindowMullion", Vector3(float(x), 1.54, -5.88), Vector3(0.055, 1.83, 0.1), "trim")
	_box("WindowTopRail", Vector3(-2.68, 2.43, -5.88), Vector3(4.95, 0.055, 0.1), "trim")
	# Clear glass is a collider only; no expensive sorting/refractive material.
	_solid("WindowGlassCollider", Vector3(-2.7, 1.54, -5.93), Vector3(4.85, 1.8, 0.06))
	_box("BalconyRail", Vector3(-2.7, 1.24, -7.45), Vector3(5.2, 0.035, 0.05), "metal")
	for i in range(18):
		_box("BalconyBaluster", Vector3(-5.1 + float(i) * 0.28, 0.82, -7.45), Vector3(0.025, 0.84, 0.025), "metal")
	_box("CurtainTrack", Vector3(-2.5, 2.53, -5.53), Vector3(5.15, 0.07, 0.09), "metal")
	var curtain: StaticBody3D = _target("curtain", "암막 커튼", Vector3(-0.3, 1.6, -5.51), Vector3(0.27, 1.66, 0.14))
	_box("CurtainPullTab", Vector3(0, -0.35, 0.10), Vector3(0.06, 0.52, 0.06), "wood_dark", false, curtain)
	for side in range(2):
		var panel: Node3D = Node3D.new()
		panel.name = "BlackoutCurtainLeft" if side == 0 else "BlackoutCurtainRight"
		panel.position = Vector3(-3.51 if side == 0 else -1.49, 1.49, -5.57)
		add_child(panel)
		_curtains.append(panel)
		for fold in range(18):
			_box("HeavyFabricFold", Vector3(-1.04 + float(fold) * 0.123, 0, sin(float(fold) * 2.0) * 0.045), Vector3(0.14, 1.99, 0.08), "curtain" if fold % 3 != 0 else "green_dark", false, panel)
	for i in range(6):
		_tower(Vector3(-17.0 + float(i) * 7.8, -23.0, -25.0 - float(i % 2) * 12.0), Vector3(4.8, 20.0 + float((i * 3) % 8), 5.0), "green_dark", true)
	# A faint horizon mass is mostly obscured; its outline never becomes a monster reveal.
	_sphere("DistantOccludedHorizon", Vector3(-3.0, -7.0, -48), Vector3(22.0, 11.0, 3.0), "sky")
	_window_light = OmniLight3D.new()
	_window_light.position = Vector3(-2.7, 1.8, -4.8)
	_window_light.omni_range = 7.2
	_window_light.omni_attenuation = 1.4
	_window_light.light_energy = 0.55
	_window_light.light_color = Color("d8b37c")
	add_child(_window_light)
	_reverse_shadows = Node3D.new()
	_reverse_shadows.name = "ShadowsPointTowardWindow"
	add_child(_reverse_shadows)
	_quad_shadow([Vector3(-3.81, 0.044, -1.56), Vector3(-2.52, 0.044, -1.56), Vector3(-1.42, 0.044, -5.41), Vector3(-4.95, 0.044, -5.41)], _reverse_shadows)
	_quad_shadow([Vector3(-5.25, 0.047, 0.8), Vector3(-5.09, 0.047, 0.8), Vector3(-4.5, 0.047, -5.38), Vector3(-5.07, 0.047, -5.38)], _reverse_shadows)
	_box("RedLeakAtClosedCurtain", Vector3(-2.5, 0.49, -5.39), Vector3(4.3, 0.03, 0.13), "red_glow", false, _reverse_shadows)

func _make_mug(chip_side: int) -> void:
	if not is_instance_valid(_cup):
		return
	for child in _cup.get_children():
		_cup.remove_child(child)
		child.queue_free()
	var mesh: ArrayMesh = ArrayMesh.new()
	var vertices: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var segments: int = 48
	# Outer bottom, outer lip, inner lip, inner base. The lip itself has a notch.
	for ring in range(4):
		for i in range(segments):
			var angle: float = TAU * float(i) / float(segments)
			var radius: float = [0.087, 0.101, 0.084, 0.075][ring]
			var height: float = [0.018, 0.218, 0.218, 0.044][ring]
			if chip_side != 0 and ring in [1, 2]:
				var chip_angle: float = 0.34 if chip_side == 1 else PI - 0.34
				if absf(angle_difference(angle, chip_angle)) < 0.17:
					height -= 0.028
			vertices.append(Vector3(cos(angle) * radius, height, sin(angle) * radius))
			normals.append(Vector3(cos(angle), 0.15 if ring in [1, 2] else 0.0, sin(angle)) * (-1.0 if ring > 1 else 1.0))
	for ring in range(3):
		for i in range(segments):
			var a: int = ring * segments + i
			var b: int = ring * segments + (i + 1) % segments
			var c: int = (ring + 1) * segments + i
			var d: int = (ring + 1) * segments + (i + 1) % segments
			indices.append_array(PackedInt32Array([a, b, c, b, d, c]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var ceramic: StandardMaterial3D = _materials["cup"].duplicate() as StandardMaterial3D
	ceramic.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, ceramic)
	var visual: MeshInstance3D = MeshInstance3D.new()
	visual.mesh = mesh
	visual.name = "HollowMugWithRememberedChip"
	_cup.add_child(visual)
	_cylinder("ColdTea", Vector3(0, 0.157, 0), 0.079, 0.004, "coffee", Vector3.ZERO, _cup)
	var handle_mesh: TorusMesh = TorusMesh.new()
	handle_mesh.inner_radius = 0.043
	handle_mesh.outer_radius = 0.064
	handle_mesh.rings = 16
	handle_mesh.ring_segments = 10
	var handle: MeshInstance3D = MeshInstance3D.new()
	handle.name = "MugHandle"
	handle.mesh = handle_mesh
	handle.material_override = _materials["cup"]
	handle.position = Vector3(0.108, 0.124, 0)
	handle.rotation.x = PI / 2.0
	_cup.add_child(handle)
	if chip_side != 0:
		var patch: MeshInstance3D = _box("ExposedClayAtChip", Vector3(float(chip_side) * 0.093, 0.192, 0.03), Vector3(0.024, 0.013, 0.024), "chip", false, _cup)
		patch.rotation.z = float(chip_side) * 0.2

func _target(id: String, label_text: String, position_value: Vector3, size: Vector3) -> StaticBody3D:
	var body: StaticBody3D = _solid(id.capitalize(), position_value, size)
	body.set_meta("interact_id", id)
	body.set_meta("label", label_text)
	body.add_to_group("interactables")
	targets[id] = body
	return body

func _solid(node_name: String, position_value: Vector3, size: Vector3, parent: Node3D = null) -> StaticBody3D:
	var body: StaticBody3D = StaticBody3D.new()
	body.name = node_name
	body.position = position_value
	body.collision_layer = 1
	body.collision_mask = 1
	var collision: CollisionShape3D = CollisionShape3D.new()
	var shape: BoxShape3D = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	(parent if parent != null else self).add_child(body)
	return body

func _box(node_name: String, position_value: Vector3, size: Vector3, material_key: String, collision: bool = false, parent: Node3D = null) -> MeshInstance3D:
	var mesh: BoxMesh = BoxMesh.new()
	mesh.size = size
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.material_override = _materials[material_key]
	if collision:
		var body: StaticBody3D = _solid(node_name + "Body", position_value, size, parent)
		body.add_child(instance)
	else:
		instance.position = position_value
		(parent if parent != null else self).add_child(instance)
	return instance

func _wall(position_value: Vector3, size: Vector3, material_key: String) -> void:
	_box("Wall", position_value, size, material_key, true)
	if size.y > 2.0:
		_box("Skirting", Vector3(position_value.x, 0.105, position_value.z), Vector3(size.x + 0.04, 0.21, size.z + 0.04), "trim")
		_box("Cornice", Vector3(position_value.x, 2.69, position_value.z), Vector3(size.x + 0.065, 0.15, size.z + 0.065), "trim")

func _sphere(node_name: String, position_value: Vector3, radii: Vector3, material_key: String, parent: Node3D = null) -> MeshInstance3D:
	var sphere: SphereMesh = SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = sphere
	instance.material_override = _materials[material_key]
	instance.position = position_value
	instance.scale = radii
	(parent if parent != null else self).add_child(instance)
	return instance

func _cylinder(node_name: String, position_value: Vector3, radius: float, height: float, material_key: String, rotation_value: Vector3 = Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
	var cylinder: CylinderMesh = CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 20
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = cylinder
	instance.material_override = _materials[material_key]
	instance.position = position_value
	instance.rotation = rotation_value
	(parent if parent != null else self).add_child(instance)
	return instance

func _table(at: Vector3, size: Vector3, material_key: String) -> void:
	_box("TableTop", at + Vector3(0, size.y, 0), Vector3(size.x, 0.08, size.z), material_key, true)
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			_box("TableLeg", at + Vector3(float(x) * (size.x * 0.5 - 0.08), size.y * 0.5, float(z) * (size.z * 0.5 - 0.08)), Vector3(0.075, size.y, 0.075), "wood_dark", true)

func _chair(at: Vector3, heading: float) -> void:
	var chair: Node3D = Node3D.new()
	chair.position = at
	chair.rotation.y = heading
	add_child(chair)
	_box("ChairSeat", Vector3(0, 0.45, 0), Vector3(0.46, 0.08, 0.45), "wood", true, chair)
	_box("ChairBack", Vector3(0, 0.77, 0.19), Vector3(0.46, 0.62, 0.055), "wood", true, chair)
	for x in [-0.18, 0.18]:
		for z in [-0.17, 0.17]:
			_box("ChairLeg", Vector3(float(x), 0.22, float(z)), Vector3(0.04, 0.44, 0.04), "wood_dark", false, chair)

func _ceiling_lamp(at: Vector3, energy: float, light_range: float) -> void:
	_cylinder("CeilingLampTrim", at, 0.26, 0.06, "brass")
	_cylinder("CeilingLampDiffuser", at + Vector3(0, -0.037, 0), 0.23, 0.027, "warm")
	var light: OmniLight3D = OmniLight3D.new()
	light.position = at + Vector3(0, -0.3, 0)
	light.light_color = Color("ffe4b0")
	light.light_energy = energy
	light.omni_range = light_range
	light.omni_attenuation = 1.2
	add_child(light)

func _floor_lamp(at: Vector3) -> void:
	_cylinder("LampFoot", at + Vector3(0, 0.04, 0), 0.24, 0.08, "metal")
	_cylinder("LampStem", at + Vector3(0, 0.77, 0), 0.025, 1.5, "brass")
	_cylinder("FabricLampShade", at + Vector3(0, 1.58, 0), 0.30, 0.39, "fabric")
	_cylinder("WarmShadeOpening", at + Vector3(0, 1.376, 0), 0.28, 0.012, "warm")
	var light: OmniLight3D = OmniLight3D.new()
	light.position = at + Vector3(0.15, 1.34, 0)
	light.light_color = Color("ffc984")
	light.light_energy = 1.0
	light.omni_range = 5.8
	light.omni_attenuation = 1.5
	add_child(light)

func _desk_lamp(at: Vector3) -> void:
	_cylinder("DeskLampFoot", at + Vector3(0, 0.025, 0), 0.14, 0.05, "metal")
	_box("DeskLampStem", at + Vector3(0, 0.2, 0), Vector3(0.023, 0.4, 0.023), "brass")
	_box("DeskLampShade", at + Vector3(0, 0.42, 0), Vector3(0.34, 0.12, 0.2), "green_dark")
	_box("DeskLampDiffuser", at + Vector3(0, 0.35, 0), Vector3(0.30, 0.008, 0.17), "warm")
	var light: OmniLight3D = OmniLight3D.new()
	light.position = at + Vector3(0, 0.3, 0.1)
	light.light_color = Color("ffd092")
	light.light_energy = 0.6
	light.omni_range = 2.0
	add_child(light)

func _faucet(at: Vector3, parent: Node3D) -> void:
	_cylinder("TapRiser", at + Vector3(0, 0.105, 0), 0.025, 0.21, "steel", Vector3.ZERO, parent)
	_box("TapSpout", at + Vector3(0, 0.21, 0.085), Vector3(0.049, 0.046, 0.21), "steel", false, parent)
	_box("TapLever", at + Vector3(0.065, 0.065, 0), Vector3(0.115, 0.023, 0.042), "steel", false, parent)

func _shoe_pair(at: Vector3, heading: float) -> void:
	var pair: Node3D = Node3D.new()
	pair.position = at
	pair.rotation.y = heading
	add_child(pair)
	for side in [-1.0, 1.0]:
		_sphere("WornSlipper", Vector3(float(side) * 0.10, 0, 0), Vector3(0.075, 0.055, 0.16), "fabric", pair)
		_sphere("SlipperOpening", Vector3(float(side) * 0.10, 0.033, 0.045), Vector3(0.047, 0.028, 0.065), "wood_dark", pair)

func _vase(at: Vector3) -> void:
	_cylinder("GlazedVase", at + Vector3(0, 0.15, 0), 0.095, 0.3, "ceramic")
	for i in range(3):
		var stem: MeshInstance3D = _box("DryStem", at + Vector3(float(i - 1) * 0.045, 0.46, 0), Vector3(0.008, 0.46, 0.008), "wood_dark")
		stem.rotation.z = float(i - 1) * 0.17
		_sphere("DriedSeedHead", at + Vector3(float(i - 1) * 0.081, 0.66, 0), Vector3(0.042, 0.07, 0.026), "fabric")

func _plant(at: Vector3, height: float) -> void:
	_cylinder("PlantPot", at + Vector3(0, height * 0.17, 0), height * 0.23, height * 0.34, "wood_dark")
	_cylinder("PotSoil", at + Vector3(0, height * 0.345, 0), height * 0.207, 0.012, "soil")
	for i in range(7):
		var angle: float = float(i) * 2.4
		var leaf: MeshInstance3D = _sphere("BroadLeaf", at + Vector3(cos(angle) * height * 0.18, height * (0.6 + float(i % 3) * 0.11), sin(angle) * height * 0.18), Vector3(height * 0.12, height * 0.34, height * 0.035), "plant" if i % 2 == 0 else "plant_light")
		leaf.rotation.z = cos(angle) * 0.7
		leaf.rotation.x = sin(angle) * 0.7

func _tree(at: Vector3, factor: float) -> void:
	_cylinder("TreeTrunk", at + Vector3(0, 1.6 * factor, 0), 0.14 * factor, 3.2 * factor, "wood_dark")
	for i in range(5):
		var angle: float = float(i) * 2.4
		_sphere("TreeCrown", at + Vector3(cos(angle) * factor, (3.2 + float(i % 2) * 0.4) * factor, sin(angle) * factor), Vector3(1.4, 1.5, 1.3) * factor, "plant" if i % 2 == 0 else "plant_light")

func _tower(at: Vector3, size: Vector3, material_key: String, lit_windows: bool) -> void:
	_box("ApartmentBlock", at + Vector3(0, size.y * 0.5, 0), size, material_key)
	_box("TowerRoof", at + Vector3(0, size.y + 0.13, 0), Vector3(size.x + 0.18, 0.26, size.z + 0.18), "stone")
	var rows: int = int(size.y / 2.0)
	for row in range(rows):
		for col in range(3):
			var material_key_window: String = "amber" if lit_windows and (row * 7 + col * 13) % 9 < 2 else "green_dark"
			_box("DistantWindow", at + Vector3((float(col) - 1.0) * size.x * 0.28, 1.3 + float(row) * 2.0, size.z * 0.5 + 0.017), Vector3(size.x * 0.16, 0.86, 0.025), material_key_window)

func _quad_shadow(points: Array, parent: Node3D) -> void:
	var mesh: ArrayMesh = ArrayMesh.new()
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(points)
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 2, 1, 0, 3, 2])
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance: MeshInstance3D = MeshInstance3D.new()
	instance.name = "ReverseShadow"
	instance.mesh = mesh
	instance.material_override = _materials["shadow"]
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(instance)

func _exit_sign(at: Vector3) -> void:
	_box("ExitSign", at, Vector3(0.75, 0.25, 0.08), "exit_glow")
	_label("EXIT  →", at + Vector3(0, 0, 0.048), 0.0038, Color("e1f2d9"))

func _label(content: String, at: Vector3, pixel_size_value: float, color: Color, heading: float = 0.0) -> void:
	var label: Label3D = Label3D.new()
	label.text = content
	label.position = at
	label.rotation.y = heading
	label.font_size = 48
	label.pixel_size = pixel_size_value
	label.modulate = color
	label.no_depth_test = false
	label.outline_size = 0
	add_child(label)

extends CharacterBody3D

signal footstep(position: Vector3)

var camera: Camera3D
var enabled: bool = false
var motion_enabled: bool = true
var sensitivity: float = 0.0023
var speed: float = 2.1
var pitch: float = 0.0
var step_distance: float = 0.0
var time_walking: float = 0.0
var key_turn_speed: float = 1.5

func _ready():
	collision_layer = 2
	collision_mask = 1
	var collider = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.75
	collider.shape = capsule
	collider.position.y = 0.875
	add_child(collider)
	camera = Camera3D.new()
	camera.position.y = 1.62
	camera.fov = 68.0
	camera.near = 0.04
	camera.far = 90.0
	camera.current = true
	add_child(camera)
	floor_snap_length = 0.25

func _unhandled_input(event):
	if not enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * sensitivity
		pitch = clampf(pitch - event.relative.y * sensitivity, -1.25, 1.25)
		camera.rotation.x = pitch

func _physics_process(delta):
	if not enabled:
		velocity.x = move_toward(velocity.x, 0.0, delta * 10.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 10.0)
		return
	var axis = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W): axis.y -= 1
	if Input.is_physical_key_pressed(KEY_S): axis.y += 1
	if Input.is_physical_key_pressed(KEY_A): axis.x -= 1
	if Input.is_physical_key_pressed(KEY_D): axis.x += 1
	if Input.is_physical_key_pressed(KEY_LEFT): rotation.y += delta * key_turn_speed
	if Input.is_physical_key_pressed(KEY_RIGHT): rotation.y -= delta * key_turn_speed
	if Input.is_physical_key_pressed(KEY_UP): pitch = clampf(pitch + delta * 0.85, -1.25, 1.25)
	if Input.is_physical_key_pressed(KEY_DOWN): pitch = clampf(pitch - delta * 0.85, -1.25, 1.25)
	camera.rotation.x = pitch
	axis = axis.normalized()
	var direction = global_basis * Vector3(axis.x, 0.0, axis.y)
	velocity.x = move_toward(velocity.x, direction.x * speed, delta * 9.0)
	velocity.z = move_toward(velocity.z, direction.z * speed, delta * 9.0)
	if not is_on_floor(): velocity.y -= 9.8 * delta
	else: velocity.y = -0.1
	var old = global_position
	move_and_slide()
	var travelled = Vector2(global_position.x - old.x, global_position.z - old.z).length()
	step_distance += travelled
	if step_distance > 0.95 and is_on_floor():
		step_distance = 0.0
		footstep.emit(global_position)
	if travelled > 0.0001: time_walking += delta * 8.0
	var bob = sin(time_walking) * 0.012 if motion_enabled and travelled > 0.0001 else 0.0
	camera.position.y = lerpf(camera.position.y, 1.62 + bob, minf(delta * 10.0, 1.0))

func set_view(yaw: float, vertical: float = 0.0):
	rotation.y = yaw
	pitch = vertical
	if camera: camera.rotation.x = pitch

func interaction_hit(distance: float = 2.6) -> Dictionary:
	if camera == null or not is_inside_tree(): return {}
	var origin = camera.global_position
	var query = PhysicsRayQueryParameters3D.create(origin, origin - camera.global_basis.z * distance, 1)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)

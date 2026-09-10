## Supplemental physical traversal diagnostic. This does not certify a browser playthrough.
## No teleports, story mutations, target overrides, or production changes.
extends SceneTree
var game
var failures: Array[String] = []
var visits: Array = []
var distance_walked: float = 0.0
const CELL = 0.35
const DIRECTIONS = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
func _initialize():
	root.unfocusable = true
	call_deferred("run")
func key(code: int, down: bool):
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = down
	Input.parse_input_event(event)
func tap(code: int):
	key(code, true)
	await process_frame
	key(code, false)
	await physics_frame
func point(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * CELL, 0.0, cell.y * CELL)
func nav_cell(pos: Vector3) -> Vector2i:
	return Vector2i(roundi(pos.x / CELL), roundi(pos.z / CELL))
func clear_cell(cell: Vector2i, space, capsule) -> bool:
	if absi(cell.x) > 17 or absi(cell.y) > 18: return false
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, point(cell) + Vector3(0, 0.90, 0))
	query.collision_mask = 1
	query.exclude = [game.player.get_rid()]
	var hits = space.intersect_shape(query, 16)
	return hits.is_empty()
func can_aim(cell: Vector2i, target, space) -> bool:
	var origin = point(cell) + Vector3(0, 1.62, 0)
	if origin.distance_to(target.global_position) > 2.45: return false
	var query = PhysicsRayQueryParameters3D.create(origin, target.global_position, 1)
	query.exclude = [game.player.get_rid()]
	var hit = space.intersect_ray(query)
	return not hit.is_empty() and hit.collider == target
func route_to(id: String) -> Array:
	var space = game.player.get_world_3d().direct_space_state
	var capsule = CylinderShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.70
	var start = nav_cell(game.player.position)
	if not clear_cell(start, space, capsule):
		var nearest = INF
		var original = start
		for x in range(-2, 3):
			for z in range(-2, 3):
				var candidate = original + Vector2i(x, z)
				var distance = point(candidate).distance_to(game.player.position)
				if distance < nearest and clear_cell(candidate, space, capsule):
					nearest = distance
					start = candidate
	var queue = [start]
	var previous = {start:start}
	var blocked = {}
	var cursor = 0
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		if can_aim(cell, game.world.targets[id], space):
			var route: Array = [cell]
			while cell != start:
				cell = previous[cell]
				route.push_front(cell)
			return route
		for direction in DIRECTIONS:
			var next: Vector2i = cell + direction
			if previous.has(next) or blocked.has(next): continue
			if clear_cell(next, space, capsule):
				previous[next] = cell
				queue.append(next)
			else: blocked[next] = true
	return []
func walk_to(cell: Vector2i) -> bool:
	var destination = point(cell)
	for frame in range(180):
		var delta: Vector3 = destination - game.player.position
		delta.y = 0.0
		if delta.length() < 0.075:
			key(KEY_W, false)
			return true
		game.player.set_view(atan2(-delta.x, -delta.z))
		key(KEY_W, true)
		var before: Vector3 = game.player.position
		await physics_frame
		distance_walked += before.distance_to(game.player.position)
	key(KEY_W, false)
	failures.append("movement blocked at %s heading to %s" % [game.player.position, destination])
	return false
func visit(id: String, alternate: bool = false) -> bool:
	for frame in range(240):
		if not game.world.action_busy(): break
		await physics_frame
	await physics_frame
	var route = route_to(id)
	if route.is_empty():
		failures.append("no reachable line of sight: " + id + " in " + game.story.phase)
		return false
	for cell in route:
		if not await walk_to(cell): return false
	key(KEY_W, false)
	# Set only the view; locomotion above always uses the production player physics.
	var delta: Vector3 = game.world.targets[id].global_position - game.player.camera.global_position
	game.player.set_view(atan2(-delta.x, -delta.z), atan2(delta.y, Vector2(delta.x, delta.z).length()))
	await physics_frame
	await process_frame
	if game.active_target != id:
		failures.append("aim selected %s instead of %s at %s" % [game.active_target, id, game.player.position])
		return false
	await tap(KEY_Q if alternate else KEY_E)
	if id == "mug": await tap(KEY_ESCAPE)
	if game.mode != "play" and id not in ["archive", "worn", "new"]:
		failures.append("mandatory modal at " + id)
		return false
	visits.append({"id":id,"alternate":alternate,"phase":game.story.phase,"position":str(game.player.position)})
	print("WALK_VISIT:",JSON.stringify(visits.back()))
	return true
func run_route(ending: String) -> bool:
	game._start_new()
	await physics_frame
	for id in ["mark","photo","mug","wash","mug","curtain","sink","wallpad","tile","door"]:
		if not await visit(id, ending == "registered" and id in ["curtain","sink","wallpad","tile"]): return false
	if ending == "witness":
		if not await visit("archive"): return false
		# Activate the actual document choice button, without applying story actions directly.
		game.ui.modal_choices.get_child(0).pressed.emit()
		await process_frame
		if not await visit("exit"): return false
	else:
		if not await visit("stairs"): return false
	if not await visit("new" if ending == "registered" else "worn"): return false
	if game.story.ending != ending:
		failures.append("expected %s, got %s" % [ending,game.story.ending])
		return false
	return true
func run():
	game = load("res://scenes/main.tscn").instantiate()
	game.qa_mode = true
	root.add_child(game)
	await process_frame
	var endings = []
	for ending in ["survivor","witness","registered"]:
		if not await run_route(ending): break
		endings.append(ending)
	key(KEY_W, false)
	print("WALK_REVIEW:",JSON.stringify({"endings":endings,"visits":visits.size(),"metres":distance_walked,"failures":failures}))
	game.queue_free()
	# Fixed-FPS simulation outruns the audio thread; allow real cleanup time.
	var cleanup_deadline = Time.get_ticks_msec() + 250
	while Time.get_ticks_msec() < cleanup_deadline: await process_frame
	quit(0 if failures.is_empty() else 1)

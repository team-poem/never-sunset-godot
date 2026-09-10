extends RefCounted

var phase: String = "home"
var memories: Array = []
var history: Array = []
var exposure: int = 0
var report: bool = false
var voice: bool = false
var notice: bool = false
var visited_elevator: bool = false
var ending: String = ""
var rules: Dictionary = {"drain:touch":{"next":"signal","exposure":1},"dusk:look":{"next":"drain","exposure":1},"return:mug":{"next":"dusk"}, "dusk:seal":{"next":"drain"}, "drain:cover":{"next":"signal"},"home:wash": {"next": "return"}}

func snapshot() -> Dictionary:
	return {"version":1, "phase":phase, "memories":memories.duplicate(), "history":history.duplicate(), "exposure":exposure, "report":report, "voice":voice, "notice":notice, "visited_elevator":visited_elevator, "ending":ending}

func mug_state() -> String:
	return "left" if phase == "home" else ("smooth" if phase in ["return","dusk","drain"] else "right")

func apply_action(action: String) -> bool:
	if phase == "ending":
		return false
	if action == "notice" and not notice:
		notice = true
	elif phase == "home" and action in ["mug", "photo", "mark"]:
		if memories.has(action):
			return false
		memories.append(action)
	else:
		var key = phase + ":" + action
		if not rules.has(key):
			return false
		if action == "wash" and memories.size() != 3:
			return false
		if action == "archive" and report:
			return false
		if action == "elevator" and visited_elevator:
			return false
		var rule = rules[key]
		phase = rule.get("next", phase)
		exposure += rule.get("exposure", 0)
		if action == "answer": voice = true
		if action == "archive": report = true
		if action == "elevator": visited_elevator = true
		if action == "worn": ending = "witness" if report else "survivor"
		if action == "new": ending = "registered"
	history.append(action)
	return true

func restore_state(_raw: String) -> bool:
	return false

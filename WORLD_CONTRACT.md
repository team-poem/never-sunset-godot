# World / gameplay integration contract

Godot 4.7.2, GDScript, Compatibility. Build original detailed low-poly apartment from MeshInstance3D and physical collision geometry; soft warm lamps, credible human scale, green-gray plaster, wood floor, furniture, objects. No external dependencies, paid asset, addon.

World script: scripts/world.gd extends Node3D (no class_name).
- func build_apartment() -> void: add children to self, including Environment, lights, meshes and colliders.
- func build_landing() -> void: separate compact corridor/stair landing + openable archive nook, front exit and alternate elevator. Called on a fresh World instance.
- func build_dawn() -> void: exterior dawn ending view. Called on fresh instance.
- func apply_story(phase: String, exposure: int) -> void: update visible cup chip (home=left, return/dusk/drain=smooth, signal/pulse/escape=right), photo bandage side, curtain closed after dusk, red directional light and reverse shadow visual, sink pot after drain, wallpad display during signal, tile trace during pulse. May store current phase internally.
- func room_at(point: Vector3) -> String: return Korean room label.
- func get_spawn() -> Vector3: CharacterBody3D ground/base position, default (0,0.05,4.5), Camera is +1.65.
- var targets: Dictionary maps interact_id strings to Node3D (ray-cast collision bodies).
- Optional func animate(delta:float)->void for gentle ongoing environmental motion, called by main only if motion enabled.

Every interactable needs a StaticBody3D with CollisionShape3D on layer 1 and metadata "interact_id":String. Parent controls raycast/use and UI. Collider sizes must cover visible object, not huge invisible proximity volumes. Generic walls/furniture collider layer 1 without interact_id will occlude use. Set interactable bodies' metadata "label" with non-spoiling Korean label (e.g. 머그잔, 가족사진, 문틀, 수도꼭지, 커튼, 월패드, 배수구, 현관문). Group "interactables" for testing.

Apartment IDs: mug, photo, mark, wash (bathroom tap), curtain, sink, wallpad, tile, door, notice, sofa(optional).
Landing IDs: archive (report at accessible table), exit (go threshold choice), elevator(optional dangerous route), stairs(optional flavor).
Dawn IDs: none.

Layout: outer x -6..6, z -6..6, ceiling 2.8m. Hall x[-1.2,1.2],z[1.5,6]; entrance south z6, player starts (0,.05,4.5) looking north (-Z).
Living x[-5.8,1.0],z[-5.8,1.5]; window north z-5.8. Kitchen x[1.2,5.8],z[-5.8,-1]. Bathroom x[1.4,5.8],z[.8,5.8], doorway west wall x1.4 at z2..3.3. Keep doorway gaps wide >=1m and door headers above2.15m. Camera collision capsule radius0.25 height1.75.
Critical objects reachable by physical walking; mug on kitchen dining table, photo in living room, mark near front door; notice near entrance, wallpad in hall. No need to model player.
Cup should be a real hollow small mesh and visible chip geometry; parent will supply enlarged inspection object overlay separately. Tiny chip can be exaggerated slightly for legibility.
Use moderately bright ambient; dark corners but readable shape. Use localized warm light with low light count for Web. No environment-dependent system fonts. Label3D may use project font resource assets/korean.ttf if exists, otherwise omit Hangul labels (parent provides HUD).

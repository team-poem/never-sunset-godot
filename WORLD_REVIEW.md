# Procedural world implementation

Original Godot 4.7.2 Compatibility geometry, with no third-party assets.

## Delivered

- `scripts/world.gd`: contract methods for apartment, landing and dawn, plus `build_threshold()` and `create_mug_preview()`.
- Apartment: staggered grain-textured parquet, green plaster and trim, inhabited living room, dining kitchen, tiled bathroom, entry storage, balcony and distant housing blocks. Furniture and structural collisions are physical.
- All required targets have layer-1 colliders, Korean labels and `interactables` membership. The optional sofa, elevator and stairs are included.
- Mug is hollow original ring geometry. Its lip is notched at the remembered left side in `home`, smooth in `return/dusk/drain`, then notched on the opposite side in `signal/pulse/escape`. The preview returns only an unparented duplicate of these current visual parts at native 0.218 m height.
- Family photo bandage changes side late. Curtains close at dusk; red light leak and deliberately reversed floor shadows persist. Sink gets its weighted lid/pot, wallpad shows an impossible plan, bathroom grout slowly shifts at the pulse.
- Landing: corridor, ajar archive door, physically accessible report, elevator, stairs and emergency exit.
- Threshold: dawn-lit glazed vestibule. Dish has separate `new` key on the player's left and `worn` key on the right. Spawn faces north, toward the dish. Exit glass remains solid; main decides the ending from a confirmed key interaction.
- Dawn: courtyard, bench, planted trees and intact 104 with a distant thin red window.

## Verification

`tools/godot.sh --headless --path . --log-file /private/tmp/never-sunset-world.log --check-only --script scripts/world.gd` passes without script errors.

An independent temporary SceneTree probe (`/private/tmp/never_sunset_world_check.gd`) instantiated all four worlds, exercised every apartment phase, animated pulse/drain and duplicated/freed all mug previews. It used an actual 1.75 m high, 0.26 m radius capsule at 0.3 m grid intervals, flooded physically free cells from spawn, and ray-tested each target from reachable camera positions within 2.6 m. All apartment (11), landing (4) and threshold (2) targets are reachable and unoccluded. Result: `WORLD CHECK PASS`.

The headless engine emitted the host CA-certificate warning; no GDScript or scene errors occurred. Parent must review actual rendered lighting, camera movement and interaction HUD in the integrated build. The bathroom mirror is intentionally opaque/muted, not a real reflection. No dynamic camera movement or flashing effects are introduced.

## Integration notes

- Five apartment omni lights and one shadowed directional light. Omnis do not cast shadows. Material resources are shared except the two-sided mug ceramic. There are many modest individual floor/tile meshes; optimize with MultiMesh if actual browser measurements demand it.
- `apply_story()` expects canonical phase `return` (any other unrecognized non-home early phase also results in a smooth mug).
- Cup handle projects right, and inspection starts facing the positive-Z side; orbit/drag shows both lip states.
- `get_spawn()` returns ground/body-base `(0, 0.05, 4.5)` for apartment/landing/threshold, `(0, 0.05, 4)` for dawn. Camera eye should be +1.65 m.
- World uses only ASCII physical labels (104, 1504, EXIT). Parent HUD supplies Korean target names and full readable notices.

# Never Sunset · 104

A complete, compact Korean first-person story horror game built in Godot 4.7.2. Walk through a familiar apartment, remember its imperfections, and discover that the replacements are too perfect. Intended playtime is about 15 minutes; this is a design estimate, not a measured average.

[한국어 안내](README.ko.md)

## Play

Open `project.godot` in Godot 4.7.2 and press F6 on `scenes/main.tscn`, or run `npm start`.
The project-local official macOS runtime is used by `tools/godot.sh`. On another machine install Godot and put `godot` on PATH, or set `GODOT_BIN` to its executable.

- WASD: walk. Mouse or arrow keys: look. If mouse capture is unavailable, hold the left mouse button and drag.
- E or left click: inspect the object under the crosshair.
- Drag or arrow keys: rotate the held cup. Esc puts it down.
- J: remembered details. Esc: settings and pause. F: fullscreen.
- Settings include sound and camera bob. Every essential sound clue has text.

Desktop keyboard and mouse are required. Touch controls are not implemented. Save data is local to the current native user or browser origin. Clearing browser site data removes it. There is no backend, account, or analytics.

## Scope

One apartment, an evacuation landing, a key threshold, and ending spaces; three endings; optional 1994 construction evidence. Changes to cup, photograph, doorway mark, light, drain, wallpad and bathroom pulse are tied to the story state. The original HTML game remains in the separate `../never-sunset` project.

The visual style uses original low-poly geometry, restrained environmental sound and Korean written narrative. It has no voice acting, chase sequence, combat, or jumpscare system. The panoramic elevator is an optional visual observation at its doors, rather than a fully simulated elevator ride.

## Web build and sharing

Place matching Godot 4.7.2 single-thread templates at `.tools/web_nothreads_debug.zip` and `.tools/web_nothreads_release.zip` (official release URL and checksums in `ASSET_SOURCES.md`). Then:

```sh
npm run export:web
npm run serve
```

Open http://localhost:4174 in a desktop browser. The localhost address works only on this machine. Prefer a normal browser window; some embedded browsers reject mouse capture.

The export creates `build/web/` and `build/never-sunset-web.zip`, including third-party licenses. Upload the **contents of build/web**, keeping `index.html`, `.js`, `.wasm`, `.pck` and other files together, to a static host such as Netlify or Vercel. No server function is required. This repo does not include a cloud build pipeline or a live deployment. A Git-connected host needs a separate Godot build step because build output and engine binaries are ignored by Git.

Single-thread Compatibility/WebGL 2 export does not require cross-origin isolation headers. Serve `.wasm` as `application/wasm`; use HTTPS on the public host. Opening the HTML directly with `file://` is not supported. Initial uncompressed runtime/game download is approximately 44 MB; hosting compression reduces network transfer.

## Verification

```sh
npm test
```

14 frozen Node tests execute the actual Godot state/controller; `failed-test.md` records verified initial failures. `QA.md` records additional scene, physics, browser and export checks and their limits. `tools/integration_probe.gd` uses `--qa-no-save` to avoid changing player progress.

Project design: `STORY_NOTES.md`, `WORLD_CONTRACT.md`, `WORLD_REVIEW.md`. Asset sources and licenses: `ASSET_SOURCES.md`, `assets/FONT-LICENSE.txt` and the generated Web license file.

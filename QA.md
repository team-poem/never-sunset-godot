# Godot edition verification · 2026-09-10

## Automated regression suite

`npm test`: 14 tests pass. Tests run the actual Godot 4.7.2 executable, rather than a JavaScript copy of the story state. Each case was demonstrated failing before implementation and retained verbatim. Covered: distinct baseline memories, replacement discovery, four rule sequences, evacuation prerequisites, three endings, replay-validated saves, terminal safety, cup Esc handling in both phases, unread narrative restoration, camera-bob setting, and drag look without pointer capture.

## Independent integration review

A read-only reviewer instantiated the actual main scene and passed 277 assertions. Every action went through `_interact` / `_on_action`; checked both safe and violating choices, archive/reread, optional elevator, all three endings, Esc/settings/notebook/title, and JSON snapshot restore at each outcome boundary. This verifies controller and scene integration, not a human playthrough.

## World and physics

All four spaces build. Seventeen target IDs are reachable by capsule-clear route and interaction ray in the world review. Held-input checks in the actual player moved 1.025 m over 30 W physics frames; pause displaced 0 m; right key turned 0.725 radians; 120 forward frames into the front door stopped at z=5.5285. Every apartment target was hittable from a standing position using the player's actual raycast.

Causal scene checks initially failed nine assertions, then passed after fixing curtains, sink pot, wallpad and photo timing. Curtains close after sealing; pot appears after covering; aerial feed appears only during the signal; photograph changes after washing.

## Browser / native execution

- Native Compatibility renderer launched on Apple M5 Pro / Metal OpenGL, with real 3D output.
- Release Web build exported successfully from Godot 4.7.2 single-thread templates.
- In-app browser at 1280×720 and Chrome at its existing tall viewport displayed the scene and Korean title/dialogues. Fixed variable font weight using the integer OpenType tag, then visually verified legible final text.
- Browser UI checked: start/prologue, pause/settings, notebook, reload/continue saved progress.
- Final browser build: dragged the view from the hall toward the wallpad, saw the `[E] 월패드` raycast prompt, pressed E, and verified the matching inspection dialogue.
- Automated browser pointer capture requests were rejected (`UnknownError` in embedded browser; `WrongDocumentError` in background Chrome). Added and browser-verified left-drag look fallback, with arrow-key look also available. Native/browser ordinary foreground pointer capture has not been manually certified.
- CUA sends down/up as a short key press; held movement was therefore verified with real Godot physics frames, not represented as a completed browser walking playthrough. Endings were verified in actual scene integration, not manually walked in a browser.
- Audio assets and phase routing loaded successfully. Subjective headphone balance and fear response require human feedback; they are not proven by automated checks.

## Export and limits

`build/web` contains HTML, JavaScript, WASM, game pack and license notices. `build/never-sunset-web.zip` is approximately 16 MiB. Static HTTP local serving works. No public Netlify/Vercel deployment has been performed. No mobile touch controls, cloud saves, or cross-browser Safari/Firefox certification.

The game is a complete compact narrative implementation with original simple geometry; it is not photorealistic. The optional elevator is an observation scene, not a fully animated ride. Intended playtime is an estimate.

## Diagnostic notes

MovingCurtain worker check (2026-09-10): reproduced `node --test --test-name-pattern=MovingCurtain tests/atmosphere.test.js` failing at `animated` (`false !== true`). Primary curtain interaction in dusk now commits `seal` through the existing story rules and animates both panels over 2.4 seconds. Narration stays in subtitles with movement enabled; repeated interaction during the pull neither restarts it nor opens a modal. Reapplying a closed story state preserves an active pull, while restored worlds use the final closed pose. `npm test` passes all 17 materialized tests, including the approved actual-scene evidence for intermediate/final transforms, continuous movement, drain phase, and exactly one seal commit. The declared editor/import lint, `npm run export:web`, and `git diff --check` pass; existing sandbox log/editor-settings errors and certificate warnings remain. Browser gameplay was not rechecked for this entry. Approved inputs, tests/support, plan checkboxes, and Git metadata were not edited by this worker.

HeldCup worker check (2026-09-10): reproduced `node --test --test-name-pattern=HeldCup tests/atmosphere.test.js` failing at `continuous` (`false !== true`). Cup inspection now attaches the existing procedural cup geometry to the player camera, hides the table copy, and shows narration while movement remains enabled. E or Esc puts it down through the existing story action; world recreation clears the held model. `npm test` passes all 16 materialized tests, including HeldCup, CupEscapeMemory, and CupEscapeReturn. The declared editor/import lint and `npm run export:web` both exit 0; sandbox log/editor-settings errors and the existing certificate warning remain. `git diff --check` passes. The actual-scene probe verifies camera-child meshes, enabled movement, no modal, and Esc memory recording; browser gameplay was not rechecked for this entry. Approved inputs, tests/support, plan checkboxes, and Git metadata were not edited by this worker.

WorldObservation worker check (2026-09-10): reproduced `node --test --test-name-pattern=WorldObservation tests/atmosphere.test.js` failing because `continuous` was false. Mark and photo now retain their existing memory/save behavior and show their phase-specific descriptions as 14-second subtitles, with an immediate HUD refresh and no modal. `npm test` passes all 15 materialized tests; the approved actual-scene probe verifies both memories, play mode, enabled movement, and no visible modal. `npm run export:web` completed editor import and single-thread Web export with exit code 0; the existing sandbox log/editor-settings errors and certificate warning remain. `git diff --check` passes. Browser gameplay was not rechecked for this entry. Approved inputs, tests, plan checkboxes, and Git metadata were not edited by this worker.

ContinuousEntry worker check (2026-09-10): reproduced the approved assertion failure (`continuous` was false). Replaced only the opening dialogue with 14-second homecoming subtitles through the existing `_say` method. `npm test` passes all 14 currently materialized tests, including ContinuousEntry. `npm run export:web` completed its editor import and single-thread Web export with exit code 0. Sandbox restrictions produced log/editor-settings write errors and the existing certificate warning. A new local server attempt (`PORT=4186 node tools/serve.mjs`) failed with `listen EPERM`; browser approval review then denied access to the existing localhost:4174 URL. Browser gameplay verification of this change remains unavailable; the actual-scene test confirms play mode, enabled movement, no visible modal, and populated narration. No approved inputs or checkboxes were changed.

macOS sandboxed headless tests print a certificate lookup warning; this does not fail gameplay or tests. The early cup integration probe terminated before audio thread cleanup, producing two resource warnings; a 0.2-second teardown grace period removes them. Independent full-flow probes reported no gameplay errors.

## Final gate

Sobaya gate PASS: 14 checked entries, 14 passing tests, 21 implementation commits since the recorded loop baseline, no existing test lines modified, every checked test retained verbatim. Release ZIP integrity check passed; all 11 expected output entries are readable, including HTML/JS/WASM/PCK and license notices. Final ZIP size: 17,244,819 bytes.

DirectAppliances worker check (2026-09-10): reproduced the approved test failing at continuous (false !== true). Primary sink, wallpad, and tile interactions now invoke cover, off, and count in their respective story phases. Outcomes use subtitles with movement enabled and no confirmation page; other phases show observation subtitles. Existing story rules preserve phase progression and prevent repeated commits. npm test passes all 18 materialized tests, including direct scene evidence for continuous play, signal/pulse/escape progression, and zero exposure. Editor/import lint, npm run export:web, and git diff --check pass; existing sandbox log/editor-settings errors and certificate warnings remain. Browser verification was blocked: PORT=4186 node tools/serve.mjs exited 1 with listen EPERM on 127.0.0.1:4186. The Web build was regenerated successfully. Approved inputs, tests/support, plan checkboxes, and Git metadata were not edited by this worker.

RiskyChoice worker check (2026-09-10): reproduced `node --test --test-name-pattern=RiskyChoice tests/atmosphere.test.js` failing with `'dusk' !== 'drain'`. Q now invokes the existing look action only while playing, targeting the curtain in dusk, and not holding the cup. The curtain prompt advertises Q; the outcome uses subtitles and the existing closing animation. Phase progression prevents repeated look commits. `npm test` passes all 19 materialized tests, including actual-scene evidence for continuous play, drain phase, exposure 1, and exactly one look commit. Editor/import lint, `npm run export:web`, and `git diff --check` pass; existing sandbox log/editor-settings errors and certificate warnings remain. Browser verification is unavailable: `PORT=4186 node tools/serve.mjs` exited 1 with `listen EPERM: operation not permitted 127.0.0.1:4186`. The Web build was regenerated. Approved inputs, tests/support, plan checkboxes, and Git metadata were not edited by this worker.

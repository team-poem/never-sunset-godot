# Atmosphere release verification · 2026-09-10

## Approved acceptance

The user approved the 11 atmosphere entries and the exact PendingOutcome replacement, then separately approved the backticked Test declaration. Baseline: `5ada23ef9da981a558d335a06558ac97a239d09c`. The Sobaya runner materialized and checkpointed all 11 entries; the retained 13 tests and the 11 additions comprise the declared 24-case suite. No approved tests, headers, scene_probe.gd support, or spec were changed by the subsequent implementation polish.

`npm test` passes all 24 tests against the actual Godot executable. The suite covers continuous entry/observations/cup handling, curtain intermediate motion and duplicate prevention, direct appliances, risky curtain input, dark ambient fill, reachable door mark, real material maps, narration restoration, spatial recorded sound/mute, and the original story/ending/save rules. Editor import and single-thread Web export succeed without script errors.

## Independent review findings and correction evidence

The first independent review of `95e9bf2` identified four real gaps despite the green suite: restart could retain a title return mode; appliance Q branches were unreachable; narration was overwritten/not fully saved; the replacement cup still opened a mandatory modal. The final implementation resets restart return state, provides Q for all four dangerous choices, queues and restores unread subtitle paragraphs, and uses continuous primary interactions through the physical key choice. Optional documents/settings/endings retain panels.

`drafts/atmosphere/flow_review.gd` is an additional diagnostic rehearsal of already-approved manual criteria, **not an added or approved acceptance baseline**. Run with `tools/godot.sh --headless --path . --script res://drafts/atmosphere/flow_review.gd -- --qa-no-save`. It passed 38 checks: restart confirmation plus cup release, ordered observation text, queue restoration, direct wash/replacement discovery, held-cup R rotation, unread narration restoration for all safe rules, direct evacuation, all four Q inputs and duplicate prevention, accessible voice evidence, optional archive, all three endings, and retention/save restoration/readable access/return for unread ending narration. This is actual-scene controller/input verification, not a claimed human browser playthrough.

The second independent review of `ad3a213` found unread arrival narration could be lost when a key was selected quickly, and correctly kept full Web traversal open. The ending now preserves the active subtitle and queue as an optional “문 앞에서 떠올린 것” transcript; the transcript is saved, restored, and can return to the ending without restarting. The 38-check diagnostic verifies these boundaries. The remaining manual browser traversal criterion has not been replaced or waived.

The final gate and separate read-only completion review are revision-bound in `.git/sobaya/state.json`; use the harness status/review commands to inspect the current HEAD receipt. A commit or this document alone is not acceptance.

## Render and playback evidence

- Actual Compatibility rendering ran on OpenGL 4.1 Metal / Apple M5 Pro. Fifteen staged views cover the entry, mark, photograph, cup/held cup, dusk, intermediate/closed curtains, drain, intermediate/placed pot, wallpad/fade, pulse and late hall. All final staged interactions remained in play mode. Images and the capture script/log are under ignored `artifacts/atmosphere/` in this local checkout.
- Native screenshots show the nine ambientCG maps on actual surfaces, local shadows, readable mark and mug, the side-to-drain pot movement, wallpad dimming, and residual red light after curtain closure. Ambient fill is 0.12 with the original 68-degree camera field of view. Practical lamps dim further as the rules progress. The geometry remains intentionally simple, not photorealistic.
- The approved audio case also ran in **windowed** Godot with the real native renderer/audio backend and returned `spatial_recording: true`, `audible_when_muted: 0`, exit 0. All 27 selected OGG recordings successfully decoded. Contact gains are restrained, and existing low ambience is retained. Subjective headphone balance and fear response are not certified by these measurements.
- The Web build is served on the existing loopback server at localhost:4174. CUA visually checked title/start, saved resume, nonblocking mark observation, mouse-drag look, settings, sound off/on, and return to play. The final build loads the larger asset pack. Embedded Chromium still sometimes rejects pointer lock with its existing UnknownError; the previously tested drag fallback remains usable.
- CUA provides short key presses rather than held movement. Full browser walking through all endings was **not** completed. A native-app input fallback was also unavailable: CUA explicitly refused access to the Codex app for safety reasons; that restriction was not bypassed. Held movement/obstacle behavior was verified in actual Godot physics during the earlier release; the final three branches are covered by the declared story suite and the 38-point scene rehearsal. No Safari/Firefox/mobile certification is claimed.

The first screenshot pass received external keyboard/mouse input and was discarded. The repeat staged capture disabled gameplay input in the diagnostic runner and made its window unfocusable. This diagnostic change does not alter game controls.

## Build and redistribution

`build/web/` and `build/never-sunset-web.zip` contain the single-thread WebGL 2 build, Godot/font notices, both Kenney CC0 notices, ambientCG source/license notice, and ASSET_SOURCES.md. ZIP CRC validation passes and all 11 output entries are readable. The current compressed ZIP is approximately 26.5 MiB. Draft scripts and unused procedural surface prototypes are excluded from the production export.

All 27 recordings and nine JPG maps retain their downloaded bytes. License wording is preserved, with line endings/trailing whitespace normalized. Sources are listed in ASSET_SOURCES.md. No Freesound recording or paid asset was used. No public hosting deployment or cloud build pipeline was performed.

## Environment notes

The Homebrew Codex 0.146.0 executable could not run Astra; the existing app-bundled Codex 0.153.3 worked through a per-command PATH override. The model was not switched. Worker sandbox DNS/listen/window restrictions caused diagnosed handoffs; the parent supplied an already-verified Kenney recording and performed native playback/browser checks in its available environment. Repeating a blocked worker-local server was not treated as verification.

Headless teardown note: the full suite can still print a small ObjectDB leaked-at-exit warning. Detailed isolation identified audio playback references during rapid scene teardown; ambient playback now uses the engine's WAV loop, mute stops sources, and world/scene exit explicitly stops and releases streams. The latest declared suite passed all 24 cases with no script errors or resource-in-use ERROR lines. This warning is retained as a diagnostic limitation rather than suppressed through changed tests.

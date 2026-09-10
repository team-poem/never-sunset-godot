# Development lessons

App-local reflection; the protected Sobaya harness and brain were not edited.

- Compare replay snapshots through the same JSON normalization path. JSON numeric decoding turns integer arrays/dictionaries into floats, so direct Variant equality can reject a valid save.
- Persist the pending narrative action as well as the story state. Saving after a transition but before the player acknowledges its prose otherwise drops the emotional beat on reload.
- Inspectors need one acknowledgement path for button, Esc and other exits. The cup's visual inspection and logical memory were initially inconsistent.
- Separate comfort settings from environmental storytelling. Camera bob can be disabled while preserving the pulse/prop animations that communicate the rules.
- Single-thread Web exports preserve simple static hosting. Browser pointer lock is still environment-dependent; keep a drag or keyboard alternative and test it independently.
- Variable font axes should use TextServer integer tags for reliable weight selection in this runtime. A technically loaded font can still be unreadably thin; inspect actual rendered Korean text.
- Keep QA save paths isolated from player progress. `--qa-no-save` prevents disposable actual-scene tests overwriting a live run.
- Allow audio teardown to finish before exiting very short integration probes. Early engine exit can report playback resources that disappear with a short cleanup grace period.

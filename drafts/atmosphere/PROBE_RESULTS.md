# Draft probes

Baseline: cf3a297. No gameplay implementation changed.

- RED    ContinuousEntry: homecoming begins with narration while walking remains available  (fails: assertion/test failure; diagnostics above)
- RED    DarkApartment: ambient fill is reduced while practical light and the existing field of view remain  (fails: assertion/test failure; diagnostics above)
- RED    DirectAppliances: sink wallpad and tile advance through direct actions without confirmation pages  (fails: assertion/test failure; diagnostics above)
- RED    FindableDoorMark: the original door mark has a forgiving visible interaction target  (fails: assertion/test failure; diagnostics above)
- RED    HeldCup: the cup is held in the world with walking enabled and Esc records it  (fails: assertion/test failure; diagnostics above)
- RED    MovingCurtain: primary interaction visibly closes curtains once while movement stays enabled  (fails: assertion/test failure; diagnostics above)
- RED    RealSurfaceMaps: plaster wood and tile use real color and normal textures in the scene  (fails: assertion/test failure; diagnostics above)
- RED    RiskyChoice: Q at the curtain keeps the risky path available without a choice modal  (fails: assertion/test failure; diagnostics above)
- RED    WorldObservation: observing the mark and photo records memories without a modal  (fails: assertion/test failure; diagnostics above)
- RED    PendingOutcomeV2: unread narration restores without freezing and expires without a Continue click  (fails: assertion/test failure; diagnostics above)
- RED    SpatialInteractionAudio: curtain contact plays a free recorded sound at the object and respects mute  (fails: assertion/test failure; diagnostics above)

All failures were actual assertions on current scene behavior. No script/parse errors were observed.

# Story integration notes

The compact Korean pages support physical observation. Do not display a page merely because a phase changes: the player must walk to and inspect the next object. The initial three memories establish a chipped cup, a bandaged hand, and imperfect handwriting before their corrections become disturbing.

`inspect(id, state)` never mutates state. `outcome(action, state)` expects the snapshot after a successful action. Only show the `mug` outcome for the second cup interaction (`return` → `dusk`), never for the initial memory collection. The parent should retain the cup inspection/rotation interface so the player notices its smooth rim before narration confirms anything.

Supported IDs: notice, mark, photo, mug, wash, curtain, sink, wallpad, tile, mirror, sofa, door, archive/report, elevator, exit/stairs. IDs have ordinary object titles. `archive` records its text only through action `archive`. `exit` in landing means walking down the stairs; at threshold it offers `worn` / `new`. `door` offers `leave` only in escape. The player washes only after all three memories, through the bathroom `wash` object.

The elevator is an optional look from outside its open cabin on the landing. No boarding or floor change is claimed, matching the state machine's lack of a next phase for `elevator`. It closes before the player continues toward the stairs. The dark surface remains unexplained.

Physical continuity: `look` still seals the curtain, `touch` still places the pot and waits outside, and both wallpad choices switch the power off and wait for the calls to stop. The breach choices add ambiguity and an exposure mark without inventing new monster abilities or an unwinnable trap. Consequences remain subtle; high exposure adds a new date above eye level at the doorframe.

Memory geometry must match the procedural assets: with the handle at the right, the initial cup chip is on the near-left rim, later smooth, and finally on the near-right rim. The photo's bandage begins on the protagonist's right thumb and changes to the left; the father's shirt pocket stays on his left. The player character's initial right-thumb scar is textual grounding for the survivor ending. Initial doorframe 2 is mirrored; corrected 2 is ordinary.

Three endings: `report && worn` gives witness (`처음 본 것`); `!report && worn` gives survivor (`정상 퇴실`); `new` gives registered (`기존 세대`). The choice is grounded in worn physical familiarity versus an official instruction to use a restored key. The archive deepens the correction pattern without explaining the entity. The opening and registered ending repeat barley-tea smell, right-hand dish, handwriting, bandage, and cup; the duplicate shoes are the final mismatch.

Pacing target: approximately ten minutes including movement, cup rotation, optional reinspection, notebook reading, and the stair departure. Time skips in the prose compress the thirty-minute wait and midnight transition; they should never impose real-time idle waiting. No jump scare, forced chase, combat, creature reveal, or lore encyclopedia is used.

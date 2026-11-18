# Forest Drake Interaction V1

## Purpose

An isolated, touch-friendly pickup and placement proof for the Forest Drake. It is built on the approved multi-part idle rig and does not replace the existing animation proof, main scene, live world projection, creature data or source artwork.

## Run

Open `scenes/tests/forest_drake_interaction_review.tscn` in Godot 4.7 and press **F6**.

## Controls

- **Mouse:** left-click and hold on the Forest Drake, move the pointer, then release.
- **Touch:** press the Forest Drake, drag, then lift your finger.
- **Space:** intentionally disabled so the review remains on the rigged creature.

The drake can be picked up repeatedly and dropped anywhere in the review board. This first milestone deliberately tests only world pickup, carry and placement. It does not yet move the creature into a collection bag or validate occupied/blocked placement cells.

## Interaction behaviour

1. Pressing inside the creature's generous touch target begins pickup.
2. The rigged visual eases upward by 34 screen pixels.
3. While held, the ground anchor follows the pointer with a small amount of smoothing.
4. The existing idle layers keep running, while the entire creature receives a subtle independent hover bob.
5. The shadow stays on the ground plane, follows the ground anchor and becomes slightly wider and softer-looking as the creature rises.
6. Releasing the pointer commits the final ground position and eases the creature back down.

The rig is wrapped in a dedicated ground-anchor Node2D. This is important: the wrapper participates in the world's Y sorting and moves the creature's ground projection, while only the visual child is vertically offset. The shadow is a separate sibling and never rises with the creature.

## Tuning values

The initial feel is intentionally conservative and easy to adjust in the interaction script:

- Lift height: 34 px
- Pickup easing: 0.22 s
- Settle easing: 0.24 s
- Drag-follow response: 18
- Hover bob: 2 px at 2.1 radians/second
- Shadow scale at full lift: 1.34x
- Shadow alpha at full lift: 0.72x

These are prototype values, not final global interaction constants.

## Non-destructive boundary

Only these new files are added:

- `scenes/tests/forest_drake_interaction_review.gd`
- `scenes/tests/forest_drake_interaction_review.tscn`
- `docs/FOREST_DRAKE_INTERACTION_V1.md`

The inherited `animation_proof_review.gd` and `.tscn` remain unchanged. Main gameplay, camera movement, grid projection, source sprites, creature definitions and the Qwen animation workflow are untouched.

## Runtime review checklist

- Does the drake visibly lift as soon as it is picked up?
- Does the shadow remain grounded and follow the creature's projected position?
- Does the finger-to-creature relationship feel natural while dragging?
- Does the smoothing feel responsive rather than laggy?
- Does the drake land cleanly at the release point?
- Does the existing head, breathing, wing and tail idle still read correctly while carried?

The first Godot runtime test should focus on those points before adding bag collection, placement snapping or generic reusable pickup logic.

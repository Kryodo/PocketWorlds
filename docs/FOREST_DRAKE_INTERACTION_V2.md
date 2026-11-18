# Forest Drake Interaction V2 — Carried Float Idle

## Purpose

A touch-friendly pickup/drag/drop proof using the refined rig from `experiment/forest-drake-walking-proof-v1`. This version retains the V6 contact shadow, forepaw weights, standing and lying posture work, and in-place walking experiment.

It adds a dedicated carried reaction and a quirky hover idle, all animated at runtime in Godot. No new sprite sheet, external animation software, or generated frames are required for this proof.

## Run

Open `scenes/tests/forest_drake_interaction_review.tscn` in Godot 4.7 and press **F6**.

## Controls

- **Mouse:** left-click and drag on the Forest Drake, then release.
- **Touch:** press the Forest Drake, move your finger, then release.
- **R:** restart the standing rig after landing.
- The review stays locked to the standing rig; Space/W/L are disabled here so the other animation tests cannot interfere with pickup.

## Interaction

1. Pressing the creature begins a smooth lift.
2. The body gives a small startled rise and tilt; the head reacts, the wing gives a quick correction, the tail follows a fraction later, and the visible forepaws tuck upward.
3. The carried state then switches to independent hover animation layers.
4. The visual follows the finger with a small amount of smoothing. Two gentle, unsynchronised motion waves add a little float to the overall sprite.
5. The existing ground shadow is detached from the visual and remains on the ground anchor. It follows the projected ground position, widening and softening slightly as the drake rises.
6. Releasing commits the final ground position; the forepaws unfold and the drake settles back into the approved standing pose.

## Godot-only rigging

The carried state uses the same Godot 2D `Skeleton2D`, `Bone2D`, `Polygon2D` and `AnimationPlayer` rig as the standing, lying and walking proofs.

Five additional `AnimationPlayer` layers run only while the creature is carried:

- **Body float:** irregular bob rhythm, slight counter-tilt and gentle breathing
- **Head glances:** short curious looks in different directions, with rests between them
- **Wing flicks:** occasional small corrections rather than continuous flapping
- **Tail balance:** slower counter-sway with a delayed twitch
- **Forepaw tucks:** both visible front paws stay lifted and make small asynchronous kick/relax motions

The layers have different loop lengths and internal timing, so the movements do not line up into one repetitive cycle. Every layer begins on the carried-pose key, avoiding a snap when the pickup reaction gives way to the hover idle. A separate pickup transition blends from the exact live standing pose into the carried pose. On release, the hover layers pause and the bones animate back to the standing rest values before the original grounded idle layers resume.

The artwork remains one weighted textured mesh. These are controlled deformations of its existing influence regions, not newly authored limb cutouts. Inspect the front paws, shoulder/wing junction and tail root for stretch artifacts during runtime review.

## Prototype tuning

- Visual lift: 36 px
- Lift transition: 0.28 s
- Carried-pose reaction: 0.52 s
- Landing transition: 0.30 s
- Follow response: 18
- Global hover bob: two small, unsynchronised waves
- Shadow scale at full lift: 1.30x
- Shadow alpha at full lift: 0.70x

These values are experimental. The first review should prioritize the creature's personality and readability over exact numbers.

## Non-destructive boundary

Only the following interaction-specific files are added on this branch:

- `scenes/tests/forest_drake_interaction_review.gd`
- `scenes/tests/forest_drake_interaction_review.tscn`
- `docs/FOREST_DRAKE_INTERACTION_V2.md`

The walking-proof base files are inherited from `experiment/forest-drake-walking-proof-v1` and are not edited here. Main gameplay, world movement, grid projection, creature data and source PNGs remain untouched.

## Runtime review checklist

- Does the drake visibly react to the pickup before settling into its hover?
- Are the tucked forepaws clear at the actual display size?
- Do the curious head glances feel intentional rather than jittery?
- Do the wing flicks and tail counter-sway add personality without looking like flapping?
- Do the animation layers feel asynchronous and organic?
- Does the shadow remain correctly aligned to the ground projection?
- Does the drake return cleanly to its original standing idle on release?

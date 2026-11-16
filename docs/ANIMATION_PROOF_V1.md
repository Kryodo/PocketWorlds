# Pocket Worlds — Animation Proof V1

## Purpose

An isolated review scene for the first Forest Drake idle animation and the newly uploaded painterly ground/tree assets. It does not replace the main scene, gameplay, live 96x48 projection, or any approved source PNG.

## Run

Open scenes/tests/animation_proof_review.tscn in Godot 4.7 and press **F6**.

## Included assets

- art_inbox/ground/Grass_Base_1024x512.png
- art_inbox/ground/Grass_Dirt_1024x512.png
- art_inbox/vegetation/Tree_01_1024.png
- art_inbox/creatures/ForestDrake_Static_1024.png
- art_inbox/creatures/ForestDrake_Idle_Sheet_1024.png

The ground board is 7x5 cells using the isolated candidate Ground Cell Unit of 128x64. The source ground images are displayed at 0.125 scale. One central cell uses the integrated dirt-patch tile; all other cells use the base grass tile.

The tree is initially fitted to 4.2 GCU of visible height. The creature is initially fitted to 1.75 GCU of visible height. These are review values, not final asset-definition or collision footprints.

## Dragon animation

The idle sheet is sliced as four 512x512 frames in reading order: top-left, top-right, bottom-left, bottom-right.

The frames are loaded into a runtime SpriteFrames resource and played as a looping idle animation. Default playback is 4 FPS.

The static Drake is placed at the same ground anchor and display height for direct comparison.

### Controls

- **Space:** toggle between the static reference and the animated idle.
- **1:** play at 2 FPS.
- **2:** play at 4 FPS.
- **3:** play at 6 FPS.
- **R:** restart the idle loop.

## Transparency diagnostics

The review script reads the PNGs into runtime Image objects and prints their detected alpha mode and visible bounds.

For the tree and static Drake only, if all four canvas corners are opaque and nearly the same colour, the script removes that uniform corner matte in memory. The source PNGs are not modified. Existing alpha is otherwise preserved.

The same uniform-corner test is applied independently to each animation frame. If a frame has an opaque, non-uniform background, the script prints a warning; it does not attempt an unreliable automatic key. Such a frame should be cleaned in Photoshop and re-exported as transparent PNG.

Ground images are not automatically colour-keyed because their grass palette must not be damaged. Their alpha should already be transparent outside the diamond.

## Layout

- Background: neutral deep green for checking transparent edges.
- Ground: 7x5 candidate 128x64 diamond grid, centred in the 1280x720 review viewport.
- Tree: rear-left of the ground patch.
- Drake: front-right, with static/animated toggle.
- All world sprites share a Y-sorted parent. Each object's node position is its ground-contact anchor, independent of the full sprite canvas.

## Non-destructive boundary

All changes are limited to this test scene, script and document. Existing gameplay scripts, main scene, camera controller, grid projection, save data, art definitions and uploaded PNGs are untouched.
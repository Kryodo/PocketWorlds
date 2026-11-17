# Pocket Worlds — Animation Proof V2

## Purpose

An isolated review scene for the Forest Drake 16-frame idle animation and the uploaded painterly ground/tree assets. It does not replace the main scene, gameplay, live 96x48 projection, or any approved source PNG.

## Run

Open `scenes/tests/animation_proof_review.tscn` in Godot 4.7 and press **F6**.

## Included assets

- `art_inbox/ground/Grass_Base_1024x512.png`
- `art_inbox/ground/Grass_Dirt_1024x512.png`
- `art_inbox/vegetation/Tree_01_1024.png`
- `art_inbox/creatures/ForestDrake_Static_1024.png`
- `art_inbox/creatures/ForestDrake_Idle_Sheet_1024_16_Frames.png`

The ground board is 7x5 cells using the isolated candidate Ground Cell Unit of 128x64. The source ground images are displayed at 0.125 scale. One central cell uses the integrated dirt-patch tile; all other cells use the base grass tile.

The tree is initially fitted to 4.2 GCU of visible height. The Forest Drake defaults to 1.25 GCU (80 world pixels) and can be adjusted at runtime for comparison. These are review values, not final asset-definition or collision footprints.

## Drake animation sheet

The 1024x1024 idle sheet is sliced as 16 frames in a 4x4 grid. Each frame is 256x256 pixels and is loaded into a runtime SpriteFrames resource in reading order, left-to-right and top-to-bottom.

Default playback is 8 FPS (a 2-second 16-frame cycle). The static Drake is placed at the same ground anchor and display height for direct comparison.

A separate soft contact shadow is generated procedurally at runtime and remains stationary beneath the creature. It is not baked into the animation frames.

### Controls

- **Space:** toggle between static reference and animated idle.
- **1:** 6 FPS.
- **2:** 8 FPS.
- **3:** 12 FPS.
- **4:** display height 1.0 GCU (64 px).
- **5:** display height 1.25 GCU (80 px).
- **6:** display height 1.5 GCU (96 px).
- **R:** restart the idle loop.

## Transparency diagnostics

The review script inspects each 256x256 frame's alpha mode and four corner colours. It only removes a frame background automatically when its four corners indicate one nearly uniform matte. It does not attempt aggressive per-pixel background removal when the background is non-uniform, because that could damage the creature's pale belly, green edges, horns or wings.

If the running scene shows coloured blocks or image remnants around the Drake, inspect the Output panel for each frame's alpha mode and corner samples. Clean the sheet in Photoshop and re-export a transparent PNG rather than relying on a broad colour key.

The tree and static Drake use the same cautious uniform-corner matte cleanup in memory. Original PNGs are not modified. Ground images are not colour-keyed.

## Layout

- Background: neutral deep green for transparency and edge inspection.
- Ground: 7x5 candidate 128x64 diamond grid, centred in the 1280x720 review viewport.
- Tree: rear-left of the ground patch.
- Drake: front-right, with static/animated toggle and separate fixed shadow.
- Ground tiles render below the object layer. The tree, shadow and Drake are Y-sorted as world objects.

## Non-destructive boundary

All changes are limited to this test scene, script and document. Existing gameplay scripts, main scene, camera controller, grid projection, save data, art definitions and uploaded PNGs are untouched.
# Pocket Worlds — Animation Proof V3

## Purpose

An isolated review scene comparing the Forest Drake's static artwork, 16-frame sprite sheet and an experimental multi-part skeletal idle. It also displays the painterly ground/tree assets. It does not replace the main scene, gameplay, live 96x48 projection, or any approved source PNG.

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

## V2 single-chest rig (superseded)

The first skeletal proof rendered the approved static Drake as one textured `Polygon2D` mesh bound to a `Skeleton2D`, using a 33x33 UV grid and a fixed root plus one chest influence. It established that the source artwork could be deformed in Godot, but its breathing was initially too subtle. The V3 rig below replaces this two-bone setup. The original source PNG continues to be read and matte-cleaned in memory; it is not modified.

## Drake sprite-sheet comparison

The 1024x1024 idle sheet is sliced as 16 frames in a 4x4 grid. Each frame is 256x256 pixels and is loaded into a runtime SpriteFrames resource in reading order, left-to-right and top-to-bottom.

Default playback is one frame every 0.15 seconds (approximately 6.67 FPS; a 2.4-second 16-frame cycle). The static Drake is placed at the same ground anchor and display height for direct comparison.

A separate, compact, low-opacity contact shadow is generated procedurally at runtime. Its centre is placed at the creature's ground-contact anchor with a slight upward offset, and it remains stationary beneath the feet. It is not baked into the animation frames.

### Controls

- **Space:** cycle between skeletal idle, 16-frame sprite idle and static reference.
- **4:** display height 1.0 GCU (64 px).
- **5:** display height 1.25 GCU (80 px).
- **6:** display height 1.5 GCU (96 px).
- **R:** restart all active rig layers, or restart the sprite-sheet animation when that comparison is selected.

## Transparency diagnostics

The review script inspects each 256x256 frame's alpha mode and four corner colours. It only removes a frame background automatically when its four corners indicate one nearly uniform matte. It does not attempt aggressive per-pixel background removal when the background is non-uniform, because that could damage the creature's pale belly, green edges, horns or wings.

If the running scene shows coloured blocks or image remnants around the Drake, inspect the Output panel for each frame's alpha mode and corner samples. Clean the sheet in Photoshop and re-export a transparent PNG rather than relying on a broad colour key.

The tree and static Drake use the same cautious uniform-corner matte cleanup in memory. Original PNGs are not modified. Ground images are not colour-keyed.

## Layout

- Background: neutral deep green for transparency and edge inspection.
- Ground: 7x5 candidate 128x64 diamond grid, centred in the 1280x720 review viewport.
- Tree: rear-left of the ground patch.
- Drake: front-right, with skeletal/sprite/static comparison and separate fixed shadow.
- Ground tiles render below the object layer. The tree, shadow and Drake are Y-sorted as world objects.

## Non-destructive boundary

All changes are limited to this test scene, script and document. Existing gameplay scripts, main scene, camera controller, grid projection, save data, art definitions and uploaded PNGs are untouched.

## Skeletal breathing visibility adjustment

The skeletal idle was initially too subtle at the creature's in-game scale: peak chest scale was only 1.035 × 1.025 and rotation was -0.012 radians. The proof now deliberately exaggerates the peak chest scale to 1.16 × 1.12 and rotation to -0.05 radians, with intermediate easing keys. This is a diagnostic amplitude, not a final creature-animation target. First verify that the chest visibly deforms while the ground anchor remains fixed; then reduce the motion toward a natural idle.


## V3 — Independent multi-part idle proof

The skeletal test now uses one 49×49 textured mesh and five weighted influences:
- Fixed `RootAnchor`, which retains the ground reference and the foot area
- `TorsoBone`, for a visible inhale/exhale, slight vertical lift and settling motion
- `HeadNeckBone`, for occasional head turns
- `WingBone`, for intermittent wing adjustments
- `TailBone`, for a slower independent sway

The four animated parts use separate looping AnimationPlayers, so they can run simultaneously without being forced into one shared cycle. Their loop durations differ deliberately: body 3.6s, head 6.3s, wing 7.8s and tail 5.1s. This causes their movements to overlap at different moments instead of repeating as one synchronized gesture.

The mesh influence regions are smooth elliptical fields with normalized weights. These pivot locations and influence regions are estimates on the existing flat source image, not final hand-painted weights. Watch especially for unwanted stretching around the neck, shoulder/wing junction, tail root and hind leg.

The current proof remains a standing idle. It does not yet prove lying down, getting up or walking. Those need separate pose design and likely a hybrid of hand-prepared cutout parts, skeletal movement and generated/painted key poses. Do not treat this rig as a production-ready universal creature rig.

### V3 test

Open `scenes/tests/animation_proof_review.tscn` with Godot 4.7 and run it with F6. The default RIG mode now shows the independent body, head, wing and tail layers together. Press Space to compare the original 16-frame sheet and static image; press R to restart the current rig layers. Use 4/5/6 to compare the three display sizes.

Runtime validation is still required. Inspect both the perceived life and deformation artifacts; if one region distorts badly, adjust that region's influence field or replace it with a separate cutout layer rather than increasing the movement.

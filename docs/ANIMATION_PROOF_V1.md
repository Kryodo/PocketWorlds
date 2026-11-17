# Pocket Worlds — Animation Proof V6 + Walking Proof V1

## Purpose

An isolated review scene comparing the Forest Drake's static artwork, 16-frame sprite sheet, approved multi-part standing idle, and an experimental stand/lie posture system. It also displays the painterly ground/tree assets. It does not replace the main scene, gameplay, live 96x48 projection, or any approved source PNG.

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
- **W:** toggle the experimental in-place walk cycle on/off. The Drake blends back to standing idle when stopped.
- **L:** toggle between standing and lying, including the transitions. L is ignored while the walk cycle is active.
- **R:** reset the rig to the approved standing idle, or restart the sprite-sheet animation when that comparison is selected.

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


## V3 head-look refinement

Runtime feedback confirmed the body, wing and tail cycles worked well and that the overall breathing remained grounded. The first head pass looked too much like inflation rather than a deliberate look-around gesture.

The likely cause was the hierarchy: HeadNeckBone, WingBone and TailBone were children of TorsoBone, while TorsoBone was being scaled for breathing. Child bones inherit their parent's transform, so the head inherited chest expansion even though the head animation itself had no scale track.

The hierarchy now uses a separate BodyMotionBone beneath the fixed RootAnchor. TorsoBone, HeadNeckBone, WingBone and TailBone are siblings beneath BodyMotionBone. The shared body lift/settle is inherited by all, but the torso's breathing scale is isolated to TorsoBone and no longer scales the head/wing/tail.

The head influence region now has a broad high-weight core with a softer outer feather, reducing stretch across the face. The head idle uses gentle left/right rotation plus a very small horizontal offset, with pauses and no head scale track. Body, wing and tail animation values are otherwise unchanged.

Re-test at the same display scale as V3. Confirm that the head reads as looking around and retains its shape, while the successful body/wing/tail motion remains intact. The hierarchy and weighting are still approximations on one flat image; if junction artefacts remain, the next refinement should be a separately prepared head cutout rather than increasingly complex weight maps.


## V4 — Standing, lying down and getting up

The posture experiment is layered on top of the existing rig in this isolated branch. It does not replace or edit the four approved standing-idle animations (body, head, wing and tail), and it does not add a new deformation influence to the mesh.

Press **L** while the RIG view is active:
- Standing → lying: the upper body settles first; the torso compresses toward a low resting shape; the wing folds, the tail relaxes and the head lowers last.
- Lying idle: a slower, lower breathing cycle continues, with occasional subtle head, wing and tail adjustments.
- Lying → standing: the head and wing recover first, followed by the torso and whole upper-body lift; the original independent standing-idle layers resume when the transition completes.
- During either transition, the standing/lying idle layers are paused. The transition animation is built from the bones' current values, so it starts from the actual point in the idle cycle rather than snapping to its first frame.
- Press **R** to return directly to the approved standing idle. Switching to the sprite-sheet or static comparison also resets the rig to standing.

The current posture is intentionally an initial deformation-only proof using the existing single-image mesh. It tests whether the body lowering, torso compression, head placement and wing/tail settling read as a believable lie-down and get-up at the target display size. At the V4 stage the mesh did not have separately weighted leg joints, so that version was not yet a final quadruped floor-contact solution. V5 below adds experimental foreleg influences. Inspect the feet, belly, neck and wing junction closely; do not preserve a pose that reads as a body squash or causes foot sliding. If the silhouette needs clearer limb folding, the next step should be a small set of independently prepared leg/limb cutouts or an additional articulation pass, not simply stronger scaling.

Runtime visual validation is required in Godot 4.7. This branch has not been confirmed in the editor; treat the numeric pose values as test parameters, not approved final animation values.


## V5 — Lying silhouette, foreleg reach and contact shadow

This iteration responds to the first in-engine posture review:

- The resting silhouette now lowers the upper-body group farther toward the ground and compresses the torso more, so it should read less like a crouch/duck.
- Two additional, independently weighted foreleg influences were added to the same 49x49 mesh. They are anchored to the fixed root rather than the descending torso. During lie-down they move slightly forward and rotate inward by about 4.3 degrees in opposite directions; during get-up they retract before the chest rises.
- The foreleg influence centres and pivots are estimated from the source image, not hand-authored limb cutouts. They are a deliberately small test adjustment and need visual inspection for mesh stretching or incorrect influence placement.
- The contact shadow is now a soft 128x64 projected oval with roughly the same 2:1 screen-space proportion as the isometric ground diamond. Its previous 96x20 texture and 0.18 maximum alpha produced a narrow, faint strip. The revised shadow is wider, deeper, darker and linearly filtered, and its screen-space footprint scales with the selected Drake display height.

### Transition continuity fix

The earlier transition code called `stop()` on the active idle players and the previous posture-transition player before sampling the current bones. Godot's `AnimationPlayer.stop()` defaults to `keep_state = false`, so stopping the previously completed posture transition could re-evaluate its first pose. This was especially visible when getting up.

The transition now pauses the active idle layers, samples their still-visible transforms, and calls `stop(true)` on the previous transition player so its visual state is not reset. At the end of get-up, the standing idle layers are deliberately restarted at their first keys, which match the standing rest pose.

Runtime validation is still required in Godot 4.7. Check especially the foreleg pivots/weights, whether the chest now sits low enough, and whether the larger isometric shadow reads naturally rather than as a dark oval.


## V6 — Foreground paw integrity and anchored contact shadow

The V5 review was positive overall. Two small issues remained: the outer nail on the foreground/right front paw was deforming too much, and the shadow was too faint and not aligned convincingly with the Drake.

- The foreground/right foreleg now has its own narrower influence region, shifted slightly toward the paw. Its weight field uses a broad full-weight core so the paw and three nails move more like one coherent shape instead of falling through a partial-weight deformation zone. The other front leg's field is unchanged.
- The shadow is now a child of the rig root, behind the skinned mesh. It shares the Drake's exact root transform and display scale instead of being a separate world-space sprite. Its local offset is moved toward the estimated cluster of ground-contact points, rather than centring it on the lowest point of the full artwork.
- The procedural shadow now combines a broad soft oval with a stronger central contact core. It keeps a 2:1 isometric footprint, a darker green-black tint and a higher but still feathered alpha.

The foreground paw weights and shadow offset are still estimated from the 1024px source artwork. Runtime validation in Godot 4.7 is needed to confirm that the outer nail remains intact and that the shadow sits under the paws/body on the diamond tile at 1.0, 1.25 and 1.5 GCU. Avoid increasing the whole-leg motion if the nail still needs adjustment; refine only the foreground paw's influence centre/radii or its local weight field.


## V1 — Experimental in-place walking proof

The walking test is intentionally layered onto the approved V6 rig without changing its mesh topology, bone weights, source artwork, standing-idle animations, lying idle or posture-transition values.

Press **W** in RIG mode:
- The four approved idle layers pause at their current visible transforms.
- A 1.2-second looping gait is generated from those exact transforms, avoiding an initial pose snap.
- The two foreleg influences already present in the single-image mesh swing in alternating phases. Each uses a small forward/reach offset and a lift/recovery arc.
- The body adds a restrained two-beat vertical pulse and slight counter-rotation. The chest compresses subtly, the head counterbalances, the wing reacts lightly and the tail sways against the gait.
- Press **W** again to blend back to the standing rest pose over 0.72 seconds, then restart the four approved independent idle layers.

This is a **walking-in-place deformation test**, not a complete quadruped locomotion solution. The approved single-image mesh has independently weighted regions for only the two visible forelegs. The rear legs do not yet have independent joints or dedicated painted cutouts, and the Drake does not translate across the ground. Their behaviour is therefore a known limitation rather than something this proof attempts to hide by adding speculative weights that could damage the approved standing and lying silhouettes.

### What to inspect

Run the scene with F6 and compare the gait at 1.0, 1.25 and 1.5 GCU. Watch:
- whether the front feet alternate clearly without stretching the claws or pulling the belly;
- whether the body bounce feels like weight transfer rather than repeated bobbing;
- whether the head, wing and tail counter-motion stays restrained;
- whether W starts and stops without a visible pose snap;
- whether the stationary rear limbs make the result read as an incomplete crawl.

The scene remains an isolated experiment. No gameplay, world movement, creature AI, approved idle/rest animation tracks or original PNGs are changed. The current foreleg influences are deliberately left intact. If the rear limbs make the gait feel incomplete, the next step is art preparation in Qwen/Photoshop: isolate the limb shapes with clean overlaps/occlusion and add dedicated leg layers or a small set of key poses, then keep Godot responsible for timing, transitions and secondary motion.

Runtime validation in Godot 4.7 is required. This implementation has not been run in the editor as part of this change.

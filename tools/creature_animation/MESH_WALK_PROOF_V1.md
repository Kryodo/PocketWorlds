# Forest Drake — Full-Image Mesh Walk Proof V1

This is an isolated Godot test of a front-facing 3/4 walk using the cleaned
ForestDrake_RigMaster_SW34_1024.png master as one complete texture.

## What this test proves

- One transparent PNG is mapped to a dense Polygon2D grid.
- Skeleton2D / Bone2D weights deform the complete image.
- Four leg regions receive separate movement phases.
- Torso, head, wing and tail receive smaller secondary motion.
- The contact shadow is a separate Godot node, not baked into the artwork.
- No limbs are cut from the source and no hidden artwork is reconstructed.

The bone pivot and influence regions are initial coordinate estimates for the
new southwest 3/4 master. They are deliberately kept at the top of
forest_drake_mesh_walk_proof.gd so they can be calibrated after visual review.

## Open the test

1. Open the Pocket Worlds project in Godot 4.7.
2. Open scenes/tests/forest_drake_mesh_walk_proof.tscn.
3. Press F6 to run the current scene.

## Controls

- Space — play / pause
- N — pause and advance by one eighth of the cycle
- Up / Down — adjust playback speed
- R — reset to the beginning and resume

## Known limitations of this first proof

This is intentionally a one-bone-per-limb deformation test, not the final
production rig. Since the original artwork is a single flattened image, the
mesh cannot create genuine occlusion changes or reveal pixels hidden behind
another limb. It may stretch pixels around shoulders, hips, paws or the belly.
The result determines whether the new perspective is sufficient for convincing
walking without separating the artwork. If not, the next iteration can use a
hybrid approach: retain the full-image body mesh and cut out only limbs that
need independent overlap.

The old animation_proof_review.tscn and its approved standing / lying idle
layers are not modified by this experiment.

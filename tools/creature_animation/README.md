# Qwen Creature Animation Workflow V1 — Forest Drake

This is an isolated art-production toolset. It does not change the approved Forest Drake idle/rest rig, source artwork, gameplay or Godot world projection.

## Goal

Generate a walking animation while keeping the creature's identity, scale and ground pivot consistent. The workflow accepts either:

1. **One Qwen sprite sheet** — default 4x4 layout, 16 frames.
2. **Individual Qwen generations** — one full-canvas PNG per pose.

Both routes pass through the same frame extraction, matte validation, body-registration and sprite-sheet assembly tool. The workflow does not assume that individual generations are better; test the 4x4 sheet first because a single generation can preserve character consistency across frames.

## Fixed Forest Drake reference geometry

| Property | Value |
|---|---:|
| Master artwork | art_inbox/creatures/ForestDrake_Static_1024.png |
| Source canvas | 1024 x 1024 |
| Source sprite-root pivot | **(535, 850)** |
| Contact-shadow centre | (505, 792) |
| Contact-shadow offset from root | (-30, -58) |
| Output frame | 256 x 256 |
| Sprite-root pivot inside each output frame | **(133.75, 212.5)** |
| Contact-shadow centre inside each output frame | (126.25, 198) |
| Default sheet | 4 columns x 4 rows |
| Default animation rate | 8 FPS |

The sprite-root pivot comes from the approved V6 rig's existing ground anchor: the source artwork's estimated visible-bounds centre-bottom is (535, 850). The accepted contact shadow is a separate child at local offset (-30, -58), so its centre is (505, 792). At 256px output size those become root pivot (133.75, 212.5) and shadow centre (126.25, 198). Keep these two references distinct: the root drives world movement; the shadow is a visual contact patch. Treat the coordinates as the current Forest Drake calibration, not a universal creature rule.

**The pivot is the ground-plane reference, not the lowest opaque pixel.** During a walk the feet deliberately lift and extend, so the lowest pixel changes from frame to frame. Never align on each frame's bottom edge.

## 1. Generate the templates

From the Pocket Worlds repository root:

~~~powershell
py -m pip install -r tools/creature_animation/requirements.txt
py tools/creature_animation/generate_templates.py
~~~

Generated files are written to:

tools/creature_animation/generated/forest_drake_walk_v1/

Important outputs:

- **ForestDrake_Walk_ControlGuide_16.png** — 4x4 simplified quadruped pose guide for a single 16-frame ControlNet generation.
- **poses_16/pose_00.png ... pose_15.png** — 16 separate 1024x1024 pose guides, for individual generation tests.
- **ForestDrake_FrameAlignmentOverlay_256.png** — target pivot and isometric contact ellipse for visual inspection.
- **ForestDrake_CanvasPivotOverlay_1024.png** — the same overlay at source-canvas size.
- **ForestDrake_MasterPivot_Reference.png** — inspection copy of the approved artwork with the proposed pivot and 2:1 ground-plane ellipse drawn on top.

The overlays are **inspection aids**. The red cross marks the sprite-root pivot; the green ellipse marks the separate contact-shadow footprint offset from the root. Do not feed either overlay to Qwen as part of the final creature artwork, and do not import them into the game. The ControlGuide images contain only simplified body/limb construction lines on white.

The current pose guides are a first geometric scaffold. They indicate a three-quarter quadruped, four distinct limb chains and a phase-shifted walking cycle; they are not final anatomical drawings. Inspect the guide sheets before using them. If the leg order or paw positions do not match the Drake's actual visible anatomy, correct the guide coordinates in generate_templates.py first.

## 2. Recommended ComfyUI / Qwen graph

Use the existing Qwen Image 2.1 INT8 workflow and the installed T8 Qwen Image 2.1 Fun ControlNet Union nodes.

**Reference / identity input**

- Load the approved ForestDrake_Static_1024.png into **Qwen 2.1 UNION Image Reference Encode → reference_image**.
- Leave reference_image_2 and reference_image_3 empty initially. Do not feed one generated frame as the next frame's only identity reference.
- Use the relevant generated pose guide as the **ControlNet conditioning image**.

**Model / ControlNet chain**

1. Load Diffusion Model: qwen_image_2.1_int8_convrot.safetensors.
2. Load CLIP: qwen3vl_8b_int8_convrot.safetensors, type qwen_image.
3. Load VAE: qwen_image_2.1_vae_bf16.safetensors.
4. Load the T8 Qwen Image 2.1 Fun ControlNet Union checkpoint.
5. Apply the UNION ControlNet to the model. Start with **Scribble** for the simple limb construction guides; try **Lineart** only if Scribble does not communicate the limb layout clearly.
6. Start with ControlNet strength **0.68**, start **0.0**, end **0.85**. Treat these as first-test values, not final universal settings.
7. Use **Qwen 2.1 UNION Image Reference Encode** for the approved creature reference. Connect its positive, negative and latent outputs to KSampler. It replaces the standard text-encode/empty-latent path in this reference workflow.
8. KSampler starting settings: **40 steps, CFG 1.5, Euler, Simple, denoise 1.0**.
9. Decode with the Qwen VAE. Save full-resolution PNG output.

The T8 node names in this project are the installed Qwen Image 2.1 UNION nodes: **Load Qwen Image 2.1 UNION**, **Apply Qwen Image 2.1 UNION**, and **Qwen 2.1 UNION Image Reference Encode**. Keep the UNION model application in the model path; do not confuse it with the reference-image encoder.

### Prompt for the 4x4 sheet

~~~text
Create one clean 4-by-4 sprite sheet showing sixteen consecutive frames of the Forest Drake walking slowly in place.

Use the supplied pose guide to determine the four leg positions and their order in every cell. Each cell contains one complete creature pose. Preserve the approved reference artwork; do not redesign or reinterpret the creature. Keep the torso/head registration consistent between cells while the legs move through a natural staggered quadruped walk. Show clear planted-foot and lifted-foot phases with readable paw silhouettes and all toes/claws intact.

Keep every frame completely inside its own equal-sized cell and at the same scale. Do not add cell borders, labels, numbers, text, scenery, props, a cast shadow, motion trails or decorative effects. Use a perfectly uniform saturated magenta background (#D632E8) in every cell for later alpha extraction.
~~~

The prompt deliberately describes only the frame layout, pose, registration and matte requirements; the reference image already supplies the approved art style and character design.

### Prompt for individual frames

Use the same approved master reference, the same Qwen graph, same canvas and the corresponding pose_XX.png guide for each frame. Keep the same seed for the first comparison batch; change only the pose guide / frame index.

~~~text
Create one walking-cycle frame of the Forest Drake. Follow the supplied quadruped pose guide for the precise limb positions. Preserve the approved reference artwork. Keep the torso/head registration consistent; change the leg positions for this phase of the walk, with only a small accompanying weight response. Keep all four legs distinct and retain complete paws and claws. No crop, zoom, camera change, scenery, props, text or guide lines in the finished artwork. Use a perfectly uniform saturated magenta background (#D632E8) for later alpha extraction.
~~~

## 3. Matte / transparency

The aligner preserves an existing alpha channel. If Qwen returns a truly uniform matte, it can remove that matte automatically from the four corner samples.

If the corners are visibly different, or the background contains patches/stripes, the tool stops rather than guessing and eating into the pale belly, horns or wing membrane. In that case use the installed PixelPro matte workflow in ComfyUI:

- Build a trimap with **Mask: Trimap Builder**.
- Refine with **Mask: Alpha Matte**.
- Clean edge colours with **Mask: Decontaminate Colors** and/or **Color: Defringe**.
- Save a transparent PNG, then run the aligner on that PNG.

The output must have a clean alpha channel. Do not use the purple/magenta key on pixels that belong to the creature. Keep the original master reference unchanged.

## 4. Align and assemble

### Route A — one 4x4 sprite sheet

~~~powershell
py tools/creature_animation/align_animation.py --sheet "art_inbox/creatures/generated/ForestDrake_Walk_Raw.png" --layout 4x4 --out "art_inbox/creatures/animation_work/ForestDrake_Walk_Aligned"
~~~

### Route B — sixteen individual full-canvas frames

Name them in order: frame_00.png, frame_01.png, ... frame_15.png.

~~~powershell
py tools/creature_animation/align_animation.py --frames-dir "art_inbox/creatures/generated/ForestDrake_Walk_Frames" --out "art_inbox/creatures/animation_work/ForestDrake_Walk_Aligned"
~~~

Both routes create:

- **ForestDrake_Walk_16_Aligned.png** — transparent 4x4 sprite sheet, ready for a Godot review scene.
- **frames/frame_00.png ...** — normalized individual frames.
- **alignment_preview.png** — contact sheet with the same pivot cross and projected ground ellipse over every frame.
- **alignment_offsets.csv** — auto-calculated body shifts plus optional manual corrections.
- **alignment_report.json** — registration scores and warnings.

The aligner resizes input canvases/cells to 256x256, removes only a verified uniform corner matte, and performs **translation-only body-core registration** inside the configured torso ROI. It does not align to the feet, because feet intentionally move. It does not scale frames independently, because independent scale changes can make the dragon pulse. The fixed sprite-root pivot stays at (133.75, 212.5) in every output frame; the separate green shadow reference is offset to (126.25, 198).

If the body's actual proportions differ strongly from the master, the registration score will be low. Inspect alignment_preview.png and alignment_report.json; do not blindly trust a low score. You can make small corrections in alignment_offsets.csv by changing manual_dx / manual_dy, then rerun with --offsets "path\to\alignment_offsets.csv". No Photoshop positioning is required.

For a diagnostic comparison without automatic translation, add --no-auto-register. For a non-uniform background that you have verified is one solid colour, you may pass --key-color "#D632E8"; the script still applies a soft edge threshold. Patchy backgrounds should go through PixelPro alpha extraction instead.

## 5. Acceptance checks before Godot

Do not import a sheet merely because the animation looks lively. First verify:

- All sixteen cells contain exactly one full creature.
- The torso/head scale and location do not jump between cells.
- Paws remain inside the cell and retain their full claws.
- No frame contains text, cell borders, duplicated limbs or stray background.
- The green contact-shadow ellipse keeps its fixed offset from the red root-pivot cross in every frame.
- The body-registration Dice score is reasonable and not flagged as weak.
- The cycle returns to a pose compatible with its first frame.

The 2:1 ellipse in the preview is a visual guide only. The production shadow remains a separate Godot world object at the creature's ground anchor; do not bake the shadow into every sprite frame.

## 6. Godot integration comes later

This first workflow stops at an aligned transparent sprite sheet and its review output. It does not replace the approved idle/rest rig or wire walking into gameplay.

After the frames pass visual review, the next isolated Godot experiment should:
- load the aligned 4x4 sheet as sixteen SpriteFrames frames;
- place its sprite root at the fixed ground pivot;
- keep the isometric contact shadow at that root;
- move the root through GridProjection.grid_to_world() / the existing 2:1 ground axes;
- synchronize travel speed with playback and planted-foot phases.

A sprite sheet generated in place still needs world-root locomotion and foot-plant timing. Alignment is a foundation, not a substitute for the movement controller.

## Important limitations of V1

- The pose guides are simple construction diagrams, not anatomy-certified final poses. Inspect and refine their four leg tracks against the actual Drake.
- Qwen may still alter anatomy, miss a paw, add grid artifacts or produce uneven backgrounds; ControlNet reduces freedom but does not guarantee correctness.
- Translation-only registration can stabilize small body-placement drift. It cannot repair changed anatomy or reconstruct missing pixels.
- The output frame size is 256px to match the existing V6 proof's 256x256 sprite-frame conventions. A higher-resolution output can be added after the first test proves the pose and alignment workflow.

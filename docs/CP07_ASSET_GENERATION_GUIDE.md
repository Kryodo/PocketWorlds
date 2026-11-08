# CP07 — 2D Asset Generation Guide

## Purpose and status

This guide defines the repeatable 2D image-generation and asset-preparation workflow for Pocket Worlds' starter artwork.

The production direction is Enchanted Hand-Painted 2.5D. See **docs/CP07_VISUAL_IDENTITY.md** for the artistic rules.

The technical platform and model are still subject to a local proof of concept. The current proposal is ComfyUI with a Qwen Image family model, evaluating GGUF quantization on the user's RTX 4090. Do not treat an exact checkpoint, release, quantization, ControlNet, transparency node or custom-node package as production-locked until it has been installed and tested.

**This is an image-generation workflow, not a 3D production pipeline.** Blender, 3D modelling, mesh creation and manually authored depth, silhouette or line-art maps are not requirements.

## 1. Scope: starter assets only

Generate only the artwork needed to validate the current Sanctuary and Whispering Woods prototype and the reusable asset workflow:

- A small ground and terrain sample.
- One representative asset from each important object scale and material category.
- Three starter structures and one cottage visual upgrade state, after calibration.
- One starter creature, first as a static design and later as a short animation test.
- Seven core item icons used by the current playable loop.

Do not create a complete forest, biome, creature, building, furniture, decoration or icon library in advance. Expand the inventory when gameplay requires it.

## 2. Proposed local generation environment

### ComfyUI

ComfyUI is the proposed local workflow environment because it can save and reuse generation graphs. It should let us keep model loading, prompting, reference conditioning and image output reproducible.

The aim is to operate a small number of proven workflows. Do not install large collections of checkpoints, custom nodes or experimental extensions before a specific test requires them.

### Model selection

The Qwen Image family is the leading starting candidate for the local generation proof. The exact model release and checkpoint must be selected after checking current ComfyUI workflow support, output quality for our art direction, image-to-image/reference capabilities, memory use and license.

A checkpoint that already produces strong dimensional fantasy artwork is preferable to trying to force an unsuitable base model into the desired style.

### GGUF

GGUF quantization is preferred for memory-efficient loading when the selected model release is supported by a compatible and maintained ComfyUI-GGUF workflow.

- Q6_K may be included as the first quality-oriented quantization to benchmark.
- A Q5 variant may be compared if additional memory headroom is useful.
- Do not assume every Qwen release, text encoder, ControlNet or LoRA is available in a compatible GGUF form.
- Compare actual image quality, stability, speed and peak memory on the RTX 4090 before deciding.
- GGUF reduces model-weight memory requirements; it does not guarantee faster generation or eliminate memory use from text encoders, VAEs, control models or intermediate activations.

Record the exact model file, quantization, loader and workflow version used for any approved test.

### Reference conditioning and LoRAs

Start with ordinary text prompting and approved visual references. Use the same master style reference for related generation batches.

A style LoRA is a later option, not a prerequisite. Consider training one only after we have a sufficiently coherent, approved set of artwork. Do not train a style LoRA from mixed or unapproved examples.

If a recurring creature or building needs identity consistency, use dedicated approved reference images and suitable reference conditioning. A general style LoRA does not guarantee exact character or object identity.

### ControlNet

ControlNet is optional. It is not required for normal asset creation.

Use it only when a repeatable test demonstrates a clear benefit, such as better adherence to a supplied reference composition or perspective. Prefer an existing compatible control workflow that uses a readily available reference. Do not create a process that requires the user to draw or prepare depth, silhouette, normal or line-art maps for every object.

The AI output still needs visual review. Structural conditioning guides an image model; it does not guarantee exact pixel geometry or exact footprint compliance.

### Transparency

Transparency is a separate technical validation.

LayerDiffusion must not be assumed compatible with the chosen Qwen workflow. Test the exact model and node combination before adopting it. Other possibilities include a model that natively produces usable alpha/layers or a separate foreground-segmentation and matte-cleanup step.

A checkerboard-looking background is not proof of an alpha channel. Verify the PNG's actual alpha data and inspect its edges over light, dark and saturated backgrounds.

If a clean transparent output is not reliable, use a consistent flat contrasting background and a tested extraction/matting workflow. Preserve the original generated image and any correction masks.

### Technical references

- ComfyUI documentation: https://docs.comfy.org/
- ComfyUI-GGUF project: https://github.com/city96/ComfyUI-GGUF
- LayerDiffusion project: https://github.com/lllyasviel/LayerDiffuse

These are starting references, not a promise that every model, node or extension combination is compatible. Recheck installation instructions, supported architectures and licenses when choosing the exact workflow.

## 3. Reference package used for generation

Keep three types of reference separate:

| Reference | What it communicates |
|---|---|
| Pocket Worlds visual identity | Rendering style, surfaces, lighting, colour, atmosphere and detail hierarchy |
| Grid and footprint board | 2:1 dimetric projection, candidate cell dimensions and relative logical ground footprints |
| Category-specific references | The exact subject, construction, material and variations required for that batch |

The visual identity reference does not define object size. The footprint board does not define the art style. Do not expect a single image to communicate both reliably.

The 128 × 64 grid is a candidate authoring standard only. The live project remains 96 × 48 until a separate grid decision is made. Do not describe the candidate as an implemented gameplay change.

## 4. Prompt and generation principles

Prompts should be short, specific and reference-led. Avoid enormous prompts that mix artistic direction, grid mathematics, extraction instructions and gameplay implementation.

Each generation request should state:

1. **Subject:** the exact asset and its role in the world.
2. **Visual identity:** Enchanted Hand-Painted 2.5D, guided by the approved style reference.
3. **Construction and materials:** the important forms and materials that make this subject distinctive.
4. **View and lighting:** the established 2.5D view and the lighting consistent with the reference batch.
5. **Scale cue:** the intended logical footprint and relative scale, supported by the separate footprint image.
6. **Presentation:** isolated asset or clean category sheet, fully visible and clearly separated.
7. **Background:** true transparent output when the selected workflow supports it; otherwise a uniform contrasting background suitable for extraction.

Do not rely on the model to calculate a footprint from text. Footprints, anchors and visual bounds are measured and validated separately during Godot review.

### Keep the composition simple

- Prefer one isolated asset per image when a subject is complex or extraction is difficult.
- Use category sheets only when objects remain distinct, fully visible and easy to extract.
- Keep ground artwork separate from object artwork.
- No UI, text, labels, numbers, borders, decorative frames or unrelated props.
- No ground tile, diamond pedestal or scene fragment attached to an individual object.
- Keep natural contact shadow close to the object; it must not become a large detached halo.
- Do not crop important leaves, roots, roof edges, branches, feet or shadows.
- For multiple objects, leave generous empty separation between their visible bounds.

### Creature animation

Do not generate the animation sheet before the static creature design is approved.

The planned test is one creature with three four-frame loops: idle, walk and one signature interaction. The eventual sheet is 4 columns × 3 rows with 12 equal frame cells. Keep the same camera, lighting, proportions, ground baseline and frame canvas. The exact pixel dimensions are selected only after static scale calibration.

## 5. Scale, footprint and image dimensions

The logical footprint describes world occupancy, not the required sprite canvas dimensions.

Candidate 128 × 64 projected ground bounds:

| Footprint | Projected bounds |
|---|---:|
| 1 × 1 | 128 × 64 |
| 1 × 2 | 192 × 96 |
| 2 × 2 | 256 × 128 |
| 2 × 3 | 320 × 160 |
| 3 × 3 | 384 × 192 |

A tree with a 2 × 2 ground footprint may have a much larger canopy. A cottage with a 3 × 3 footprint may have roof overhangs. A tall object may use a large transparent canvas. Do not force all images into tile-sized canvases.

For ground tiles only, a 256 × 128 source image rendered at 0.5 scale is a candidate 2× source size for a 128 × 64 cell. Keep this provisional until the candidate grid is approved.

For every sprite, record its visible bounds and actual ground-contact anchor independently from its canvas centre and logical footprint.

## 6. Extraction and image preparation

Keep the original generated output unchanged. Create working copies for extraction and correction.

The basic workflow is:

1. Verify whether the source actually contains alpha.
2. If it does, inspect alpha edges for holes, fringe and partially transparent contamination.
3. If it does not, use the selected segmentation/matting workflow or flat-background extraction.
4. Correct holes in fine foliage, thin branches, fur, rope and other delicate details.
5. Remove colour spill and halos around partially blended edges.
6. Preserve the natural contact shadow without retaining a broad background patch.
7. Inspect the result on light, dark and saturated backgrounds.
8. Save a clean RGBA PNG and retain the source, mask and correction data.

Do not accept foliage with transparent holes caused by background removal. Do not accept a bright or dark fringe simply because it disappears against the test scene's background.

Manual correction is allowed when a generated image needs it, but the tool workflow should make correction straightforward. We do not need to build a sophisticated image editor before the first extraction test.

## 7. Godot asset metadata

Each approved asset needs its artwork and placement data to remain independent.

Record at least:

| Field | Meaning |
|---|---|
| Asset ID | Stable project identifier |
| Display name and category | Human-readable identity |
| Source image | Original generated source path |
| Runtime image | Approved transparent PNG path |
| Source dimensions | Original image or sheet dimensions |
| Crop / mask | Extraction region and correction data, when applicable |
| Canvas dimensions | Final sprite dimensions |
| Visible alpha bounds | Bounding rectangle of non-transparent pixels |
| Ground anchor | Contact point in source-image pixels |
| Logical footprint | Occupied grid columns × rows |
| Display scale | Runtime sprite scale |
| Texture filtering | Per-asset filtering setting |
| Source model and workflow | Checkpoint, quantization, workflow and version |
| Prompt and seed | Generation record; seed alone is not a guarantee of identical output |
| LoRAs / conditioning | Any model add-ons and reference-conditioning inputs |
| Alpha method | Native alpha, layered output or extraction/matting method |
| Review status | Experimental, calibration-approved or production-approved |

Use the existing PWAssetDefinition and source-art conventions where they fit. Do not overwrite Old Oak, Moonpetal Plant, Mossy Rock or other approved production artwork with experimental generations.

## 8. Quality gates

An asset remains experimental until it passes all relevant checks:

- Correct intended visual identity and material definition.
- Clear silhouette at normal mobile viewing size.
- Coherent perspective and scale relative to the approved references.
- Correct ground anchor and independent logical footprint.
- Natural ground contact and convincing contact shadow.
- No unwanted alpha holes, edge fringe, bright halos or dark halos.
- No accidental cropping or attached terrain/pedestal.
- Correct filtering and readable detail at actual game scale.
- Successful import and visual review in the isolated Godot calibration scene.
- Original source and generation settings retained.

A successful generation or export does not itself mean the asset is approved.

## 9. Starter production order

1. Establish and approve the master visual identity reference.
2. Calibrate a static tree, small plant, rock, building, creature and ground sample.
3. Prove the selected local model and the simplest reliable transparency workflow.
4. Review all calibration assets in Godot at actual game scale.
5. Produce the remaining ground, environmental-object, building and item-icon starter assets.
6. Generate the creature animation sheet after its static design and scale are accepted.
7. Integrate only approved assets into the playable project.

Keep batches small, reversible and reviewable. Do not turn a successful single test into permission to generate a full library.

## 10. Commercial and versioning checks

Before an image-generation model or add-on becomes part of production, record and review its license and any commercial-use restrictions. Check the base checkpoint, quantized distribution, LoRA, ControlNet, transparency model and custom nodes independently.

Record the ComfyUI version, relevant custom-node versions, model filenames and workflow JSON with each approved generation batch. Prefer a known working environment over updating every component during an active asset batch.

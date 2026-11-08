# CP06 — Starter Asset Plan and Scale Standard

## Purpose and scope

CP06 defines only the minimum artwork needed to validate the Pocket Worlds production pipeline and support the current playable prototype.

**This is not a full asset-library plan.** We will expand the catalogue as gameplay and environments grow. Do not generate large collections in advance.

Current playable scope:

- **Sanctuary:** the primary home space, where the player inspects, gathers, plants, crafts and places objects.
- **Whispering Woods:** a discovery space containing collectible resources and points of interest.
- **Home / stations:** the current Field Guide, Alchemy Table, Workbench and Creature Nook interactions.
- **One starter creature:** sufficient to prove sprite-sheet import, animation playback and world positioning.

The current project already has the interaction loop and resource IDs for wood, berries, Moonpetal Seeds, Dew, Moonstone, Moonpetal Essence and the Rune Lantern. Starter artwork should support these examples without expanding the gameplay scope.

## CP06 decisions and status

| Topic | CP06 position | Status |
|---|---|---|
| Production art direction | Enchanted Hand-Painted 2.5D | Working direction; CP07 calibration pending |
| World projection | 3/4 top-down dimetric, 2:1 diamond | Keep |
| Logical cell size | Evaluate 128 × 64 instead of current 96 × 48 | Candidate; not implemented |
| Source art density | Test 2× source resolution for ground tiles and suitable object classes | Provisional |
| Grounding | Object shadows must visibly connect to the ground | Required |
| Asset generation | 2D image generation with shared style and scale references | Proposed local workflow; model/tool compatibility pending |
| Animation | One creature, three short animation loops | Required validation |
| Library size | Starter assets only | Locked scope limit |

## 1. Grid size: 96 × 48 versus 128 × 64

The current GridProjection uses:

- Axis A: (48, 24)
- Axis B: (-48, 24)
- Cell dimensions: 96 × 48 world units

The proposed 128 × 64 system would use:

- Axis A: (64, 32)
- Axis B: (-64, 32)
- Cell dimensions: 128 × 64 world units
- Ground-tile PNG centre anchor: (64, 32) at 1×. The projected world cell-centre offset from the top grid vertex is (0, 32) world units.

For a rectangular logical footprint of columns × rows, the projected bounding dimensions are:

- Width: (columns + rows) × 64 world units
- Height: (columns + rows) × 32 world units

Examples:

| Footprint | Projected bounds at 128 × 64 |
|---|---:|
| 1 × 1 | 128 × 64 |
| 1 × 2 | 192 × 96 |
| 2 × 2 | 256 × 128 |
| 2 × 3 | 320 × 160 |
| 3 × 3 | 384 × 192 |

### Important: world units and source pixels are different

The proposed (64, 32) is the centre pixel of a 128 × 64 ground-tile PNG. In projected world coordinates, the cell centre is offset from the top grid vertex by (0, 32). These are different coordinate spaces, and the ground-tile anchor is not automatically the anchor for every object image.

For a ground tile:

- At 1× source resolution, a 128 × 64 PNG has a pixel centre at (64, 32).
- At 2× source resolution, a 256 × 128 PNG has a pixel centre at (128, 64) and can render at 0.5 scale into a 128 × 64 world cell.

For object sprites, source canvases and ground anchors depend on the visible artwork and the object's actual contact point. Do not force every object into a tile-sized canvas.

### What the Power-of-Two choice does and does not do

128 × 64 is attractive as an authoring standard because a base ground tile and a 2× source tile can use convenient power-of-two dimensions. It also gives us straightforward reference coordinates.

However, changing logical world units does not itself make the GPU faster or improve sharpness. Power-of-Two is a texture-dimension consideration, not a property of the world coordinate system. Godot 4.7 notes that some mobile GPUs have restrictions on repeating non-power-of-two textures; the current renderer places individual sprites per cell rather than repeating one texture. Mipmaps are a separate texture-import/filtering decision and should be enabled for smooth 2D artwork only when zoom-out testing shows a visible benefit.

**Decision:** 128 × 64 is the preferred candidate for the next authoring standard, but do not change the main GridProjection yet. First prepare a visual scale-reference board and an isolated comparison. If adopted, migrate grid coordinates, camera framing, ground tile sizing, sprite scales, selection bounds and test fixtures together. Do not leave a mixed 96/128 world.

### Technical references

- [Godot 4.7 rendering limitations](https://docs.godotengine.org/en/4.7/tutorials/3d/3d_rendering_limitations.html) — mobile GPU notes for repeating non-power-of-two textures.
- [Godot image importing and mipmaps](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html) — 2D mipmap trade-offs and additional memory use.
- [Godot CanvasItem texture filters](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html) — LINEAR and LINEAR_WITH_MIPMAPS behaviour for 2D sprites.

## 2. Starter asset inventory

This inventory is intentionally small. Each batch exists to test a different production problem.

### Batch G — Ground and terrain

The ground batch must validate seamless repetition, path connections, material transitions and object contact.

| Asset / tile group | Minimum content | Purpose |
|---|---|---|
| Grass base | One repeatable base tile | Main Sanctuary and woodland surface |
| Grass variation | Two or three restrained variants or overlays | Avoid obvious repetition |
| Dirt path | Straight, end, corner, T-junction and crossing pieces | Test connected path layouts |
| Rocky / mossy ground | One base patch plus a small variation | Whispering Woods surface |
| Water | One pond/water surface tile | Reuse the existing pond gameplay example |
| Shoreline | A small edge/corner transition set | Prove grass-to-water joins |

Ground images must share the same 2:1 dimetric projection, edge treatment, lighting and visual scale. The logical grid may remain invisible in the artwork. Do not draw individual cell borders into the final terrain unless the art direction explicitly calls for them.

For the 128 × 64 candidate, test a 256 × 128 source ground tile at 0.5 scale. Atlas layout and edge padding are to be decided after the first tiling test.

**Ground acceptance:** repeated grass has no obvious seams or pattern grid; path pieces connect on every intended side; water shorelines join cleanly; object shadows sit on top of the surface rather than appearing detached.

### Batch E — Environmental objects

These assets replace or support the current starter-world examples. They are not a complete nature collection.

| Starter object | Initial footprint | Gameplay / test purpose |
|---|---:|---|
| Large oak tree | 2 × 2 | Large natural silhouette, wood harvest, canopy overhang |
| Berry bush | 1 × 1 | Harvestable resource and smaller foliage |
| Moonpetal plant | 1 × 1 | Planting, tending and harvesting example |
| Small leafy ground plant | 1 × 1 | Small-scale proportion reference |
| Mossy boulder | 1 × 1 | Compact object, hard material and ground contact |
| Fallen log | 1 × 2 or 2 × 1 after orientation test | Long low silhouette and directional grounding |
| Ancient marker | 1 × 1 or 1 × 2 after placement test | Discovery / inspection point |
| Crystal cache | 1 × 1 | Collectible resource object |

Footprints are initial logical occupancy estimates, not visible image bounds. The generated objects need a separate visual scale standard.

### Batch B — Buildings and structures

We need a small size hierarchy, not a town library.

| Starter structure | Initial footprint | Required visual test |
|---|---:|---|
| Main Sanctuary cottage | 3 × 3 | Clearly architectural scale; main home landmark |
| Workshop / crafting shed | 2 × 3 | Smaller production building; recognizable entrance |
| Creature habitat | 2 × 2 | Dedicated creature home; compact but distinct |

Include one alternate/upgraded visual state for the main cottage, retaining the same ground footprint. This is enough to test visual progression and state swapping without producing a full upgrade catalogue.

Building roofs and overhangs may extend beyond the ground footprint. Keep doors, foundations and contact shadows aligned to the same ground plane.

### Batch C — One animated starter creature

Create one complete creature, not a species library.

| Animation | Frames | Requirement |
|---|---:|---|
| Idle | 4 | Small breathing, blink or body movement |
| Walk | 4 | Readable repeating gait |
| Signature interaction | 4 | One distinctive action such as greeting, gathering or reacting |

Initial target: a 4-column × 3-row sprite sheet with 12 equal frame cells, organized as one animation per row. Use identical frame dimensions, stable ground baseline, stable camera, consistent lighting and no unexpected changes to body proportions.

The exact frame-cell pixel size is provisional and must be set by the visual scale-reference test. Export a clean sheet with no labels or decorative framing. We must validate frame slicing, SpriteFrames creation, playback, looping, state switching and anchor stability in Godot.

Do not add growth stages, extra species or additional animation states in CP06.

### Batch I — Minimal item icon sheet

Only create the core items needed by the current playable loop:

- Wood
- Berry
- Moonpetal Seed
- Dew
- Moonstone
- Moonpetal Essence
- Rune Lantern

One small cohesive icon sheet is enough to test consistent item rendering and UI-scale readability. Do not create a full inventory icon catalogue yet.

## 3. What the first integrated starter scene must contain

The first complete art review scene should show:

- A large continuous grass area.
- A connected dirt path.
- A rocky patch.
- A pond with at least one shoreline transition.
- The main cottage, workshop and creature habitat.
- The oak, berry bush, Moonpetal, ground plant, boulder and fallen log.
- The Ancient Marker and Crystal Cache.
- The one starter creature playing its idle and walking animations.
- The cottage's base and upgraded visual states, shown as a controlled comparison.

This one scene is the minimum useful cross-category test for scale, ground contact, visual consistency, animation and composition. It is not a finished level or a full biome.

## 4. 2D AI image-generation batches

Keep prompts concise and reference-led. Use the approved visual identity reference and the separate grid/footprint guide rather than repeatedly putting every rule into long text prompts.

Recommended order:

1. **Style and scale calibration set:** one representative tree, plant, rock, building, creature and ground sample. This is a calibration set, not production content. Review the relative size hierarchy against the separate 2:1 ground-footprint guide.
2. **Ground sheet:** starter ground materials and the small connection set, generated separately from objects.
3. **Environmental object sheet:** the starter natural objects, with visible size differences matching the approved calibration reference.
4. **Building sheet:** cottage, workshop and habitat, all shown with the same view and clearly different architectural scales.
5. **Creature animation sheet:** one approved static creature, with three four-frame animation rows.
6. **Item icon sheet:** only the seven current core items.

After the visual identity and scale references are approved, reuse them for later batches. The footprint guide explains ground occupancy and relative size; the visual identity reference explains artistic appearance.

Use one isolated asset per image when a complex subject is difficult to separate. Category sheets are acceptable only when every object remains fully visible, clearly separated and easy to extract. ComfyUI is the proposed local generation environment; the exact model, quantization and optional conditioning tools remain subject to the CP07 local proof.

### Object-sheet background and presentation

- Use one uniform, contrasting background for extraction, unless a generator produces verified clean alpha.
- Keep objects fully visible and separated.
- Include compact natural contact shadows.
- No terrain tile, diamond platform, pedestal or scene beneath individual props.
- No UI, labels, grid, borders, decorative framing or unrelated props.
- Keep ground tile sheets separate from object sheets.
- For sprite sheets, require equal frame cells, fixed alignment and no labels or frame numbers inside the artwork.

## 5. Asset extraction and scale rules

For every extracted asset, retain:

- Original source sheet and file.
- Crop rectangle.
- Extraction method and mask.
- Manual correction layer, if any.
- Canvas dimensions and visible alpha bounds.
- Logical footprint.
- Ground anchor in source-image pixels.
- Display scale and texture filtering.
- Animation frame layout, when applicable.
- Source set / reference version.

Never derive scale from canvas dimensions alone. Normalize the visible artwork relative to the scale reference and footprint. Preserve the original generated sheet so every extraction can be reproduced.

For object shadows, validate both the generator's included contact shadow and a separately adjustable Godot shadow option where appropriate. Moving creatures need a stable, simple ground shadow independent of the animation frames.

## 6. Acceptance gates

| Gate | Must pass before moving on |
|---|---|
| Grid / scale reference | 1 × 1, 2 × 2 and 3 × 3 proportions are visually unambiguous; candidate grid decision recorded |
| Art direction | One coherent style works for natural props, buildings, creatures and ground |
| Extraction | No foliage holes, unwanted translucent patches, visible background fringe or soft halo at game scale |
| Object grounding | Rocks, logs, plants, buildings and creature do not appear to float |
| Terrain | Ground tiles repeat and connect without seams, grid-like patterns or broken transitions |
| Animation | Three loops import and play; no frame jitter or shifting ground baseline |
| Gameplay | Imported assets can be selected and used with the existing world interaction architecture |
| Production workflow | A repeatable batch can be imported, corrected, regenerated and reviewed without damaging approved assets |

Do not mark a gate as passed because files were generated or a script completed. The artwork must be inspected in the Godot review scene, including at normal gameplay zoom and a reduced zoom.

## 7. Explicitly out of scope for CP06

- Full environment / biome library.
- Multiple creature species or creature evolution chains.
- Large building catalogue or many upgrade levels.
- Complete furniture and interior decoration collection.
- Large vegetation, flower, rock or mushroom catalogues.
- Full inventory icon library.
- Full animation library for every asset.
- Production-quality auto-tiling editor or complete asset-management suite.

Build additional tools only when a specific CP06 test exposes a repeatable manual bottleneck.

## 8. Next implementation sequence

1. Create a visual 2:1 grid and footprint reference board for the 128 × 64 candidate.
2. Compare the candidate grid against the current 96 × 48 project in an isolated review; do not modify the main projection until the decision is made.
3. Establish the Enchanted Hand-Painted 2.5D calibration set across one object from each major category.
4. Review the calibration set and approve the repeatable 2D generation workflow before producing the separate starter batches.
5. Continue with ground tiling, extraction QA, animation and gameplay integration gates.

**CP06 completion means that the starter scope, grid reference and category-batch plan are understood. It does not mean the starter asset library has been generated or approved.**

## 9. CP07 art direction and calibration

CP07 supersedes the earlier Casual Toon candidate with the working direction **Enchanted Hand-Painted 2.5D**. See:

- **docs/CP07_VISUAL_IDENTITY.md** — central style, material, lighting, atmosphere and detail rules.
- **docs/CP07_ASSET_GENERATION_GUIDE.md** — proposed 2D image-generation, extraction and metadata workflow.
- **docs/CP07_CALIBRATION_SCENE_SPEC.md** — specification for the isolated Godot visual-review scene.

The proposed local image-generation platform is ComfyUI, with the Qwen Image family and GGUF loading to be evaluated on the RTX 4090. ControlNet and transparency tooling are optional experiments. No 3D modelling or manual structural-map authoring is required. The calibration scene is specified but not yet implemented.

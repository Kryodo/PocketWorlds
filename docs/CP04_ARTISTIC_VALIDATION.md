# CP04 — Artistic Validation

## Purpose

CP04 is an isolated art-direction experiment. It is intended to answer whether a deliberately authored, pixel-cluster approach can establish the visual standard for Pocket Worlds before the asset collection is expanded.

It is not a production biome pack and does not replace the current asset collection.

## Review scene

Run `scenes/tests/artistic_validation_review.tscn` with F6.

The scene places two samples side by side:

- **Current baseline:** the existing Old Oak, Moonpetal Plant, Mossy Rock and the current per-cell ground renderer.
- **Pixel-cluster study:** three new experimental sprites and one continuous 7 × 5 ground patch.

Both sides use the same projection, object cells and logical footprints. The current object PNGs and definitions are not modified.

## Experimental assets

| Asset | Source canvas | Ground anchor | Footprint | Display scale |
|---|---:|---:|---:|---:|
| `validation_oak` | 256 × 256 | (128, 244) | 2 × 2 | 1.0 |
| `validation_plant` | 128 × 128 | (64, 122) | 1 × 1 | 1.0 |
| `validation_rock` | 160 × 112 | (80, 102) | 1 × 1 | 1.0 |

The prototypes are built from explicit pixel clusters and separate source layers:

1. Ground Shadow
2. Base Art
3. Directional Highlights

The tree study tests a broad canopy with a distinct brighter upper mass and darker lower crown, plus a visible trunk and ground-contact shadow. The plant and rock test whether the same cluster scale and lighting language work on smaller silhouettes.

## Ground study

`validation_ground_patch.png` is a single continuous projected surface covering a 7 × 5 world grid.

The study deliberately avoids drawing a separate visible diamond boundary around every cell. Terrain variation is distributed as larger connected color clusters, with a winding dirt path, small flower groups and stone details.

Its editable source document is stored at `assets/source_art/validation_ground_patch/`.

## Generated files

When the review scene runs, it creates:

- `assets/sprites/validation_oak.png`
- `assets/sprites/validation_plant.png`
- `assets/sprites/validation_rock.png`
- `assets/sprites/validation_ground_patch.png`
- Matching object definitions under `assets/definitions/`
- Three editable PNG layers and `document.json` for each object under `assets/source_art/`
- Three editable ground-patch layers and `document.json` under `assets/source_art/validation_ground_patch/`

Existing validation files are preserved by default. To intentionally regenerate a prototype after editing it, remove that prototype's generated files first or explicitly change the generator call to overwrite them.

## What to evaluate

1. **Pixel language:** Do the silhouettes and interior shading read as deliberate pixel clusters rather than brush-like texture?
2. **Volume and light:** Is the brighter upper surface clearly separated from the darker lower-facing areas?
3. **Shadows:** Do the contact shadows ground the objects without looking like detached flat ovals?
4. **Palette:** Are the greens, flower colors, bark and stone lively enough while remaining coherent?
5. **Proportions:** Does the 2 × 2 oak feel substantially larger than the 1 × 1 plant and rock? Are visual overhangs believable relative to the footprints?
6. **Ground continuity:** Does the connected surface feel more natural than the individual diamond tiles? Does the path sit naturally in it?
7. **Consistency:** Do all three prototypes feel like the same game and the same lighting setup?

## Non-goals and safety rails

- Do not change gameplay, grid projection, object placement rules or the existing production asset definitions.
- Do not overwrite Old Oak, Moonpetal Plant, Mossy Rock or the CP03 ground tiles.
- Do not expand the collection yet.
- Do not treat this experimental set as approved production art until the visual review is complete.

The outcome of CP04 should be a decision about the art direction and production method, not a larger asset count.

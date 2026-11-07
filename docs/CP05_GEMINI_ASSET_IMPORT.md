# CP05 — Gemini Woodland Asset Import

## Purpose

CP05 tests the complete transition from one externally generated JPG asset sheet into reusable Pocket Worlds assets.

The original source is preserved at:

- `art_inbox/woodland_asset_set_01.jpg`

The source sheet is 1264 × 848 and contains six isolated objects on a uniform cyan background.

## Imported objects

| Asset ID | Object | Source crop | Ground anchor | Footprint | Initial display scale |
|---|---|---:|---:|---:|---:|
| `ai_woodland_oak` | Woodland Oak | 510 × 510 | (300, 475) | 2 × 2 | 0.42 |
| `ai_woodland_bush` | Leafy Bush | 300 × 280 | (150, 245) | 1 × 1 | 0.36 |
| `ai_woodland_flowering_plant` | Flowering Plant | 190 × 210 | (90, 185) | 1 × 1 | 0.40 |
| `ai_woodland_leafy_plant` | Leafy Plant | 230 × 220 | (115, 210) | 1 × 1 | 0.38 |
| `ai_woodland_mossy_boulder` | Mossy Boulder | 260 × 225 | (130, 215) | 1 × 1 | 0.34 |
| `ai_woodland_fallen_log` | Fallen Log | 370 × 280 | (190, 255) | 1 × 2 | 0.38 |

The crop rectangles and initial scales are first-pass measurements. They are expected to be refined after visual inspection in Godot.

## Import and extraction

Run `scenes/tests/ai_woodland_asset_review.tscn` with F6.

The importer:

1. Loads the original JPG directly from `art_inbox/`.
2. Samples the four corners to estimate the cyan key color.
3. Crops each object using a fixed rectangle.
4. Removes the cyan background and decontaminates partially blended edge pixels.
5. Saves each object as a transparent PNG.
6. Creates a `PWAssetDefinition` with display scale, ground anchor and logical footprint.
7. Saves a source document with the extracted flattened artwork and an empty manual-cleanup layer.

The JPG has no transparency and is compressed. The color-key process is an initial automated matte, not a promise of perfect edge isolation. Inspect foliage edges, log details and contact shadows carefully.

The original contact shadows remain part of the flattened extracted sprite. They are not separated into independent layers. The source document explicitly records this.

## Rendering

The new assets set `texture_filter_mode` to LINEAR to retain the illustrated Casual Toon appearance when scaled. Existing assets continue to use NEAREST by default. This is a per-asset setting and does not change the global project filter.

The review scene displays:

- **Left:** current Old Oak, Moonpetal Plant and Mossy Rock.
- **Right:** all six imported objects.
- Both panels use the same 2:1 grid projection and current CP03 ground renderer.

The review is intentionally isolated. Existing production sprites, definitions, ground tiles and gameplay are not overwritten.

## Generated files

The first run creates:

- `assets/sprites/ai_woodland_*.png`
- `assets/definitions/ai_woodland_*.tres`
- `assets/source_art/ai_woodland_*/document.json`
- `assets/source_art/ai_woodland_*/layers/layer_00.png`
- `assets/source_art/ai_woodland_*/layers/layer_01.png`

The dedicated review scene currently calls the importer with overwrite enabled, so every F6 run refreshes all six experimental PNGs, definitions and source documents from the original JPG. This intentionally removes stale exports from earlier extraction attempts. Do not make manual edits to the generated files until the extraction settings are accepted. The original `art_inbox/` JPG is never modified.

## Review checklist

1. Is the cyan fully removed, including between leaves, branches and around the log?
2. Are there visible cyan or dark fringes around anti-aliased edges?
3. Are contact shadows preserved naturally, or do they look too opaque or too faint?
4. Do the visible dimensions feel appropriate for the assigned footprints?
5. Do all six objects read clearly at gameplay scale?
6. Does LINEAR filtering look correct at the selected display scales?
7. Do the assets fit the existing world and ground treatment?

Do not promote the imported objects to the production collection until extraction, scale, shadows and consistency are approved.

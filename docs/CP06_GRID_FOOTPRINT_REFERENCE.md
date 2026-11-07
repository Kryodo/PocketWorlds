# CP06 — Grid and Footprint Visual Reference

## Purpose

This technical reference is for Gemini prompts, manual asset sizing and Godot integration. It explains the proposed 128 × 64 dimetric grid and demonstrates how logical ground footprints differ from visible object dimensions.

It does not modify or replace the current GridProjection (96 × 48). The 128 × 64 system remains a candidate until visual framing and migration implications are reviewed.

## Preview and export

Run scenes/tests/grid_footprint_reference.tscn with F6.

The scene validates the candidate projection and draws:

- The current 96 × 48 and proposed 128 × 64 diamond tile canvases.
- Candidate axis vectors A=(64,32) and B=(-64,32).
- The 1× and 2× image-centre anchors.
- 1 × 1, 1 × 2, 2 × 2, 2 × 3 and 3 × 3 ground footprints.
- Examples showing that a tree crown or building roof can extend beyond its ground footprint.

Expected console output:

    GRID FOOTPRINT REFERENCE PASS
    Candidate: 128 × 64 | A=(64,32) | B=(-64,32)
    PNG centre anchor: (64,32) at 1×; (128,64) at 2×

Press P while the scene is focused to export a 1280 × 720 PNG to:

assets/catalog/grid_footprint_reference.png

The exported PNG is generated locally by Godot. Commit it through GitHub Desktop if it is useful as a visual reference for Gemini.

## 1. Two different coordinate spaces

Do not confuse the centre of the tile image with the centre's offset in projected world coordinates.

### Ground-tile image canvas

A 128 × 64 PNG contains a diamond with canvas-space vertices:

- Top: (64,0)
- Right: (128,32)
- Bottom: (64,64)
- Left: (0,32)

The image-centre anchor is therefore **(64,32)**.

For a 2× source image rendered at 0.5 scale:

- Source PNG: 256 × 128
- Image-centre anchor: **(128,64)**
- Rendered size: 128 × 64 world units

### Projected world coordinates

The candidate grid axes are:

- A=(64,32)
- B=(-64,32)

grid_to_world(cell) identifies the top grid vertex / lattice intersection for that cell coordinate. The cell's geometric centre is offset from that vertex by:

- World X: 0
- World Y: 32

The renderer positions a centred diamond sprite at that projected cell centre. The sprite image centre remains (64,32) in its own 128 × 64 canvas.

This is the same convention used by the current 96 × 48 projection, scaled by 4/3.

## 2. Candidate footprint dimensions

For a rectangular footprint columns × rows using A=(64,32) and B=(-64,32), the projected ground bounding dimensions are:

- Width = 64 × (columns + rows)
- Height = 32 × (columns + rows)

| Footprint | Projected ground bounds |
|---|---:|
| 1 × 1 | 128 × 64 |
| 1 × 2 | 192 × 96 |
| 2 × 2 | 256 × 128 |
| 2 × 3 | 320 × 160 |
| 3 × 3 | 384 × 192 |

The footprint is an occupancy and placement contract. It is not the required source-image size.

## 3. Communicating object scale to Gemini

Use this guide alongside an approved style reference. Do not rely on a text-only instruction such as "create a 3 × 3 house".

Explain that:

- A 1 × 1 plant has a compact base and a relatively small visible silhouette.
- A 1 × 1 rock is low and broad, with a clear contact shadow on the ground plane.
- A 2 × 2 tree has its trunk/root contact centred on the occupied cells; its crown can extend well beyond the footprint.
- A 2 × 1 log is long and low; its orientation must match its footprint direction.
- A 3 × 3 cottage is a building-scale object, visibly larger than the tree and vastly larger than a rock or log. Its roof may overhang, but its foundation and door placement must agree with the ground plane.

The board's silhouettes are schematic guides, not final art dimensions. The approved cross-category reference artwork will establish actual visible-size ratios.

## 4. Source dimensions and Power-of-Two note

For the candidate 128 × 64 world cell, a 256 × 128 source tile rendered at 0.5 scale is a convenient 2× authoring option. Both dimensions are powers of two.

This is an authoring and texture-layout convenience. It does not mean the 128 × 64 world-coordinate system itself is a GPU optimisation. Test texture filtering, mipmaps, camera zoom and memory usage on the intended mobile renderer before selecting import settings.

## 5. Decision gate

After inspecting the board in Godot, evaluate:

1. Is the 128 × 64 diamond a more convenient authoring and reference size?
2. Are the footprint dimensions and relative sizes clear enough for Gemini to follow when given the image?
3. Does the projected composition frame well in the existing landscape world viewport?
4. Is there a strong reason to migrate the main world from 96 × 48, beyond simply preferring the larger numbers?

Do not change GridProjection, ground assets, map coordinates or gameplay until the candidate is explicitly approved.

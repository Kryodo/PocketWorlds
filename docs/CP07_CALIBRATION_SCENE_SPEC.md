# CP07 — Godot Asset Calibration Scene Specification

## Status

**Specification only.** This document defines the isolated review scene to be implemented after the CP07 documentation batch. No new calibration scene or runtime code is created by this document update.

Proposed future scene path: **scenes/tests/cp07_asset_calibration_review.tscn**

## 1. Purpose

Provide one repeatable Godot scene for reviewing the first Pocket Worlds 2D-generated calibration assets together, at the actual target viewport and candidate grid scale.

The scene answers whether the chosen art direction and image-generation workflow produce assets that work together in the game. It is not a playable level, production biome, asset editor or model-generation interface.

It must not require ComfyUI to be running. It loads exported image files and their Godot asset definitions.

## 2. Non-destructive boundaries

The calibration scene must:

- Remain under scenes/tests/.
- Use isolated test data and review-only scene nodes.
- Never overwrite approved production PNGs, source documents or PWAssetDefinition resources.
- Never modify the current GridProjection or gameplay map.
- Never change the main scene, camera, input, interaction, save or gameplay systems.
- Never generate or extract artwork automatically when the scene starts.
- Show missing assets as clearly labelled placeholders rather than silently modifying the inventory.
- Keep test configuration and candidate settings local to the calibration scene.

The current game remains on its existing 96 × 48 projection. The 128 × 64 projection remains a candidate and may be used inside this isolated review scene only. Do not mix 96 × 48 and 128 × 64 cells within one calibration board.

## 3. Initial calibration asset set

The first pass must review one representative from each category below. These are test subjects, not a commitment to produce the remaining library.

| Test subject | Initial footprint / role | Main question |
|---|---|---|
| Ancient oak | 2 × 2 | Canopy-to-trunk proportion, foliage detail, overhang and grounding |
| Small plant | 1 × 1 | Mobile readability and small-object detail density |
| Mossy rock | 1 × 1 | Stone material, volume and convincing ground contact |
| Sanctuary cottage | 3 × 3 | Building scale, crafted architecture, roof/foundation alignment |
| Starter creature | 1 × 1 provisional | Character rendering, appeal, world integration and ground baseline |
| Ground sample | Candidate 128 × 64 tile or connected patch | Seamless surface, tile scale, texture density and world integration |

The exact creature footprint may be revised after its static scale is reviewed. Footprints are logical placement values and do not constrain the size of the sprite canvas.

The first cottage may show one state. The base/upgraded comparison belongs in the later starter-building review unless it is readily available without expanding the calibration batch.

## 4. Scene layout

The scene should be arranged as three clearly labelled review areas.

### A. Asset scale and footprint stage

Display the oak, plant, rock, cottage and static creature on the same candidate projection and at a shared visual scale.

- Place each asset on its logical ground footprint.
- Draw the occupied diamond cells as an optional overlay.
- Mark each ground anchor independently from the image-canvas centre.
- Show the visible alpha bounds without clipping overhangs.
- Leave enough separation that large canopies and roofs do not visually merge.
- Use a neutral, unobtrusive background that makes transparency defects easy to see.

The stage should make the relative size hierarchy obvious: the 1 × 1 plant and rock are small, the oak is materially larger, and the cottage reads as a structure rather than another prop.

### B. Ground and material stage

Display the ground sample as a continuous patch rather than only as a single isolated diamond.

At minimum, allow review of:

- Grass base and a small variation, if both are available.
- One path connection or path segment.
- One rocky/mossy patch.
- One water-to-ground or shoreline transition when those samples are ready.

The ground stage must make repeated patterns, tile seams, incorrect edge alignment and texture-density differences visible. Do not add decorative props that hide the joins.

### C. Integrated composition stage

Arrange the calibration objects on the ground sample to show whether they belong to the same world.

- Place the tree, plant, rock and creature at different depth positions.
- Include at least one object behind and one in front of another where practical.
- Verify that sorting follows the ground anchor or the project's established asset sorting convention, not the top of the sprite canvas.
- Keep the cottage far enough from other objects that its footprint and foundation can be read.
- Do not create a complete level or add unapproved decorations merely to fill empty space.

## 5. Projection and viewport

- Target the project's existing landscape logical review viewport: 1280 × 720.
- Use the 2:1 dimetric / three-quarter top-down presentation.
- Use the candidate axes A=(64,32) and B=(-64,32) only for the isolated 128 × 64 review profile.
- Keep the image-centre anchor distinct from the world-cell-centre offset. For a 128 × 64 tile, the image-centre pixel is (64,32); relative to the top grid vertex, the projected world cell-centre offset is (0,32).
- Preserve the same camera direction and object orientation throughout the stage.
- Review both normal gameplay framing and a reduced-zoom stress view.

The scene is a visual scale test, not a decision to migrate the live project. A future comparison with the existing 96 × 48 world must use a separate, clearly labelled profile or panel; never reinterpret one scene's object coordinates as if the two grid sizes were interchangeable.

## 6. Review overlays and diagnostics

Provide simple toggles or clearly separated diagnostic views for:

- Logical footprint diamonds.
- Ground-anchor crosshairs.
- Visible alpha bounds.
- Candidate grid axes / cell edges.
- Background comparison for transparency defects.

Overlays must be optional so the final artwork can also be judged without visual clutter.

For each asset, show its ID, category, footprint, source canvas size and display scale in a small review label or adjacent panel. Do not burn these labels into the artwork.

The scene should report missing resources and invalid definitions clearly. It should not automatically rewrite definitions, PNGs or inventory data.

## 7. Rendering and quality checks

### Scale and visual hierarchy

- Compare the assets together at 1280 × 720.
- Confirm the plant and rock remain readable without becoming oversized.
- Confirm the oak crown can overhang its 2 × 2 footprint without its trunk or ground anchor drifting.
- Confirm the cottage foundation and entrance align with its 3 × 3 ground area.
- Check the creature against the same world scale.

### Grounding and sorting

- Confirm rocks, plants, tree roots, building foundations and creature feet meet the ground convincingly.
- Look for detached contact shadows, excessive dark patches, pale halos and alpha fringes.
- Confirm near/far sorting uses ground position, not full image height.
- Confirm tall or wide artwork may overlap adjacent cells without changing occupancy.

### Transparency and filtering

- Inspect each transparent sprite against light, dark and saturated backgrounds.
- Confirm transparent corners and gaps are genuinely transparent.
- Look for holes in foliage, translucent patches, cyan/white/black spill, halos and jagged matte edges.
- Compare the intended per-asset texture filtering at normal and reduced zoom.
- Do not change the global project filter merely to improve one experimental sprite.

### Ground continuity

- Check tile joins at normal and reduced zoom.
- Look for repeated motifs that reveal the grid or obvious pattern repetition.
- Check that path edges and shoreline transitions meet at the correct sides.
- Verify that object shadows remain visually attached to the terrain.

### Style consistency

- Compare material rendering, contour softness, light direction, detail density, saturation and depth across all categories.
- A beautiful isolated object does not pass if it looks as though it belongs to a different game.
- Inspect at the actual gameplay scale; do not approve an asset solely from a large source preview.

## 8. Test phases

| Phase | Inputs | Required result |
|---|---|---|
| CP07-A static calibration | One oak, plant, rock, cottage, creature and ground sample | Style, scale, perspective, material and grounding review |
| CP07-B extraction review | Transparent PNG exports and source/mask records | Clean edges, preserved detail, correct anchors and bounds |
| CP07-C terrain review | Grass, path, rocky patch, water/shoreline samples | Seamless or correctly connected ground |
| CP08 starter-world review | Remaining starter objects and three buildings | Coherent small environment with correct logical placement |
| CP09 creature animation review | Approved 4 × 3 creature sheet | Frame slicing, SpriteFrames playback, loops, transitions and stable baseline |

Do not block static visual calibration on the creature animation sheet. Static creature design and scale are reviewed first; animation comes after approval.

## 9. Acceptance criteria

The initial calibration scene is useful when it can prove all of the following:

- Six representative category samples can be loaded without modifying production assets.
- The 2:1 projection and candidate footprints are clear.
- Image-centre, ground anchor, visible bounds and logical footprint are displayed as separate concepts.
- Relative asset proportions are understandable at the target viewport.
- The same assets can be inspected with and without grid/anchor overlays.
- Ground contact, transparency, filtering, sorting and mobile readability can be evaluated.
- The ground sample can be checked as a continuous surface.
- Results can be recorded without changing the live game.

A calibration pass does not approve the candidate 128 × 64 grid for the main project and does not approve a full production library. It approves only the tested visual direction and the tested sample assets.

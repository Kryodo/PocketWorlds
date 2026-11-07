# CP02 implementation — world foundation and Art Studio MVP

## Current baseline

- Project version target: Godot 4.7.
- CP01 game-state, inventory, discovery, crafting and interior interaction logic remains in place.
- Implementation is committed directly to `prototype/playable-skeleton-v0.1` at the user's request.

## Implemented in this pass

### Landscape shell
- Project reference viewport changed to 1280 × 720.
- Handheld orientation changed to landscape.
- Main screen shell changed to a compact landscape layout with the world occupying the main area and a collapsible contextual side panel.

### World foundation
- Replaced the 9 × 9 square board with a 32 × 32 projected test world.
- Added a dedicated SubViewport and Camera2D so world movement and zoom do not transform the HUD.
- Added separate camera pan/zoom handling and mouse/touch gesture handling.
- Adopted one 2:1 diamond ground projection with three-quarter-view object artwork; the redundant projection toggle was removed after user testing found the candidates indistinguishable.
- Added grid-to-world, world-to-grid, cell polygon and map-bounds functions.
- Added a grid occupancy model with rectangular and irregular footprints.
- Added object-level footprint metadata in the CP02 debug map.
- Added an asset definition Resource for PNG path, pixel dimensions, ground anchor, visual offset, footprint, blocking cells, selection polygon, sorting and optional SpriteFrames.
- Added an asset-backed WorldEntity Node2D that positions a Sprite2D or AnimatedSprite2D using the ground anchor.
- Integrated the first three transparent PNG sprites (Old Oak, Moonpetal Plant, Mossy Rock) through PWAssetDefinition and the y-sorted WorldEntities root.
- Standardized world-object sorting origins on the bottom-center of their logical footprint; visual sprite offsets remain driven by each PNG's ground anchor.

### Art Studio MVP
- Added an optional editor plugin. It is not auto-enabled.
- Provides a 128 × 128 transparent canvas.
- Provides brush, eraser and eyedropper tools.
- Provides three initial layers, layer add/remove and palette swatches.
- Saves editable layer PNGs and a JSON source document under `assets/source_art/<asset_id>/`.
- Exports a composite runtime PNG under `assets/sprites/`.
- Exports a `PWAssetDefinition` resource under `assets/definitions/`.

## What is deliberately still temporary

- Old Oak, Moonpetal Plant and Mossy Rock now render from transparent PNGs and editable source layers. Other visible object forms remain temporary debug silhouettes.
- The ground is a projected debug grid, not a finished terrain tileset.
- The Art Studio does not yet provide selection/mask tools, fill, shape/line tools, animation frame editing, sprite-sheet packing, undo/redo history or asset browser integration.
- The first three-sprite starter collection is authored; the broader biome library, tileset and animation frames are still future work.
- WorldEntity exists as the asset-backed rendering primitive but is not yet used to replace the debug entities in the comparison scene.
- Camera framing, projection ratios, filtering and touch targets still require manual visual tuning.
- Android performance and input have not been tested in this environment.

## Regression test

Open `scenes/tests/world_foundation_regression.tscn` and run it with F6.

Expected output:

```
WORLD FOUNDATION REGRESSION PASS
```

The test verifies cell-center round trips for all 1,024 cells in the selected projection, map bounds, multi-cell occupancy, overlap rejection, same-instance validation, edge rejection, release and irregular footprints.

## Enable Art Studio

1. Open Project Settings → Plugins.
2. Enable **Pocket Worlds Art Studio**.
3. Use Project → Tools → Pocket Worlds Art Studio.
4. Paint a sprite, select its ground anchor and footprint, then use Export PNG.

The generated source and export files are saved into the project tree and should be committed normally through GitHub Desktop.

## Next implementation slice

1. Run the regression scene and game in Godot 4.7.
2. Fix any parser or viewport issues reported by the editor.
3. Run `scenes/tests/asset_collection_regression.tscn` with F6 and confirm the runtime textures and editable source documents pass.
4. Open the main scene and inspect the three real sprites at normal zoom and after pan/zoom; tune any visual-scale or anchor issues found in Godot.
5. Improve Art Studio editing ergonomics based on first hands-on use.
6. Add initial idle animation tests.
7. Build and validate on a physical Android device.

## First PNG asset collection

The first asset integration pass adds:

- `old_oak`: 128 × 128, ground anchor (64, 122), 2 × 2 footprint.
- `moonpetal_plant`: 128 × 128, ground anchor (64, 119), 1 × 1 footprint.
- `mossy_rock`: 128 × 128, ground anchor (64, 116), 1 × 1 footprint.

Each runtime PNG has three editable source layers (Shadow, Main, Highlights) and a source `document.json`. Definitions live under `assets/definitions/`; runtime composites live under `assets/sprites/`. The existing debug ground and remaining debug objects are intentionally retained so this slice changes only the three selected asset instances.

Run `scenes/tests/asset_collection_regression.tscn` with F6. Expected output: `ASSET COLLECTION REGRESSION PASS`. This checks transparent texture content, metadata, source-layer presence and WorldEntity sprite/anchor setup. A normal main-scene run is still required to visually verify projection scale and depth sorting on the user's Godot 4.7 setup.


## CP03 terrain and object-scale integration

The first three authored object PNGs remain unchanged. Their display scale is now definition metadata, so the source PNG dimensions and logical ground anchors are preserved while the in-world sprite size can be tuned independently. The Art Studio canvas supports rectangular documents and configurable dimensions.

The debug ground was replaced by `WorldGroundTiles`, which renders one 2:1 diamond sprite per grid cell. Six forest tile definitions are produced by `ForestGroundTileGenerator`: grass, flower grass, wildflowers, dirt path, bare dirt path and rocky ground. The source tiles are 192 × 96 and render at 0.5 scale to align with the 96 × 48 projection cell. The generator writes static PNGs, `.tres` definitions and editable three-layer source documents. Existing files are preserved by default.

### CP03 verification

1. Run `scenes/tests/generate_forest_ground_tiles.tscn` with F6. Expected output begins with `FOREST GROUND TILE PNG GENERATION PASS`.
2. Run `scenes/tests/asset_ground_review.tscn` with F6 to inspect the three existing object sprites on the generated ground.
3. Run `scenes/tests/asset_collection_regression.tscn` with F6. Expected output: `ASSET + GROUND REGRESSION PASS`.
4. Run `scenes/tests/world_foundation_regression.tscn` with F6 to confirm the existing projection and occupancy foundation remains intact.

Generated PNGs, definitions and source files live under `assets/sprites/`, `assets/definitions/` and `assets/source_art/`. Commit those generated assets through GitHub Desktop after visual review.

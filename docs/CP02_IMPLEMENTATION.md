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
- Added projection switching between the current three-quarter candidate and an isometric-style candidate.
- Added grid-to-world, world-to-grid, cell polygon and map-bounds functions.
- Added a grid occupancy model with rectangular and irregular footprints.
- Added object-level footprint metadata in the CP02 debug map.
- Added an asset definition Resource for PNG path, pixel dimensions, ground anchor, visual offset, footprint, blocking cells, selection polygon, sorting and optional SpriteFrames.
- Added an asset-backed WorldEntity Node2D that positions a Sprite2D or AnimatedSprite2D using the ground anchor.

### Art Studio MVP
- Added an optional editor plugin. It is not auto-enabled.
- Provides a 128 × 128 transparent canvas.
- Provides brush, eraser and eyedropper tools.
- Provides three initial layers, layer add/remove and palette swatches.
- Saves editable layer PNGs and a JSON source document under `assets/source_art/<asset_id>/`.
- Exports a composite runtime PNG under `assets/sprites/`.
- Exports a `PWAssetDefinition` resource under `assets/definitions/`.

## What is deliberately still temporary

- The visible world object forms remain debug silhouettes. They are deliberately not presented as production pixel art.
- The ground is a projected debug grid, not a finished terrain tileset.
- The Art Studio does not yet provide selection/mask tools, fill, shape/line tools, animation frame editing, sprite-sheet packing, undo/redo history or asset browser integration.
- The first production sprite family has not yet been authored.
- WorldEntity exists as the asset-backed rendering primitive but is not yet used to replace the debug entities in the comparison scene.
- Camera framing, projection ratios, filtering and touch targets still require manual visual tuning.
- Android performance and input have not been tested in this environment.

## Regression test

Open `scenes/tests/world_foundation_regression.tscn` and run it with F6.

Expected output:

```
WORLD FOUNDATION REGRESSION PASS
```

The test verifies cell-center round trips in both projections, map bounds, multi-cell occupancy, overlap rejection, same-instance validation, edge rejection, release and irregular footprints.

## Enable Art Studio

1. Open Project Settings → Plugins.
2. Enable **Pocket Worlds Art Studio**.
3. Use Project → Tools → Pocket Worlds Art Studio.
4. Paint a sprite, select its ground anchor and footprint, then use Export PNG.

The generated source and export files are saved into the project tree and should be committed normally through GitHub Desktop.

## Next implementation slice

1. Run the regression scene and game in Godot 4.7.
2. Fix any parser or viewport issues reported by the editor.
3. Compare the two projection modes and check PC aspect ratios.
4. Improve Art Studio editing ergonomics based on first hands-on use.
5. Create the first production PNG sprites and load them through WorldEntity.
6. Add initial idle animation tests.
7. Build and validate on a physical Android device.

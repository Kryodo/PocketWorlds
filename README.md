# Pocket Worlds — CP01 playable skeleton + CP02 world foundation

A first Godot 4.7 mobile-first prototype for the Pocket Worlds concept.

## Apply this package to your existing project

This is an **overlay package** for the clean `Kryodo/PocketWorlds` starter project.

1. Commit or otherwise back up your current local project state.
2. Extract this package into the root of your existing `PocketWorlds` project folder.
3. Allow `project.godot` to be replaced.
4. Keep your existing `.git/`, `.gitignore`, `.gitattributes`, `.editorconfig`, `icon.svg` and `icon.svg.import` files. This package intentionally does not contain or replace them.
5. Open the project in Godot 4.7 and let the editor scan/import the new files.
6. Run the project with F6 from `scenes/app/main.tscn`, or F5 after opening the project (the main scene is configured).

The package does not contain `.git/` or `.godot/`.

## Included in this checkpoint

- Landscape-first 1280 × 720 logical reference viewport (Godot 4.7 Mobile renderer).
- Sanctuary and Whispering Woods prototype worlds on a 32 × 32 projected grid.
- Mouse/touch map panning and pinch/wheel zoom using an isolated world SubViewport and Camera2D.
- One selected 2:1 diamond grid with a three-quarter top-down/isometric hybrid presentation.
- Separate grid projection, occupancy, camera and asset-definition resources.
- World object anchors and selection areas are independent of grid cell dimensions.
- Pocket Worlds Art Studio editor plugin for pixel painting, layers, palettes, source saving and PNG/resource export.
- First real transparent PNG collection: Old Oak, Moonpetal Plant and Mossy Rock, with editable source layers and asset definitions.
- Tap-to-inspect contextual object interactions.
- Basic inventory, XP and Sanctuary levels.
- Home interior with Field Guide, Alchemy Table, Workbench and Creature Nook hubs.
- Swipe-style book page navigation using touch-friendly buttons.
- A short multi-step brewing interaction.
- Discovery collection, planting, tending and harvesting.
- A basic crafting and Sanctuary placement reward.
- JSON save data stored under `user://pocket_worlds_save.json`.

## First playable loop

1. In the Sanctuary, inspect the Old Oak and collect berries and wood.
2. Open **Explore** and activate the Ancient Marker.
3. Collect Moonpetal Seeds and a Moonstone in Whispering Woods.
4. Open **Home**, read the Field Guide and study the Moonpetal notes and brewing recipe.
5. Brew Moonpetal Essence at the Alchemy Table.
6. Craft a Rune Lantern at the Workbench.
7. Return to the Sanctuary, plant and tend a Moonpetal, then place the Rune Lantern.
8. Open the Field Journal to review discoveries and inventory.

Progress is saved automatically in the user's Godot data directory.

## Important limitations

- Old Oak, Moonpetal Plant and Mossy Rock are now real transparent PNG sprites with editable source layers. Most other world objects and the ground are still temporary debug silhouettes/polygons.
- Art Studio is an initial MVP. It currently provides a 128 × 128 canvas, brush/eraser/eyedropper, layers, palette selection, source save/load, PNG export and asset metadata export. Advanced selection, fill, shape and animation editing are not implemented yet.
- Object placement is restricted to predefined demonstration slots; a full drag-to-place editor is a later checkpoint.
- Discovery interactions are authored examples, not a generalized quest or ecology simulation.
- The Creature Nook is currently a placeholder hub.
- The brewing activity proves the reusable hub interaction pattern; additional minigames are not included yet.
- No mobile export presets, audio package, final typography, production assets or device-specific performance pass are included.

## CP02 Art Studio

1. Open **Project → Project Settings → Plugins**.
2. Enable **Pocket Worlds Art Studio**.
3. Open **Project → Tools → Pocket Worlds Art Studio**.
4. Paint on the transparent canvas, add/select layers and choose palette colors.
5. Use **Save Source** to retain editable layers, or **Export PNG** to create a runtime PNG and `.tres` asset definition under `assets/`.

The current project configuration enables the plugin. It can be disabled under Project Settings → Plugins if you need to isolate an editor-tool issue.

## First PNG asset collection

See `assets/README.md` for the asset IDs, ground anchors, footprints and Art Studio editing steps. The first three sprites are integrated into the Sanctuary and Whispering Woods. Run `scenes/tests/asset_collection_regression.tscn` with F6; expected output:

```
ASSET COLLECTION REGRESSION PASS
```

## Verification

See `docs/PLAYABLE_SKELETON_V0_1.md` for the architecture and manual verification checklist.

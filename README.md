# Pocket Worlds — Playable Skeleton v0.1

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

- Portrait-first 2D project setup (preserves the starter project's Godot 4.7 Mobile renderer configuration).
- Sanctuary and Whispering Woods top-down tile maps.
- Mouse/touch map panning and pinch/wheel zoom.
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

- World artwork is temporary programmatic placeholder drawing. It is not representative of the final pixel-art style.
- Object placement is restricted to predefined demonstration slots; a full drag-to-place editor is a later checkpoint.
- Discovery interactions are authored examples, not a generalized quest or ecology simulation.
- The Creature Nook is currently a placeholder hub.
- The brewing activity proves the reusable hub interaction pattern; additional minigames are not included yet.
- No mobile export presets, audio package, final typography, production assets or device-specific performance pass are included.

## Verification

See `docs/PLAYABLE_SKELETON_V0_1.md` for the architecture and manual verification checklist.

# Playable Skeleton v0.1 — Scope and verification

## Product intent

Prove the mobile-first interaction model before investing in production pixel art:

- Swipe/pinch world navigation.
- Point-and-click object interactions.
- Two separate outdoor spaces.
- A separate `HomeInteriorView` scene with station entry points.
- Contextual hubs for knowledge, brewing and crafting.
- A small discovery-to-cultivation loop.
- Persistent inventory, discoveries and progression.

## Architecture

- `GameState` remains the only autoload and continues to own inventory, flags, experience, discoveries and JSON save/load.
- `Main` owns high-level screen navigation and now uses a compact landscape layout with a contextual side panel.
- `WorldBoard` hosts an isolated `SubViewport`, `Camera2D`, projection renderer and input overlay.
- `GridProjection` converts between logical grid coordinates and projected world coordinates for three-quarter and isometric-style layouts.
- `WorldGridData` provides footprint occupancy validation independently of sprite dimensions.
- `PWAssetDefinition` stores reusable PNG paths, texture dimensions, ground anchors, footprints, selection and sorting metadata.
- `WorldEntity` provides an asset-backed world-object root using ground-anchor positioning and optional `SpriteFrames`.
- `HomeInteriorView` remains a separate reusable scene that emits station-selection and return signals.
- Hub interactions continue to communicate through `GameState` rather than mutating world visuals directly.

## First-playable verification checklist

- [ ] Project opens in Godot 4.7 without parse or import errors.
- [ ] Main scene starts in the Sanctuary.
- [ ] Mouse drag and one-finger touch pan the map.
- [ ] Mouse wheel and two-finger pinch zoom the map.
- [ ] Tapping an object opens the contextual panel.
- [ ] Harvest actions update inventory and XP.
- [ ] Explore navigation loads Whispering Woods and its objects.
- [ ] Discovery actions add journal entries and items.
- [ ] Home navigation instantiates the separate `HomeInteriorView` scene.
- [ ] Field Guide pages can be browsed and studied.
- [ ] Brewing follows the add / stir / stir / finish sequence.
- [ ] Workbench craft consumes materials and grants a Rune Lantern.
- [ ] Moonpetal can be planted, tended and harvested.
- [ ] Rune Lantern can be placed in the Sanctuary.
- [ ] Journal reflects discoveries and inventory.
- [ ] Closing and reopening the project preserves inventory, flags, XP and discoveries.

## CP02 foundation added

- The project reference viewport is now 1280 × 720 landscape.
- The outdoor test world is 32 × 32 projected cells and can switch between three-quarter and isometric-style projections.
- The world camera runs in its own `SubViewport`, so it does not transform the surrounding HUD.
- World objects use separate debug selection bounds and ground-anchor positions.
- `WorldGridData` supports rectangular or custom cell footprints and occupancy checks.
- The initial Art Studio editor plugin supports a transparent 128 × 128 canvas, three starter layers, brush/eraser/eyedropper, a palette, source PNG layer saving/loading, composite PNG export and `.tres` asset-definition export.

## Known limitations

- Current visible world objects remain temporary debug silhouettes drawn by `WorldDebugObject`; the new asset-backed `WorldEntity` is ready for exported PNG definitions but the first production sprite set has not yet been authored.
- Three-quarter and isometric projection values are comparison starting points, not a final art-direction lock.
- The Art Studio is an intentionally small MVP. It does not yet include fill, geometric selection, line/shape tools, animation timeline editing or automatic sprite-sheet packing.
- Object placement is restricted to predefined demonstration slots; a full drag-to-place editor is a later checkpoint.
- Discovery interactions are authored examples, not a generalized quest or ecology simulation.
- The Creature Nook is a placeholder hub.
- The brewing activity proves the reusable hub interaction pattern; additional minigames are not included yet.
- No mobile export presets, audio package, final typography, production assets or device-specific performance pass are included.

## Next implementation checkpoints

1. Run the project and compare the three-quarter and isometric buttons at landscape and PC aspect ratios.
2. Test the grid conversion and occupancy helpers with regression fixtures, then add placement preview/validation.
3. Enable the Art Studio plugin and create the first real transparent PNG sprite collection.
4. Load those PNG definitions into `WorldEntity` and replace the temporary debug silhouettes.
5. Add a few anchored sprite animations and lightweight ambient effects.
6. Export an Android build and validate touch input, safe areas and performance on a physical device.

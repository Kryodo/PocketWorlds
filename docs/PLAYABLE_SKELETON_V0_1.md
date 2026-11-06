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

- `GameState` is the only autoload. It owns inventory, flags, experience, discoveries and JSON save/load.
- `Main` owns high-level screen navigation and composes the UI.
- `WorldBoard` owns outdoor world rendering, map navigation gestures and visual-object hit testing.
- `HomeInteriorView` is a separate reusable scene that emits station-selection and return signals.
- Hub interactions are separate methods in `Main`; they communicate through `GameState` rather than mutating world visuals directly.

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

## Known limitations

- The world artwork is intentionally primitive placeholder drawing. It is not representative of the final pixel-art art direction.
- Object placement is restricted to predefined demonstration slots; a full drag-to-place editor is a later checkpoint.
- Discovery interactions are authored examples, not a generalized quest or ecology simulation.
- The Creature Nook is a placeholder hub.
- The brewing activity proves the reusable hub interaction pattern; additional minigames are not included yet.
- No mobile export presets, audio package, final typography, production assets or device-specific performance pass are included.

## Next checkpoint candidates

1. Validate input, layout and save/load on an actual Android device or emulator.
2. Add true grid-based drag-and-place with footprints and collision/occupancy validation.
3. Replace placeholder world drawing with a small approved pixel-art tileset and object sprites.
4. Add a reusable contextual hub scene/resource pattern.
5. Add one short sprite animation and one reusable environmental effect.

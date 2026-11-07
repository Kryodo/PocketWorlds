# CP03 — Forest asset and ground review

## Goal

Evaluate the scale relationship between the first three asset-backed objects and a real 2:1 diamond ground surface before expanding the forest art library.

## Ground tile set

The generator creates six 192 × 96 transparent diamond textures:

- `forest_grass`
- `forest_grass_flowers`
- `forest_wildflowers`
- `forest_dirt_path`
- `forest_dirt_path_bare`
- `forest_rocky_ground`

Each tile displays at 0.5 scale (96 × 48), matching the current grid projection. Static PNGs are generated in the project; runtime code retains an in-memory image fallback so the map can render before the PNG-generation runner has been used.

## Object integration

The existing Old Oak, Moonpetal Plant and Mossy Rock source PNGs are preserved. Their independent display scale is stored in `PWAssetDefinition.sprite_scale`, and their existing ground anchors remain unchanged. This adjusts only the rendered display size and anchor offset, not the source art or footprint.

The review scene places all three objects on the new ground and includes a short dirt path so their relative sizes and contact points can be assessed together.

## Art Studio

The Art Studio now accepts rectangular document dimensions from 16 to 2048 pixels per axis. Canvas rendering keeps the source aspect ratio, and checker cells are scaled against source pixels. The toolbar also includes a command to generate the forest ground PNGs.

## F6 test order

1. `scenes/tests/generate_forest_ground_tiles.tscn` — creates PNGs, definitions and source-layer documents.
2. `scenes/tests/asset_ground_review.tscn` — visual review of ground and object integration.
3. `scenes/tests/asset_collection_regression.tscn` — checks object PNGs, metadata, source layers, all six ground files and renderer population.
4. `scenes/tests/world_foundation_regression.tscn` — confirms the pre-existing projection and occupancy regression suite.

Godot runtime validation is still required on the user's Godot 4.7 setup. The generated tile art is an initial procedural texture pass, not a final production pack.

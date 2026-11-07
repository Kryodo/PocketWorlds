# Pocket Worlds — First PNG Collection

The first three transparent, asset-backed world sprites establish the authored texture and anchor pipeline:

| Asset | Runtime PNG | Canvas | Ground anchor | Grid footprint |
|---|---|---:|---:|---:|
| Old Oak | `sprites/old_oak.png` | 128 × 128 | (64, 122) | 2 × 2 |
| Moonpetal Plant | `sprites/moonpetal_plant.png` | 128 × 128 | (64, 119) | 1 × 1 |
| Mossy Rock | `sprites/mossy_rock.png` | 128 × 128 | (64, 116) | 1 × 1 |

Each asset has three editable PNG layers (`Shadow`, `Main`, `Highlights`) and a `document.json` under `source_art/<asset_id>/`. The runtime composite is stored in `sprites/`; its `PWAssetDefinition` is in `definitions/`.

## Editing in Godot

1. Open **Project → Tools → Pocket Worlds Art Studio**.
2. Enter the asset ID (`old_oak`, `moonpetal_plant`, or `mossy_rock`) and click **Load**.
3. Select a layer, edit it, and use **Export PNG** to update the source layers, transparent composite and `.tres` definition.

The current editor canvas is 128 × 128. Keep the ground anchor and footprint consistent with the definition unless intentionally changing how the object sits on the grid. The bottom-center ground contact is the sorting origin; artwork extends upward from it.

## Art and rendering notes

- PNGs use RGBA transparency and nearest-neighbor filtering in the world.
- Shadows are deliberately part of the authored sprite, not generated with runtime polygon drawing.
- The grid footprint describes occupied world cells; it is independent of the PNG's visual dimensions.
- The collection is a first visual integration test, not a final biome-wide production library. Remaining map objects and the ground still include debug placeholders.

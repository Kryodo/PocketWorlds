# CP07 — Pocket Worlds Visual Identity

## Status

**Working art direction established for calibration; production approval is pending cross-category testing.**

This document is the central artistic reference for Pocket Worlds. It supersedes the earlier Casual Toon 2.5D candidate in CP06. The direction should now guide test artwork and prompts, but it is not permission to mass-produce or approve a full asset library.

## 1. Visual identity

### Enchanted Hand-Painted 2.5D

A rich, hand-crafted fantasy world combining painterly stylized realism, organic forms, weathered materials, dimensional lighting and an atmospheric enchanted aesthetic.

The intended appearance is hand-painted and carefully rendered, with convincing volume and material definition. It is not photorealistic, flat vector art, pixel art or a toy-like casual town-builder style.

The 2.5D description refers to the visual presentation: objects should have convincing three-dimensional volume while remaining coherent with the game's 2:1 dimetric / three-quarter top-down world. It does not imply a 3D production pipeline.

### Core visual characteristics

- Hand-painted, carefully controlled surface textures.
- Softly defined contours; no heavy black outlines.
- Rich dimensional shading, natural form shadows and restrained ambient occlusion.
- Material-specific imperfections in wood, stone, foliage, fabric and other surfaces.
- Warm, inviting details balanced with mysterious and ethereal elements.
- Detailed environments with readable silhouettes and a deliberate mobile-first visual hierarchy.
- Subtle magical illumination and atmospheric effects used selectively.
- Believable ground contact and shadows that visually connect objects to their terrain.

### Surface finish: painterly, not brushy

The artwork should look intentionally rendered. Texture must clarify material and form rather than become decoration.

Prefer controlled painted transitions, layered material colour, selective fine detail and coherent highlights. Avoid obvious random brush strokes, smeared or muddy textures, sketchy strokes, watercolor bleed, noisy over-texturing and inconsistent surface treatment.

A hand-painted appearance does not require visible brush marks. The finish should feel polished and deliberate.

## 2. Shape language and composition

- Prefer organic, crafted, slightly irregular forms over perfect geometric primitives.
- Use believable proportions and construction details. Avoid excessive toy-like rounding or inflated proportions.
- Give each object a strong, recognisable outer silhouette.
- Keep small objects simple enough to read at normal mobile viewing size.
- Use asymmetry, natural growth patterns, weathering and handmade construction to give objects character.
- Keep the ground-contact area visually understandable even when foliage, roofs or other forms overhang it.
- Avoid decorative details that obscure the object's primary shape or interaction point.

The logical footprint is a placement and occupancy property, not a limit on the visible artwork. Tree crowns, roof eaves, branches, roots and other forms may extend beyond their occupied cells.

## 3. Material language

Materials should be visually distinct and appropriate to the subject. Texture, roughness, highlights, colour variation and edge treatment should reinforce the material rather than compete with one another.

| Material | Intended treatment |
|---|---|
| Wood | Warm or world-dependent natural colour, visible grain, knots, joints, worn edges and handcrafted construction. |
| Stone | Weighty, varied surfaces, softened weathering, cracks, chips, moss and believable contact with the terrain. |
| Foliage | Layered leaves with clear volume and controlled variation; avoid noisy individual-leaf detail that collapses at mobile scale. |
| Soil and earth | Subtle value and colour variation, compact readable texture, natural transitions into grass and stone. |
| Metal | Restrained, material-appropriate highlights, patina or wear; avoid generic chrome gloss unless the world requires it. |
| Fabric, leather and rope | Soft but clearly differentiated forms, seams, folds and use-related wear at an appropriate detail level. |
| Crystal and magical matter | Clear faceted or organic form, luminous colour where appropriate, and restrained internal or emitted light. |
| Bone, fossil and relic materials | Aged, dry, weathered surfaces with enough contrast to remain legible without looking like plastic props. |

Do not apply the same texture treatment to every material. A wood beam, a mossy rock and a crystal should not look as though they were painted with the same surface brush.

## 4. Lighting, depth and grounding

### Dimensional rendering

Use coherent light and shadow to explain volume. Objects should have readable front, side and top planes where their form calls for them. Avoid flat colour fills and excessive outline-based separation.

### Directional consistency

A given asset batch and world scene must share a coherent key-light direction and shadow logic. The exact production direction should be selected during calibration rather than assumed independently by each generation prompt.

Different worlds and time-of-day settings may change the light colour, intensity and atmosphere, but objects that appear together must still look as though they share the same lighting environment.

### Ambient occlusion and contact shadows

Use ambient occlusion to reinforce intersections and depth, not to create dirty black borders. Contact shadows should connect trunks, roots, rocks, foundations, feet and other contact points to the terrain.

Ground shadows must not float separately from the subject, become excessively soft halos, or turn into an opaque dark blob. Moving creatures may later use a stable separate ground shadow if that produces cleaner animation.

## 5. Colour and world atmosphere

The underlying rendering identity remains consistent across Pocket Worlds. Individual worlds can have their own palettes, materials, lighting and atmosphere.

| World character | Possible visual language |
|---|---|
| Enchanted woodland | Rich natural greens, moss, earth, warm wood, floral accents and filtered light. |
| Crystal world | Cool or luminous stone, crystalline materials, mineral colour and controlled magical illumination. |
| Elemental world | Stronger world-specific colour identity, unusual materials and more dramatic environmental light. |
| Ancient or subterranean world | Weathered stone, aged materials, deep values, warm local light and mysterious illumination. |

These are examples, not final biome palettes. Avoid forcing every world into the same green-brown forest palette or making every magical object glow.

Cozy does not require constant brightness or high saturation. Warm lantern light, firelight or a small illuminated sanctuary can create warmth within a darker, mysterious environment.

## 6. Asset-category direction

### Buildings and structures

Buildings should feel hand-built, old, lived-in and integrated with their surroundings.

Suitable visual vocabulary includes timber frames, weathered stone foundations, mossy roofs, shingles, thatch, roots, aged plaster, handmade doors, warm windows, chimneys, signs and small crafted details.

Future structures may include cottages, workshops, smithies, taverns, towers, bridges, sanctuaries, caves, ruins and dungeons.

Do not use modern factories, conventional modern town-builder production buildings, generic suburban houses, modern community buildings or industrial architecture unless a future world explicitly calls for a deliberate contrast.

### Nature and terrain

Vegetation should have rich, varied silhouettes and organic growth. Trees, bushes, flowers, mushrooms, roots, logs, rocks, moss and ground cover should feel related to the same environment without becoming repetitive clones.

Terrain artwork must connect cleanly and retain the same perspective, lighting and surface finish as its objects. Ground tiles are their own category and must be evaluated as a continuous surface, not only as isolated pictures.

### Relics, discoveries and props

Objects should suggest history, function or mystery. Useful vocabulary includes ancient stonework, carved symbols, rune markers, old tools, bones, skulls, crystals, crates, barrels, lanterns, signs, caches and unusual crafted objects.

A relic should not look like an ordinary generic decoration with a rune pasted onto it. Its materials, wear and form should make it feel like an object with a past.

### Creatures

Creatures should be expressive, appealing and immediately recognisable, while retaining the same dimensional shading, material richness, light direction and controlled surface rendering as the environment.

Avoid a creature that looks like a flat cartoon sticker placed into a richly rendered world. Its contact shadow, feet and ground baseline must be stable and convincing.

### UI and item artwork

The seven initial resource icons should use the same rendering identity, simplified appropriately for small display sizes. Prioritise distinct silhouettes and material recognition over tiny decorative details.

## 7. Detail hierarchy and mobile readability

Not every object should carry the detail density of a full environment illustration.

Use three practical detail levels:

1. **Focal assets:** important buildings, discoveries, relics and landmarks can carry richer construction details and material variation.
2. **Supporting world assets:** ordinary plants, rocks, logs and props should retain material character but use fewer small details.
3. **Small assets and icons:** simplify shapes, highlights and textures so they remain instantly readable at their actual display size.

Place detail where it helps explain form, material, age, function or rarity. Reduce detail that disappears, flickers or turns into visual noise at normal gameplay zoom.

The final judge is the asset at normal game scale, not a zoomed-in source image.

## 8. Magical effects and reward feedback

The world should feel enchanted through its architecture, materials, objects, vegetation and atmosphere before any particles or glow effects are added.

Use magical illumination, particles, small reveals and distinctive effects selectively for meaningful interactions, rare discoveries, upgrades and collection moments. Avoid outlining every object in glow or making every resource excessively luminous.

Progression can feel rewarding through richer construction, repaired materials, new details, subtle magical activation, environmental changes and meaningful visual reveals. It does not need toy-like exaggeration or oversized generic mobile-game effects.

## 9. Explicit exclusions and failure modes

Reject or revise artwork that relies on:

- Heavy black outlines or comic-style contouring.
- Flat vector fills or generic icon-like illustration as the world-asset finish.
- Excessively toy-like, plastic, inflated or uniformly rounded forms.
- Photorealistic rendering that clashes with the stylized world.
- Pixel-art rendering as the default asset direction.
- Obvious random brush strokes, muddy smears or uncontrolled painterly noise.
- Excessive micro-detail that becomes unreadable at mobile scale.
- Inconsistent camera angle, top-plane visibility or ground-plane orientation.
- Inconsistent light direction within one asset batch.
- Floating objects, detached shadows, bright edge halos or dark extraction fringes.
- Generic modern town-builder architecture.
- Magical glow applied indiscriminately to ordinary objects.

## 10. Approval gates

The working direction is ready for production approval only after the calibration set demonstrates:

- A coherent appearance across one building, one tree, one small plant, one rock, one creature and ground artwork.
- Distinct, convincing material definition without uncontrolled brushiness.
- Consistent 2.5D perspective and world alignment.
- A useful detail hierarchy at normal mobile viewing size.
- Natural contact shadows and convincing ground integration.
- The ability to vary world palettes and atmosphere without losing the shared identity.
- A repeatable 2D image-generation workflow that does not require manual 3D modelling or hand-built structural maps.

**CP07 visual identity approval means the style is reproducible across the calibration categories. It does not mean a complete biome or asset library is approved.**

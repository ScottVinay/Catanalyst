---
status: in-progress
started_datetime: 2026-09-06T15:01:45Z
completed_datetime:
---

# TASK-059 artwork prompts

Implementation notes for TASK-059. Priority: P2. Requirements: REQ-022, REQ-023.

Generated with the built-in image_gen tool. Original PNG outputs are copied unchanged into `HexIQ/Assets.xcassets/`. Terrain opacity is controlled in `BoardArtwork.swift` by `// # terrainalpha`.

## Terrain-brick

```text
Use case: stylized-concept
Asset type: one square background illustration for a small hexagonal terrain tile in a native Catan board planner.
Primary request: Brick / clay hills. three broad terracotta clay terraces with softly rounded edges and a few large brick-like strata.
Style: professional, minimal cartoon board-game artwork. Cohesive flat painted shapes with very subtle soft shading, clean edges, calm restrained palette, no texture noise.
Composition: top-down decorative terrain impression, full-bleed square colour background, very sparse detail kept in the outer half of the image, quiet unobstructed centre for a number token. The square will be cropped to a point-up hexagon. Keep terrain recognisable at 60 pixels wide without busyness.
Palette: muted terracotta and rust, low contrast within the tile.
Constraints: exactly one terrain illustration, not a sprite sheet. No outline or hex border, no text, no numbers, no token, no buildings, no frame, no watermark, no sky, no horizon, no photorealism. Keep at least 65 percent as broad plain colour areas. 1024 by 1024 pixels.
```

## Terrain-ore

```text
Use case: stylized-concept
Asset type: one square background illustration for a small hexagonal terrain tile in a native Catan board planner.
Primary request: Ore / rocky hills. two broad angular slate-blue mountain shapes and one small rock cluster, no snow.
Style: professional, minimal cartoon board-game artwork. Cohesive flat painted shapes with very subtle soft shading, clean edges, calm restrained palette, no texture noise.
Composition: top-down decorative terrain impression, full-bleed square colour background, very sparse detail kept in the outer half of the image, quiet unobstructed centre for a number token. The square will be cropped to a point-up hexagon. Keep terrain recognisable at 60 pixels wide without busyness.
Palette: muted blue-grey and slate, low contrast within the tile.
Constraints: exactly one terrain illustration, not a sprite sheet. No outline or hex border, no text, no numbers, no token, no buildings, no frame, no watermark, no sky, no horizon, no photorealism. Keep at least 65 percent as broad plain colour areas. 1024 by 1024 pixels.
```

## Terrain-wheat

```text
Use case: stylized-concept
Asset type: one square background illustration for a small hexagonal terrain tile in a native Catan board planner.
Primary request: Wheat fields. two simple gently curved golden field bands with just two small clusters of wheat stalks.
Style: professional, minimal cartoon board-game artwork. Cohesive flat painted shapes with very subtle soft shading, clean edges, calm restrained palette, no texture noise.
Composition: top-down decorative terrain impression, full-bleed square colour background, very sparse detail kept in the outer half of the image, quiet unobstructed centre for a number token. The square will be cropped to a point-up hexagon. Keep terrain recognisable at 60 pixels wide without busyness.
Palette: muted harvest gold and ochre, low contrast within the tile.
Constraints: exactly one terrain illustration, not a sprite sheet. No outline or hex border, no text, no numbers, no token, no buildings, no frame, no watermark, no sky, no horizon, no photorealism. Keep at least 65 percent as broad plain colour areas. 1024 by 1024 pixels.
```

## Terrain-lumber

```text
Use case: stylized-concept
Asset type: one square background illustration for a small hexagonal terrain tile in a native Catan board planner.
Primary request: Lumber / forest. two small groups of three rounded stylized evergreen trees, broad simple canopy shapes.
Style: professional, minimal cartoon board-game artwork. Cohesive flat painted shapes with very subtle soft shading, clean edges, calm restrained palette, no texture noise.
Composition: top-down decorative terrain impression, full-bleed square colour background, very sparse detail kept in the outer half of the image, quiet unobstructed centre for a number token. The square will be cropped to a point-up hexagon. Keep terrain recognisable at 60 pixels wide without busyness.
Palette: muted forest green and sage, low contrast within the tile.
Constraints: exactly one terrain illustration, not a sprite sheet. No outline or hex border, no text, no numbers, no token, no buildings, no frame, no watermark, no sky, no horizon, no photorealism. Keep at least 65 percent as broad plain colour areas. 1024 by 1024 pixels.
```

## Terrain-wool

```text
Use case: stylized-concept
Asset type: one square background illustration for a small hexagonal terrain tile in a native Catan board planner.
Primary request: Wool / pasture. two small round white sheep on gently curved meadow bands, tiny charcoal faces.
Style: professional, minimal cartoon board-game artwork. Cohesive flat painted shapes with very subtle soft shading, clean edges, calm restrained palette, no texture noise.
Composition: top-down decorative terrain impression, full-bleed square colour background, very sparse detail kept in the outer half of the image, quiet unobstructed centre for a number token. The square will be cropped to a point-up hexagon. Keep terrain recognisable at 60 pixels wide without busyness.
Palette: muted light meadow green and cream, low contrast within the tile.
Constraints: exactly one terrain illustration, not a sprite sheet. No outline or hex border, no text, no numbers, no token, no buildings, no frame, no watermark, no sky, no horizon, no photorealism. Keep at least 65 percent as broad plain colour areas. 1024 by 1024 pixels.
```

## Terrain-desert

```text
Use case: stylized-concept
Asset type: one square background illustration for a small hexagonal terrain tile in a native Catan board planner.
Primary request: Desert. three wide overlapping sand dunes with smooth curved crests, almost no fine detail.
Style: professional, minimal cartoon board-game artwork. Cohesive flat painted shapes with very subtle soft shading, clean edges, calm restrained palette, no texture noise.
Composition: top-down decorative terrain impression, full-bleed square colour background, very sparse detail kept in the outer half of the image, quiet unobstructed centre for a number token. The square will be cropped to a point-up hexagon. Keep terrain recognisable at 60 pixels wide without busyness.
Palette: muted sand and warm beige, low contrast within the tile.
Constraints: exactly one terrain illustration, not a sprite sheet. No outline or hex border, no text, no numbers, no token, no buildings, no frame, no watermark, no sky, no horizon, no photorealism. Keep at least 65 percent as broad plain colour areas. 1024 by 1024 pixels.
```

## Terrain-ocean

```text
Use case: stylized-concept
Asset type: one square background illustration for a small hexagonal terrain tile in a native Catan board planner.
Primary request: Ocean. three gently curved broad bands of blue water with only a few soft wave highlights.
Style: professional, minimal cartoon board-game artwork. Cohesive flat painted shapes with very subtle soft shading, clean edges, calm restrained palette, no texture noise.
Composition: top-down decorative terrain impression, full-bleed square colour background, very sparse detail kept in the outer half of the image, quiet unobstructed centre for a number token. The square will be cropped to a point-up hexagon. Keep terrain recognisable at 60 pixels wide without busyness.
Palette: muted sea blue and pale aqua, low contrast within the tile.
Constraints: exactly one terrain illustration, not a sprite sheet. No outline or hex border, no text, no numbers, no token, no buildings, no frame, no watermark, no sky, no horizon, no photorealism. Keep at least 65 percent as broad plain colour areas. 1024 by 1024 pixels.
```

## Building-settlement

```text
Use case: stylized-concept
Asset type: one small game-piece illustration on a genuinely transparent background for a native Catan board planner.
Primary request: a single compact cottage settlement with one pitched roof, a door and one window.
Style: polished minimal cartoon board-game piece, slight isometric three-quarter view, bold crisp black outer and inner outlines, simple broad shapes, softly shaded white and light neutral grey surfaces only. This neutral artwork will be tinted with the owner's colour by the app, so all surfaces must be greyscale and all lines black.
Composition: centred, isolated, fills 86 percent of square canvas, strong readable silhouette at 28 pixels, tiny amount of detail. Flat base. All parts visible.
Constraints: exactly one piece, actual transparent alpha outside the building. No ground, no cast shadow, no platform, no text, no numbers, no frame, no watermark, no gradients in the background, no checkerboard painted in the image. 1024 by 1024 pixels.
```

## Building-city

```text
Use case: stylized-concept
Asset type: one small game-piece illustration on a genuinely transparent background for a native Catan board planner.
Primary request: a compact city formed from a connected pair of houses and one squat square tower, clearly larger and different in silhouette from a single cottage.
Style: polished minimal cartoon board-game piece, slight isometric three-quarter view, bold crisp black outer and inner outlines, simple broad shapes, softly shaded white and light neutral grey surfaces only. This neutral artwork will be tinted with the owner's colour by the app, so all surfaces must be greyscale and all lines black.
Composition: centred, isolated, fills 86 percent of square canvas, strong readable silhouette at 28 pixels, tiny amount of detail. Flat base. All parts visible.
Constraints: exactly one piece, actual transparent alpha outside the building. No ground, no cast shadow, no platform, no text, no numbers, no frame, no watermark, no gradients in the background, no checkerboard painted in the image. 1024 by 1024 pixels.
```

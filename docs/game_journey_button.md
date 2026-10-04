# Journey button reference

Asset: `assets/images/icons/game_journey_button.png`.

Generated with the built-in `image_gen` tool from the user's cropped Journey button reference. The transparent skin includes the cream beveled button, softly shaded folded map, orange location pin, corner bamboo and empty label band. `GameJourneyButton` overlays the live Vietnamese label and keeps the existing stage-map callback and tooltip. This replaces the earlier flat custom-painted map.

Preview: `docs/games_ui_preview.png`.

The button now occupies a 92 × 92 design-unit area (previously 68 × 68). The caption and hit area scale with it; the Games header reserves space beside the centered title to prevent overlap on small screens.

The button sits 8 design units from the right edge. Its transparent top margin is lifted by up to 12 units into the top inset, bringing the visible cream button close to the safe-area edge. The title and subtitle positions stay fixed.

## Final generation prompt

Use case: precise-object-edit. Input images: the SMALL cropped cream 'Hành trình' journey button is the exact visual reference; the other full app screen is context only, do not recreate the full screen. Asset type: one production transparent PNG skin for that small journey button, WITHOUT text so the app can overlay the live Vietnamese label. Primary request: reproduce the small supplied reference button as closely as possible: a soft warm pale ivory rounded almost-square button with a fine white beveled rim, soft golden ambient shadow, and a charming miniature three-dimensional folded PAPER MAP with a SMALL orange location pin above the right fold. The map has three softly folded panels, pale buttery parchment edges, sage and jade-green land patches and thin pale winding road details, angled perspective, subtle crease depth and gentle soft highlights. Map must look like the reference's polished soft rounded 3D storybook game artwork, not a flat vector symbol, not a generic zigzag graph. Map is centered in the upper half of the button and modestly sized, leaving generous cream around it. Location pin is small relative to the map, just 25% of map height, glossy orange with a small pale circular hole. Preserve the reference's thin airy green bamboo sprig protruding from the TOP RIGHT corner, with three slender pointed green leaves on a curved fine stem; a tiny pale green leaf at lower left beside the map. Composition: square transparent canvas, the cream button occupies x8%-91%, y17%-96%, rounded corners roughly 22% of button width. The tiny bamboo sprig extends up to the top right edge, like the reference. Map occupies x29%-74%, y29%-65%. Bottom x14%-84%, y73%-91% is a simple softly raised pale golden cream label capsule/band, EMPTY, reserved for live text 'Hành trình'; DO NOT render any text. Keep exact warm muted reference palette and restrained soft 3D style. No large orange pin, no hard black outlines, no chunky leaves, no checkmark, no additional objects, no scenery, no UI screenshot, no other buttons, no watermark. Outside this single small cream button and its corner leaves must be true transparent alpha.

## Validation

`flutter analyze lib/screen/game_hub/view`

`flutter test test/screen/game_hub/game_hub_view_test.dart`

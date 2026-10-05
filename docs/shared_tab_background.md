# Shared landscape tab background

Current asset: `assets/images/backgrounds/shared_landscape.png`.

This is the original landscape file supplied by the user, used without image edits or regeneration: blue sky framed by bamboo, misty mountains, pagodas, waterfalls and a turquoise lake. It is centered with `BoxFit.cover` to fill the viewport without stretching. Unused generated backgrounds have been removed from the asset bundle.

`lib/screen/home/widgets/shared_tab_background.dart` renders the same image behind Learning, Games, Progress and Personal. The backdrop fills the viewport and stays fixed as content scrolls. `GameHubView` uses this shared backdrop in both the main app and standalone game preview. Home keeps its own scene. Existing card artwork, navigation and callbacks are preserved.

Current Games preview: `docs/games_ui_preview.png`.

## Previous background generation prompt (historical)

Use case: precise-object-edit. Edit target: the supplied minimalist cream mobile app background. Primary request: refine this into a more beautiful polished Chinese watercolor background used across Learning, Games, Progress and Personal, while preserving the calm simple layout and generous blank central space. Preserve portrait 9:16 composition and warm ivory #FFFAF0 base. Improve the elegance of the bamboo: finer graceful curved stems and airy pointed leaves, muted jade and soft sage instead of flat grey, watercolor variations and delicate translucency; keep it restricted to the top RIGHT corner and lower LEFT corner, not a border. Make three softly overlapping mountain ridges at the bottom 14% with slightly more depth, a pale cool jade layer in the distance and warm sage foreground, thin luminous ivory mist separating them and dissolving upward; keep all mountains subtle and low contrast. Add a barely visible warm ivory to pale celadon wash in the outer corners, like softly lit premium rice paper; surface smooth with extremely faint organic watercolor grain, no busy paper texture. Keep the central 80-85% essentially plain warm ivory and the upper center clear for dark headings. Visual character: refined modern Chinese ink wash, delicate and inviting, clean premium mobile app backdrop. Restrained muted color, no vivid green, no bright color, no ornate ornaments, no flowers, no temple, no buildings, no panda, no characters, no icons, no words, no buttons, no borders, no watermark. The image should be more graceful and dimensional, still quiet and simple.

## Validation

`flutter analyze lib/screen/home lib/screen/game_hub lib/screen/dragon_panda/screens/game_hub`

`flutter test test/screen/home test/screen/game_hub/game_hub_view_test.dart`

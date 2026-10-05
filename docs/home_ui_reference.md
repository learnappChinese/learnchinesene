# Home UI reference

The main app (`lib/screen/home/home_screen.dart`) and the standalone Dragon Panda preview share the dashboard in `lib/screen/home/widgets/home_dashboard.dart`.

- `flutter_screenutil` uses `Size(440, 956)`, the logical viewport of iPhone 16 Pro Max.
- The layout follows the supplied reference: Chinese greeting, streak badge, parchment lesson hero, green learning buttons, three statistics cards, today's lesson, four quick actions, daily challenge, and a floating five-tab navigation bar with a central panda.
- Existing GetX controller, statistics, refresh, feature access rules, and screen destinations remain integrated with the main app. Navigation is restored to learning, games, central home, progress, personal, mapped to controller indices (1, 2, 0, 3, 4). There is exactly one Home button, in the center, with no visible text label. The quick-action section's “Xem tất cả” opens Learning.
- The latest section reference uses compact statistics with icons beside values, pale mountain and pagoda silhouettes, panda section badges, and green “Xem tất cả” links. Today's lesson has a green continue button and a leaf sprig. Continue and Start Learning share `HomeGreenButton`, including its gradient, bright border, raised base, and shadow. Quick actions have pastel tiles and centered labels, with the circular arrows removed per the follow-up request. The daily challenge has a target icon, progress bar, and gift icon.
- The lower dashboard, from the learning sections through the floating navigation and home indicator, uses the very pale ivory background (`#FFFEF9`, `homePageBackground`) from the user's color reference. Lesson and challenge cards have white surfaces, muted jade borders and stronger soft shadows. Statistics and quick-action tiles use borders tinted to match their artwork, separating them from the page background.
- The floating navigation bar has a white surface, a muted jade rim and a stronger soft shadow. Selected destinations use the original green primary (`homeGreen`, `#45BC09`) for icons and labels, with a pale green fill and border. The central Home circle also uses this green when selected and a neutral fill when another tab is selected. These styles apply to the shared navigation bar on every tab.
- Start Learning and Continue use `HomeGreenButton` with the same original green primary (`homeGreen`, `#45BC09`), derived highlight and shadow shades, and white text and icons. This green primary is the user's preferred Home palette, shared by the main app and standalone preview.
- Tablet and desktop retain the existing navigation rail; the dashboard follows the available content width and can scroll.
- Widget sizes use ScreenUtil extensions directly (`.w`, `.h`, `.sp`). There is no additional sizing multiplier or custom font-size helper passed through the home widgets.
- The streak badge matches the supplied crop: flame on the left, streak count above the label, a centered orange chevron on the right, and a cream pill with a pale green border. `HomeStreakBadge` keeps the live streak value and opens progress when tapped. Its rendered detail is saved as `docs/home_streak_badge_preview.png`.
- The dashboard paints one continuous scene behind the status bar and content. Its greeting respects the top safe inset, and parchment overlays follow the scene's vertical scale on phones with a notch. The standalone preview uses the same layout.
- Hero content uses bounds measured on the artwork: the label is centered inside the wooden plaque, headline and wrapping description stay inside the paper, and the learning button fits between the frame edges. Text scales down to its allotted region if necessary. Rendered alignment was checked at 320, 393, and 440 pixel widths with and without a top safe inset.
- The scroll content is at least as tall as the viewport. The area behind the bottom navigation and home indicator uses the same plain pale ivory backdrop; the garden footer has been removed from Home.
- Lesson progress (3/8), challenge progress (6/10), and their descriptive text remain presentation examples, as in the previous dashboard. Live statistics retain the previous mappings.
- The standalone Dragon Panda app is a game preview: its callbacks open the existing game hub. Learning features are wired in the main app.

## Artwork

Saved assets:

- `assets/images/backgrounds/home_garden.png`: parchment, waving panda, and bamboo mountain scene.
- `assets/images/characters/home_panda_peek.png`: transparent panda for the greeting avatar and center navigation.
- `assets/images/characters/home_title_panda.png`: tilted panda portrait used by section-title badges.
- `assets/images/characters/home_nav_panda.png`: front-facing panda in a green vest for the floating Home item.
- `assets/images/effects/home_leaf_sprig.png`: transparent matte three-leaf sprig matching the supplied card and Home-button references. In the latest reference, sprigs decorate the lesson's continue button and flank the central Home circle.
- `assets/images/backgrounds/home_metric_streak.png`, `home_metric_lessons.png`, and `home_metric_xp.png`: dedicated statistics backgrounds with baked-in flame, book, and star icons, rounded misty mountains, and Chinese architecture. The numerical values and Vietnamese labels remain Flutter text. Generation and refinement prompts are saved in `docs/home_metric_assets.md`; the detail preview is `docs/home_metrics_preview.png`.

Rendered previews: `docs/home_ui_preview.png` (440 × 956 logical pixels, matching iPhone 16 Pro Max) and `docs/home_ui_sections_preview.png` (316 × 388 logical pixels, matching the latest section crop). Both are captured at 2× resolution with local preview fonts, so native font rendering may vary. The original generated scene `home_garden.png` is retained as the source of the edited version.

The raster artwork was created with the built-in `image_gen` tool, inspired by the supplied screenshot rather than extracted from it. The statistics use generated raster art; the quieter mountain accents behind the lesson and challenge are drawn with a native Flutter painter. Text, progress bars, cards, navigation, and buttons are Flutter widgets. All imagery is bundled and requires no network requests.

### Generation prompt

Use case: illustration-story. Asset type: production background artwork for a Flutter Chinese learning app home screen. Create ONE landscape nearly square illustration, aspect ratio 1.16:1 (e.g. 1200 wide x 1030 high), inspired by a premium adorable 3D storybook mobile game. Bright pale blue sky, misty Chinese karst mountains, distant beautiful traditional pagodas on the RIGHT, luminous clouds, bamboo framing BOTH left and right edges, green foliage at bottom. IMPORTANT precisely reserved UI spaces: top 30 percent is quiet scenic sky with no character or foreground objects, so app greeting can overlay it. LEFT foreground from x4 percent to x56 percent and y34 percent to y96 percent: a big BLANK ivory parchment board with realistic rounded bamboo/wood frame, lightly weathered creamy paper, fully empty for Flutter UI text and buttons. A small horizontal BLANK honey colored wooden plaque attached at its upper edge (x10 to40 percent,y33to40 percent), no writing. On RIGHT foreground from x58 percent to x96 percent, y49 percent to y95 percent: extremely cute fluffy baby panda sitting on a mossy rock, wearing green Chinese traveler clothes, red scarf, a broad straw conical hat and rolled backpack, smiling happily waving its left paw, squinting cute crescent eyes, small rosy cheeks. Panda is seated, not warrior, no weapon. One warm glowing golden Chinese lantern on far right hanging around y40-65 percent, lantern can have a single red 中 character. Soft green leaves on the bamboo board edges. Illustration should feel like polished rounded tactile 3D plush artwork with warm soft lighting, matching a Vietnamese Chinese learning screen. Keep parchment absolutely blank and broad, no interface, no statistics cards, no buttons, no words, no logo, no watermark. Full bleed scenic image.

### Scene refinement prompt

Use case: precise-object-edit. Edit target: supplied Chinese app background illustration. Preserve the same image size, scenery, fluffy waving panda character, lighting, bamboo border, golden lantern and mountain architecture. Make ONLY these composition changes to match the app reference: 1) narrow the cream parchment board on the LEFT: its right wooden frame should be at 52 percent of image width instead of 56 percent, leaving its left edge and its vertical top and bottom positions unchanged. 2) Relocate the small blank wooden title plaque on the top edge of the board so its LEFT edge is at 9 percent image width and RIGHT edge at 40 percent image width; preserve its vertical center, rounded wood style, and blank surface. 3) Shift the seated panda and rock slightly LEFT so panda left paw begins at 56 percent of width and panda's right edge remains around94 percent. Keep it smiling, waving, green clothes red scarf and straw hat. Leave all parchment and plaque completely blank with no text or buttons. Do not introduce any UI, lettering, labels, cards, frame borders or logos. Preserve warm bright polished 3D storybook style and other background details.

### Navigation panda prompt

Use case: stylized-concept. Asset type: transparent PNG mascot for the central Home button of a Vietnamese Chinese learning app. One extremely cute fluffy baby panda peeking over a round button (do NOT draw the button). Precisely a small rounded white panda head, two fluffy black round ears, friendly large sparkling black eyes in black eye patches, rosy cheeks, tiny happy smiling mouth, very short chubby white shoulders and two black fluffy paws at lower left and lower right, paws reaching forward to rest on the future button rim. Front view perfectly symmetric near square composition. The face must be fully visible, eyes open friendly like adorable 3D animated plush character, with realistic soft fluffy fur, pale cream white fur, warm gentle daylight. Panda head fills the upper 75 percent of the canvas, paws at bottom around 85 percent. No hat, no clothes, no neck scarf, no accessories, no background, no text, no circle, no scenery, no button. Isolated transparent background with tight framing and small margins, premium polished 3D storybook mobile game style. This mascot is decorative artwork above a vivid green Home button.

### Previous footer prompt (historical)

Use case: illustration-story. Asset type: landscape bottom background strip for a Chinese learning app, 3:1 wide horizontal composition. A tranquil turquoise jade stream flowing across the center bottom through a lush sunny bamboo garden, mossy stones, rounded bright green bamboo leaves and pink lotus blossoms at both bottom corners, vertical bamboo trunks framing far left and far right edges. Very soft warm 3D storybook illustration, painterly atmospheric light, shallow depth of field distant lush greenery. TOP one-third should dissolve into a near blank pale warm ivory cream mist matching color #FFFAF0 so it can fade behind a cream app interface. Bottom two-thirds colorful nature with reflective water flowing through the middle, plants all around edges. Similar to an adorable panda Chinese learning app illustrated forest background. No character, no panda, no board, no parchment, no wood plank, no icons, no labels, no UI elements, no text, no watermark. Full bleed decorative garden floor scenery.

### Leaf refinement

The supplied quick-action, navigation, and statistics crops guided a refinement of the original leaf asset: exactly three slender pointed leaves, an airy diagonal fan, matte pale and medium green shading, and a short thin stem. The image is transparent and renders at 22–44 logical pixels. Corner decorations ignore pointer input, and card sprigs can extend beyond rounded corners.

## Validation

```sh
flutter analyze lib/screen/home lib/screen/dragon_panda/screens/home test/screen/home/home_dashboard_test.dart
flutter test test/screen/home/home_dashboard_test.dart
```

Widget tests cover 320, 393, and 600 pixel widths, learning action callbacks, a single central Home button without visible text, navigation index mapping, reactive statistics, quick-action “Xem tất cả,” Games access, and tab switching with a 62 pixel top safe inset. Rendered previews were inspected to check the continuous scene across the status bar, align the parchment text, and match the compact sections and bottom navigation.

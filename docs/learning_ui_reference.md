# Illustrated Learning tab

The main app's Học tập tab uses `lib/screen/home/widgets/home_learning_tab.dart`. It keeps existing GetX destinations and feature access checks: Practice opens the practice menu; Vocabulary opens HSK; AI Lessons and AI Conversation retain subscription gating. The shared bottom bar has one central Home button with no visible label.

The current screen background is the user-supplied landscape used by Learning, Games, Progress and Personal: `assets/images/backgrounds/shared_landscape.png`. It is rendered by `SharedTabBackground`. See `docs/shared_tab_background.md` for the current backdrop details.

Four card assets were created with the built-in `image_gen` tool using the supplied learning-screen screenshot as the reference. Each card now uses one continuous full-card image, without separately cropped illustration layers. Headings, descriptions, white borders and circular arrow buttons are Flutter widgets. Descriptions wrap naturally and cards can grow to fit them instead of truncating text. Status bar content stays native. This is newly generated artwork rather than the source design assets.

## Saved assets

- `assets/images/backgrounds/learning_practice.png`
- `assets/images/backgrounds/learning_vocabulary.png`
- `assets/images/backgrounds/learning_lessons.png`
- `assets/images/backgrounds/learning_conversation.png`

## Preview and validation

`docs/learning_ui_preview.png` is the rendered 440 × 956 view captured at 2× resolution with local preview fonts. `docs/learning_ui_reference_preview.png` uses the reference's aspect ratio (440 × 782). Native font rendering may vary.

Widget checks cover narrow phones, standard phones, wide screens, all four card callbacks, the single Home button and integration with main-app tab switching.

## Final prompt set

### background

Use case: precise-object-edit. Input: the user's learning screen screenshot is the visual reference. Create one production illustration asset based closely on the specified part of that screenshot, WITHOUT app UI text, navigation, status bar, or button shapes. Soft polished 3D storybook rendering, bright cream daylight, rounded shapes, miniature lush bamboo, Chinese karst mountains and traditional architecture, pastel colors. Preserve useful quiet negative space for Flutter text. No watermark. Asset type: full screen background. Portrait 9:16. Warm almost-white ivory #FFFAF0 background, bamboo trunks and clusters of shiny green elongated leaves framing the upper left edge and upper right corner. Soft pale mint Chinese karst silhouettes and white clouds across the middle around y18%-32%, cream lower 65% mostly empty. A few tiny floating green leaves at y10% and y25%. Central x14%-86% should remain light and visually quiet for a large app heading. No panda, no cards, no icons, no text, no underline. Fill whole canvas with warm ivory, no transparency.

### practice

Use case: precise-object-edit. Input: the user's learning screen screenshot is the visual reference. Create one production illustration asset based closely on the specified part of that screenshot, WITHOUT app UI text, navigation, status bar, or button shapes. Soft polished 3D storybook rendering, bright cream daylight, rounded shapes, miniature lush bamboo, Chinese karst mountains and traditional architecture, pastel colors. Preserve useful quiet negative space for Flutter text. No watermark. Asset type: first practice card artwork. Wide landscape 3.3:1 aspect ratio, full bleed rectangle; UI will add rounded corners and white border. In the LEFT x0%-35%, green bamboo and leaves frame a large glossy rounded green square with a white crossed pen-and-brush symbol, small stacked cream books in bottom-left, a small black Chinese ink pot and brush, and a light parchment card leaning at the lower center-left bearing the single Chinese character 学. Match the green practice illustration in the screenshot. On RIGHT x40%-100% pale mint misty Chinese mountains, jade lake, green miniature pagoda far right, a few bamboo leaves lower-right. The text region x38%-84%, y14%-61% must be nearly blank pale cream/mint; all substantial mountain details stay at bottom y65%-100% and right x86%-100%. Do not draw Vietnamese words, app labels or any arrow/button. Only 学 on the small parchment may appear.

### vocabulary

Use case: precise-object-edit. Input: the user's learning screen screenshot is the visual reference. Create one production illustration asset based closely on the specified part of that screenshot, WITHOUT app UI text, navigation, status bar, or button shapes. Soft polished 3D storybook rendering, bright cream daylight, rounded shapes, miniature lush bamboo, Chinese karst mountains and traditional architecture, pastel colors. Preserve useful quiet negative space for Flutter text. No watermark. Asset type: vocabulary card artwork. Wide landscape 4.4:1 aspect ratio, full bleed rectangle. On LEFT x0%-35%, a large open glossy orange-red Chinese dictionary book with cream page edges, standing upright angled toward viewer, a white Chinese character 词 on its right page, small stacked books, green bamboo leaves below and along left edge. On RIGHT x40%-100% light cyan sky, pale turquoise rounded karst mountains, jade Chinese pagoda at far right x90%, small soft pink blossoms along bottom, faint white clouds. Keep x38%-84%, y15%-66% nearly blank pale mint white for title and subtitle. All dark scenery stays below y70% or far right. No other text, no UI labels, no arrows, no borders, no surrounding card frame.

### lessons

Use case: precise-object-edit. Input: the user's learning screen screenshot is the visual reference. Create one production illustration asset based closely on the specified part of that screenshot, WITHOUT app UI text, navigation, status bar, or button shapes. Soft polished 3D storybook rendering, bright cream daylight, rounded shapes, miniature lush bamboo, Chinese karst mountains and traditional architecture, pastel colors. Preserve useful quiet negative space for Flutter text. No watermark. Asset type: AI lessons card artwork. Wide landscape 4.4:1 aspect ratio, full bleed rectangle. LEFT x0%-35% shows a glossy red Chinese graduation cap with a small gold tassel, rolled ivory parchment diploma leaning diagonally in front, diploma has the exact large dark brown letters AI, two small golden sparkle stars near its top-right, thick green bamboo leaves along the lower left. RIGHT is pale warm ivory and buttery yellow, soft honey colored karst mountains across bottom, warm orange Chinese temple at the far right, small coral blossoms near bottom-right. x38%-84%, y15%-66% is almost blank cream reserved for overlaid title and description. No app labels or words other than AI on diploma. No arrows, buttons, border or outside frame.

### conversation

Use case: precise-object-edit. Input: the user's learning screen screenshot is the visual reference. Create one production illustration asset based closely on the specified part of that screenshot, WITHOUT app UI text, navigation, status bar, or button shapes. Soft polished 3D storybook rendering, bright cream daylight, rounded shapes, miniature lush bamboo, Chinese karst mountains and traditional architecture, pastel colors. Preserve useful quiet negative space for Flutter text. No watermark. Asset type: AI conversation card artwork. Wide landscape 4.2:1 aspect ratio, full bleed rectangle. LEFT x0%-35%: large glossy vivid blue chat bubble with three small rounded white dots, smaller ivory white chat bubble in front with three blue dots, surrounded by a few bamboo leaves and soft pink cherry blossoms below. RIGHT x40%-100% pale blue and lavender airy sky and delicate karst mountains, a tiny elegant red Chinese pavilion at far right x91%, a curved gray stone bridge below it, pink blooming cherry blossom branches along far right and bottom. x38%-84%, y15%-69% is quiet nearly white pale blue/lavender for title and wrapped subtitle. No app text, no labels, no arrows, no buttons, no border or outside frame.

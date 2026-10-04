# Progress screen reference implementation

`lib/screen/home/widgets/home_progress_tab.dart` implements the main app's Progress tab from the supplied screenshot. `HomeScreen` supplies the existing GetX routes for statistics, HSK exams (including the subscription check), and history. The shared landscape and bottom navigation remain the existing app components.

The layout uses the same `TabHeader` and ScreenUtil scaling as Learning and Games, with a green statistics badge, black/green heading, gray subtitle, three scenic cards, and orange/green/blue arrow controls. All three tabs share the header's safe inset and padding, 16-unit horizontal card margins, 4-unit spacing below the header, 8-unit card gaps, and 128-unit minimum card height. Progress cards also use 24-unit rounded corners and 4-unit white borders. Cards retain live Flutter text and full-card tap targets, grow for larger text, and reserve scrolling space above the floating bottom navigation.

## Artwork

All action-card text across Learning, Games, Progress and Personal is rendered by `TabCardText`: titles use 18.sp, weight 900 and line height 1.1; descriptions use 15.sp, weight 600 and line height 1.3, separated by 5.w. Per-card colors remain tied to their artwork. Titles scale down to fit and descriptions wrap fully.

The three illustrations were generated with the built-in `image_gen` tool using the supplied screenshot as visual reference, then copied into the project:

- `assets/images/backgrounds/progress_stats.png`
- `assets/images/backgrounds/progress_exam.png`
- `assets/images/backgrounds/progress_history.png`

The artwork keeps the original subjects and scenes, with a lighter central sky behind live text. Unused drafts have been removed from the asset bundle.

The original `assets/images/backgrounds/shared_landscape.png` remains the full-screen background. Asset directories are already included in `pubspec.yaml`.

## Preview and verification

`docs/progress_ui_preview.png` is a widget-rendered preview at 440 × 874 logical pixels, captured at 2× resolution. Local Arial fonts are loaded only for preview rendering; native device fonts can differ. The operating system supplies status indicators and the home indicator on devices.

`test/screen/home/home_progress_tab_test.dart` checks four viewport widths, safe-area placement, all card callbacks via their arrow controls, bottom navigation, and full descriptions with 1.5× text scaling. `tab_header_alignment_test.dart` compares header geometry, card positions, margins and gaps across Learning, Games and Progress; individual card heights can grow to fit their descriptions. Existing home integration tests cover switching into Progress and back to the other tabs.

## Final generation prompts

The three initial prompts below were followed by the same targeted edit prompt for each illustration:

Use case: precise-object-edit. Edit target: this production illustrated Flutter card background. Make one targeted change: create a much lighter, quieter area for overlaid text in the CENTRAL rectangle x40%-84%, y18%-70%. Replace the strong mountains/trees/river details within that region with luminous pale soft sky and faint distant mist, so dark UI title and description can be clearly readable. Blend naturally without any rectangle edge. Keep all left foreground characters, scrolls, books, bamboo, robot/panda, props and Chinese lettering exactly unchanged, keep far-right pagoda and flowers unchanged, preserve all colorful scenery across the bottom 23%. Keep the original exact wide dimensions, framing, composition, storybook render style, colors and lighting. Stats scene stays ivory-gold, exam scene stays pale cyan, history scene stays pale sky-blue. Add no text, no UI, no buttons, no frames. Do not rearrange or redesign objects. Change only the central text area's background readability.

### progress_stats

Use case: illustration-story. Asset type: production full-bleed illustrated background for a clickable Flutter card. Input image: the user's attached Progress screen is the visual reference. Recreate the indicated card's ARTWORK very closely, as a standalone wide landscape image with approximately 2.9:1 aspect ratio. Match the lush polished colorful 3D storybook illustration, composition and details from the reference. NO Vietnamese text, NO app title or description, NO circle arrow button, NO UI, NO phone/status/navigation, NO borders or rounded corners, NO watermark. Flutter overlays the title at x40%-84%, y20%-68% so keep this region light, uncluttered and legible, with scenery along bottom and right. Fill the whole rectangular canvas. Recreate artwork of the FIRST warm golden card. LEFT x0%-38%: green bamboo at far left, large vertical ivory Chinese scroll showing orange ascending bar chart and rising arrow, small green-yellow-orange pie chart, cute black-and-white panda in red traditional clothing seated at bottom-left reading a cream document, stack of teal and blue books at lower-left. Right background: buttery ivory sky, golden orange autumn trees, softly painted warm Chinese mountains, traditional Chinese pavilions at lower edge, elegant arched stone bridge across a turquoise river lower-center-right. Large scroll and panda confined to left 37%; mostly cream warm pale yellow sky under the overlaid Flutter title. Do not put any lettering on scroll.

### progress_exam

Use case: illustration-story. Asset type: production full-bleed illustrated background for a clickable Flutter card. Input image: the user's attached Progress screen is the visual reference. Recreate the indicated card's ARTWORK very closely, as a standalone wide landscape image with approximately 2.9:1 aspect ratio. Match the lush polished colorful 3D storybook illustration, composition and details from the reference. NO Vietnamese text, NO app title or description, NO circle arrow button, NO UI, NO phone/status/navigation, NO borders or rounded corners, NO watermark. Flutter overlays the title at x40%-84%, y20%-68% so keep this region light, uncluttered and legible, with scenery along bottom and right. Fill the whole rectangular canvas. Recreate artwork of the SECOND cyan-green card. LEFT x0%-38%: lush glossy bamboo, large leaning cream clipboard checklist with exact dark green letters HSK at the top and three green checkmarks, small teal Chinese dictionary book at bottom-left with gold Chinese characters 汉语, open book along bottom; adorable white round AI robot with a glossy black screen face displaying cyan smiling digital eyes, green outfit and black graduation cap, holding a golden pencil, sitting beside open book. Right background: pale cyan blue sky with soft white clouds, misty teal karst peaks, lush green trees, serene jade lake at bottom, elegant Chinese pagoda and arched stone bridge at far right. Center area for title bright pale cyan and nearly empty. No lettering except HSK and 汉语.

### progress_history

Use case: illustration-story. Asset type: production full-bleed illustrated background for a clickable Flutter card. Input image: the user's attached Progress screen is the visual reference. Recreate the indicated card's ARTWORK very closely, as a standalone wide landscape image with approximately 2.9:1 aspect ratio. Match the lush polished colorful 3D storybook illustration, composition and details from the reference. NO Vietnamese text, NO app title or description, NO circle arrow button, NO UI, NO phone/status/navigation, NO borders or rounded corners, NO watermark. Flutter overlays the title at x40%-84%, y20%-68% so keep this region light, uncluttered and legible, with scenery along bottom and right. Fill the whole rectangular canvas. Recreate artwork of the THIRD blue-pink card. LEFT x0%-38%: ivory parchment scroll with a prominent large blue circular history arrow wrapping a blue clock symbol, small stack of teal books and cream papers bottom-left, small open parchment book with exact Chinese characters 你好, large magnifying glass with golden rim and brown handle tilted towards lower-middle, small glossy blue-white chat bubble with blue dots peeking beside scroll, lush bamboo and pink blossoms at far left. Right background: light bright blue sky, pale cyan-blue Chinese karst mountain silhouettes, elegant blue Chinese pavilion at far right, arched bridge and lake along lower-right, pink cherry blossom canopy along top-right and bright blossoms at bottom edge. Keep title area x40%-84%, y20%-68% almost empty pale blue sky. No letters except 你好.

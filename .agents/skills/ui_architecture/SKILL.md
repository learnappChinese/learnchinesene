---
name: ui-architecture
description: "Use when creating or refactoring Flutter screens, organizing UI with helper methods, extracting widgets, defining presentation contracts, or improving responsive layouts in this project."
---

# UI Screen and Widget Refactoring

Keep UI code easy to read, test, and change. Screens compose the interface; focused widgets render inputs and forward user actions. Preserve behavior and styling during structural refactors unless the user requests changes.

## Feature Structure

For new screen features, use this layout under `lib/screen/`:

```text
lib/screen/<feature_name>/
├── controller/                       # When the feature needs a controller
├── binding/                          # When route registration is needed
├── page/
│   └── <feature_name>_screen.dart
└── widget/                           # When local widgets need extraction
```

- Create directories and files only when they have a concrete purpose.
- Existing features may keep the screen at the feature root and use `widgets/` or `view/`. Preserve that structure when editing them.
- Keep established modules under `lib/features/` in their existing architecture. Do not relocate features to match this layout or introduce `lib/screens/` unless an existing module requires it.
- Keep feature-specific widgets with their feature. Reuse the existing shared widget/design-system location for widgets used by multiple features.
- The screen owns route-level composition, layout constraints, scrolling, safe areas, and interaction wiring. Put business operations, repository calls, and domain transformations in the controller or domain/data layer.

## Choosing Widget Boundaries

Extract a named widget when it forms a useful boundary: an independent responsibility, reusable UI, its own lifecycle, a separately changing subtree, or substantial presentation logic that makes the parent's `build()` hard to follow.

- Prefer meaningful sections and item widgets over arbitrary fragments such as `ContainerWidget` or `Widget1`. Use names such as `ProfileHeader`, `LessonProgressSection`, or `AnswerOptionTile`.
- Prefer private helper methods for meaningful sections used only within the same screen when the goal is to make composition easier to read and no independent widget boundary is needed. Small, obvious fragments may remain inline. A simple conditional or callback alone does not require a new class.
- Keep a simple local flag in the existing `State` when that remains clear. Extract a component when its state, resource ownership, or rebuild boundary becomes independent.
- Use `StatelessWidget` for widgets that only render inputs. Use `StatefulWidget` when the component owns mutable presentation state or resources; listening to externally owned reactive state alone does not require it.
- Extract complex or reusable list items into named widgets. Simple one-off items may stay in the builder. Pass item data and callbacks rather than fetching data or locating a broad controller from each item.
- Choose the boundary first, then the file location. A small private widget may stay in the screen file; use a feature widget file when reuse or complexity makes it easier to maintain.
- Avoid abstraction or file splits based solely on line counts.

## Private Helper Methods

Use helper-method refactoring alongside widget extraction. Keep `build()` readable as the screen's composition; move cohesive local sections or repeated presentation into descriptive private methods such as `_buildHeader`, `_buildContent`, `_buildEmptyState`, or `_buildActions`.

- Give each helper one clear presentation responsibility. Keep it in the screen or widget class that uses it; avoid chains of trivial wrappers and names such as `_buildPart1`.
- Use `_build...` for methods returning UI, `_handle...` for interaction handlers, and `_open...` for navigation when those names fit the existing code. A handler may forward an action to a controller; business logic and repository calls remain in their existing layers.
- Pass `BuildContext` when a helper needs theme, inherited values, or constraints. Pass display values and callbacks when that makes dependencies clearer. A private screen helper may adapt its screen's controller state to a presentation widget.
- Keep rendering helpers free of side effects: do not register controllers, start requests, mutate state, or create owned resources from a helper called during build.
- A helper method does not create a separate Flutter element, lifecycle, or rebuild boundary. Use a named widget for reusable components, independently changing subtrees, owned state/resources, or a presentation contract that benefits from separate testing.
- Keep Rx reads inside the relevant `Obx` callback, including reads performed by helpers called synchronously from it. Retain the smallest meaningful reactive subtree; wrapping composition in a helper does not narrow rebuilds by itself.
- Preserve keys, child order, scrolling, constraints, and callbacks when moving UI into helpers. Keep helpers cohesive rather than imposing a line-count limit or extracting every expression.

For example, a screen helper can keep static composition outside the reactive list:

```dart
Widget _buildBody(BuildContext context) {
  return Column(
    children: [
      _buildHeader(context),
      Expanded(
        child: Obx(() => LessonList(
              lessons: controller.lessons.toList(),
              onSelect: _openLesson,
            )),
      ),
    ],
  );
}
```

## Widget Contracts and State Ownership

- Prefer immutable constructor inputs and `const` constructors where possible. Pass display-ready values or small view models when they clarify the contract.
- Use callbacks for user actions. Reusable widgets should receive the values and actions they need rather than a large controller or hidden `Get.find()` dependencies.
- Keep business state in the controller and transient presentation state at the narrowest useful UI scope. Distinguish owned resources from borrowed resources.
- Initialize owned animation/text/scroll controllers, focus nodes, and subscriptions in `initState()` or the appropriate lifecycle hook, not in `build()`.
- When an input supplying a listener or resource changes, use `didUpdateWidget()` to detach from the old input and attach to the new one. Keep derived presentation state consistent with changed inputs.
- Dispose owned resources and remove listeners in `dispose()`. Remove your listeners from borrowed resources without disposing those resources.
- After an async operation, check `mounted` before calling `setState()` or using the widget's context. When inputs can change while work is running, also cancel prior work or ignore outdated results; `mounted` alone does not establish freshness.
- Preserve widget identity during refactoring. For stateful items that can reorder, use keys based on stable item identity rather than position. Preserve existing scroll keys and intentional state retention.

Example for a list with reorderable, stateful items:

```dart
ListView.builder(
  itemCount: lessons.length,
  itemBuilder: (context, index) {
    final lesson = lessons[index];
    return LessonListItem(
      key: ValueKey(lesson.id),
      lesson: lesson,
      onTap: () => onLessonTap(lesson),
    );
  },
)
```

## GetX and Reactive UI

- Use `Obx` around the smallest meaningful subtree that reads Rx state inside its callback. Avoid rebuilding the whole screen when only one section changes.
- Prefer explicit inputs and callbacks in reusable child widgets. A feature-specific adapter may read its controller and pass values to presentation widgets.
- Use `GetView<T>` when the screen's controller scope is clear; use `StatefulWidget` when the screen also owns local lifecycle.
- When changing controller registration, route bindings, async business state, or controller cleanup, consult [GetX Architecture and State Management](../getx_architecture/SKILL.md). Keep those rules in that skill rather than duplicating them here.

## Layout and Responsive Behavior

- Reuse the project's [ResponsiveLayout and ResponsiveHelper](../../../lib/core/responsive/responsive_layout.dart) and [AppBreakpoints](../../../lib/core/responsive/app_breakpoints.dart) when they fit the feature. Use parent constraints from `LayoutBuilder` for components whose available width differs from the full screen.
- Preserve the feature's existing `flutter_screenutil` usage. The active app initializes it in [lib/app.dart](../../../lib/app.dart); do not change its design size or introduce another scaling convention during a local refactor.
- Prefer flexible constraints, `Expanded`, `Flexible`, and `Wrap` over fixed screen widths. Constrain expanded children appropriately inside scrollables.
- Define the primary scrolling owner. Avoid an unbounded scrollable nested in the same direction; use slivers or an explicitly constrained composition when needed. Preserve lazy builders for large lists and grids.
- Keep icon/image areas and controls visually stable when appropriate, but allow text-bearing cards to grow or wrap. Prefer minimum heights and constraints over fixed heights that clip long text or enlarged fonts.
- Preserve system text scaling. Do not solve overflow by disabling it or shrinking readable text by default.
- Apply safe-area padding at the layer that owns it and avoid duplicating an inset already handled by an ancestor. Account for keyboard insets when editing input screens.
- Handle loading, empty, error, and disabled states with deliberate layout. Avoid expensive data work or repeated side effects inside `build()`.

## Visual Consistency and Accessibility

- Use the feature's existing theme, colors, typography, spacing, and assets. Reuse existing tokens and icon libraries when they fit.
- Preserve the established visual language during refactoring, including alignment, content order, and interaction states.
- Give interactive controls clear labels and semantic meaning. Use `Semantics` for custom controls or gestures when existing widgets do not provide the needed information; avoid duplicated announcements.
- Keep touch targets usable and expose applicable pressed, disabled, loading, and error states. Do not communicate important information by color alone.
- Preserve keyboard/focus behavior and focus order on supported platforms.

## Refactoring and Verification

Before editing, identify the route entry point, controller, widget boundaries, and behavior to preserve, including callbacks, navigation, keys, scroll position, input state, and semantics. Choose the smallest coherent change.

During editing, organize one responsibility at a time into a local helper or a focused widget according to the criteria above, keep business logic in its existing layer, and remove dead imports or local duplication. Avoid unrelated formatting, routing changes, or visual redesign.

After changing Dart UI code:

- Format changed Dart files and run `flutter analyze`.
- Run the narrowest relevant existing widget or screen tests. Add focused regression coverage when changed behavior, lifecycle, identity, or layout makes it useful; do not add tests merely to assert the new file structure.
- For layout changes, check representative narrow and wide sizes supported by the screen. Add long text, enlarged text, keyboard insets, or orientation checks when those dimensions are affected.
- For interaction or state changes, verify the affected loading/error/empty states, callbacks, focus, resource cleanup, and state retention. For GetX scope changes, follow the linked skill's verification guidance.
- When preserving appearance is central to the task, compare the affected screen before and after using existing visual tests or a rendered view when available.
- Report what was verified and any checks that could not run. Keep unrelated baseline failures distinct from regressions introduced by the change.

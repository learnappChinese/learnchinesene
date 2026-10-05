---
name: getx-architecture
description: "Use when creating or modifying GetX controllers, reactive state, dependency registration, route bindings, or controller lifecycle in this Flutter project."
---

# GetX Architecture and State Management

Use GetX for application state, dependency injection, and navigation. Before editing a feature, identify its route entry point, controller registrations, dependencies, and lifecycle owner. Preserve existing behavior and limit architectural changes to the requested scope.

## Feature Structure

For new screen features, use this layout under `lib/screen/`:

```text
lib/screen/<feature_name>/
├── controller/
│   └── <feature_name>_controller.dart
├── binding/                          # When route registration is needed
│   └── <feature_name>_binding.dart
├── page/
│   └── <feature_name>_screen.dart
└── widget/                           # When local widgets need extraction
```

- Create directories and files only when they have a concrete purpose.
- Existing features may keep their screen at the feature root and use `widgets/` or `view/`. Preserve those conventions when editing them.
- Keep established modules under `lib/features/` in their existing architecture; do not relocate them to satisfy this layout. Do not introduce `lib/screens/` for new features unless an existing module requires it.
- Keep repositories and data sources outside the screen folder when shared by multiple features.
- Use `GetView<T>` or `StatelessWidget` when no local lifecycle is needed. Use `StatefulWidget` when the widget owns local state or resources such as animation controllers or focus nodes.
- For widget extraction, layout, and presentation contracts, consult [UI Screen and Widget Refactoring](../ui_architecture/SKILL.md) when the task includes UI work.

## Controllers and Reactive State

- Extend `GetxController`. Keep business operations and data fetching in controllers or the domain/data layer; widgets render state and forward actions.
- Prefer constructor injection for repositories, services, and use cases. Resolve dependencies in the feature's binding or existing composition root so controllers can be tested with fakes.
- Use Rx fields for state observed by the UI, with `.value` for scalar reads and writes. Use `RxList` operations such as `assignAll` for collection updates. Do not make every field reactive by default.
- Mutating a field inside a plain object stored in an Rx does not automatically notify observers. Prefer replacing it with an updated immutable value; use `refresh()` only when in-place mutation is intentional.
- Prefer `Obx` around the smallest meaningful subtree that reads Rx state inside its callback. Preserve established `GetBuilder`/`update()` workflows unless changing them is part of the task.
- Keep transient presentation state at the narrowest useful scope; a local expansion flag or animation does not automatically require a GetX controller.

### Controller Responsibilities

- A controller should coordinate one screen or one cohesive use case.
- Split when state and actions have clearly independent responsibilities, unrelated async workflows, or independently owned workers/subscriptions, and the split improves understanding or testing.
- Name controllers by responsibility, such as `LessonContentController`, `LessonAnswerController`, and `LessonProgressController`. Avoid vague names such as `CommonController`.
- A parent controller may coordinate child controllers, but each child must remain independently understandable and testable. Register route-owned controllers in the route's binding rather than constructing them inside a widget or parent controller.
- Do not split solely because of an arbitrary line count. Move reusable, data-oriented, or UI-independent logic to a repository, service, use case, or mapper rather than another controller.

## Dependency Registration and Ownership

Choose the lifetime before choosing the registration API:

| Lifetime | Registration and cleanup |
| --- | --- |
| One route | Prefer a route binding. Let GetX manage disposal according to the app's existing `SmartManagement` configuration. |
| Shared across features | Register in `lib/di.dart` or the module's existing composition root. Decide explicitly whether the instance can be recreated or must retain state. |
| One widget | Use local ownership only when needed. Register once in `initState()`, use a unique instance tag where necessary, and delete only that widget's registration when it is disposed. |

- `Get.lazyPut()` creates the instance on the first `Get.find()`, not at registration time.
- `fenix: true` retains the factory so GetX can create a new instance after deletion. It does not preserve the old instance's state. The factory must construct a fresh instance, not return a previously closed controller.
- Use `Get.put(..., permanent: true)` only when the same instance must survive route changes. Define its reset/cleanup owner, such as logout or app-level teardown; do not use permanence as a default.
- `Get.put()` registers in GetX's dependency container; placement in a `State` class alone does not make it widget-scoped. Do not rely on an empty widget `dispose()` for widget-owned controller cleanup.
- Do not register the same instance key (type plus optional tag) in global DI, a binding, and a widget. Widgets using `Get.find()` borrow the dependency and must not delete it.
- If multiple instances of one controller type must coexist, use a stable tag unique to each live instance consistently in registration, lookup, and deletion. Do not reuse a tag solely because two routes show the same item.
- Never create or register controllers from `build()`. Do not call a GetX-managed controller's `onClose()` directly; let its registration owner remove it through GetX.

## Route Bindings and Navigation

Use GetX navigation and page factories such as `Get.to(() => const FeatureNameScreen())`. Prefer named routes when the active app already configures them; do not migrate routing merely to add a binding.

```dart
class FeatureNameBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FeatureNameController>(() => FeatureNameController());
  }
}

// Direct navigation can attach a route binding without a named route table.
Get.to(
  () => const FeatureNameScreen(),
  binding: FeatureNameBinding(),
);

// In an existing named route table, attach it to the GetPage instead.
GetPage(
  name: '/feature-name',
  page: () => const FeatureNameScreen(),
  binding: FeatureNameBinding(),
);
```

- Ensure dependencies exist before the destination calls `Get.find()`.
- Pass route data explicitly through constructor inputs or route-scoped `Get.arguments`. Validate required data and types before starting work; do not use arguments as global state.
- Use `Get.back()` to pop, and `Get.back(result: value)` when the caller needs a result. Await navigation when its result matters: `final result = await Get.to<bool>(() => const FeatureNameScreen());`.

## Async State and Concurrent Work

- Make loading, content, empty, and error states distinguishable. Rx fields or an explicit state model are both acceptable; do not add a state hierarchy for a simple flow.
- Reset loading with `try/finally`. Expose a user-safe, localized error message through the project's existing error handling convention; retain diagnostic details through its logging mechanism.
- For repeated calls, choose a policy appropriate to the interaction: ignore duplicate submissions, cancel prior work when supported, or ignore outdated results for search/filter requests. `debounce` delays new calls but does not cancel requests already running.
- When work can finish after disposal, avoid updating state or navigating from a closed controller. For overlapping requests, guard success, error, and loading updates so an older request cannot overwrite a newer one.

Example for a load operation that ignores duplicate calls while running:

```dart
class ItemsController extends GetxController {
  ItemsController({required this.loadItems});

  final Future<List<String>> Function() loadItems;
  final items = <String>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  Future<void> fetchData() async {
    if (isClosed || isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final result = await loadItems();
      if (isClosed) return;
      items.assignAll(result);
    } catch (_) {
      if (!isClosed) errorMessage.value = 'Không thể tải dữ liệu.';
    } finally {
      if (!isClosed) isLoading.value = false;
    }
  }
}
```

Adapt the error text and reporting to the feature's existing convention. For search where the latest query must win, use cancellation or request identity checks instead of this duplicate-call guard.

## Lifecycle and Side Effects

- Use `onInit()` for initial state, initial loading, and workers; `onReady()` for work requiring the first frame; and `onClose()` for releasing owned resources. Call the corresponding `super` lifecycle methods.
- Use `ever`, `once`, `debounce`, or `interval` only for a clear reactive side effect. Retain each returned `Worker` and dispose it in `onClose()`.
- Cancel owned timers and stream subscriptions, and dispose owned Flutter controllers in `onClose()`. Do not dispose borrowed shared dependencies or independently registered child controllers.
- Keep a cleanup path for listeners and other long-lived work. Handle async cancellation errors through the project's existing convention when cleanup cannot complete synchronously.

## Verification

- For changed controller behavior, use focused tests with injected fakes. Cover relevant success, empty, and failure states, and concurrency or cleanup when affected by the change.
- When tests register GetX dependencies, reset them in teardown with `Get.reset()`; await it in async teardown. Test lifecycle through GetX registration/deletion when validating ownership or `onClose()` behavior.
- For dependency or routing changes, verify that opening, closing, and reopening the screen creates and disposes the intended instance, including tagged instances when applicable.
- Format changed Dart files, run `flutter analyze`, and run the narrowest relevant existing tests. Report any checks that could not run and their cause.

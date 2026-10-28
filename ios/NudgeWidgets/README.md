# Nudge iOS widgets — Xcode setup

The widget code is complete (`NudgeWidgets.swift`); it only needs a Widget
Extension target, which must be created in Xcode (it cannot be added from the
Windows dev machine).

What is already in the repo, so you don't redo it:

- `Runner/Runner.entitlements` declares the App Group and is wired into all
  three Runner build configurations via `CODE_SIGN_ENTITLEMENTS`.
- `Runner/Info.plist` registers the `nudge` URL scheme under
  `CFBundleURLTypes`. Without it widget taps never reach the app.
- Every link in `NudgeWidgets.swift` goes through `deepLink(_:)`, which appends
  the `homeWidget` query item that the plugin's iOS side requires before it
  forwards a URL to Dart.

Steps:

1. **Add the extension target.** In Xcode open `Runner.xcworkspace`, then
   File → New → Target… → *Widget Extension*. Name it `NudgeWidgets`,
   uncheck "Include Configuration App Intent", and finish. Delete the
   generated Swift files in the new target and add `NudgeWidgets.swift`
   from this folder instead. Set the new target's deployment target to
   **iOS 17** or later (see the note at the bottom).

2. **Share the App Group.** The `Runner` target already carries the
   entitlement; add the *App Groups* capability to the new `NudgeWidgets`
   target too, with the id `group.com.example.todoList`. It must match
   `HomeWidgetService.iosAppGroup` in
   `lib/services/home_widget_service.dart` and the `appGroup` constant in
   `NudgeWidgets.swift` — change all three together if you use a different
   bundle id. Enable the group for both App IDs in the developer portal.

3. **Build.** The widget kinds (`NudgeUpNextWidget`, `NudgeFocusWidget`) are
   already wired to the Flutter side — the app pushes data on every change
   via the `home_widget` plugin, and taps deep-link back through
   `nudge://task/<id>`, `nudge://quickadd` and `nudge://focus`.

## Known gaps

- **No complete button.** The Android widgets complete a task from a
  background broadcast (`nudge://complete/<id>`). The iOS equivalent is an
  `AppIntent` in the extension calling
  `HomeWidget.registerInteractivityCallback`'s worker — the Dart side is
  already registered, but the intent itself needs the extension target to
  exist first. Until then the iOS widgets are read-plus-open only.
- `containerBackground` requires **iOS 17+**. To support iOS 16, replace that
  modifier with a plain `.background` and lower the target.

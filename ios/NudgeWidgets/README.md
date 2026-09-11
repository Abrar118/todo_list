# Nudge iOS widgets — Xcode setup

The widget code is complete (`NudgeWidgets.swift`); it only needs a Widget
Extension target, which must be created in Xcode:

1. **Add the extension target.** In Xcode open `Runner.xcworkspace`, then
   File → New → Target… → *Widget Extension*. Name it `NudgeWidgets`,
   uncheck "Include Configuration App Intent", and finish. Delete the
   generated Swift files in the new target and add `NudgeWidgets.swift`
   from this folder instead.

2. **Share the App Group.** In Signing & Capabilities add the *App Groups*
   capability to **both** the `Runner` target and the `NudgeWidgets` target,
   using the group id `group.com.example.todoList` (must match
   `HomeWidgetService.iosAppGroup` in `lib/services/home_widget_service.dart`;
   change both together if you use a different bundle id).

3. **Build.** The widget kinds (`NudgeUpNextWidget`, `NudgeFocusWidget`) are
   already wired to the Flutter side — the app pushes data on every change
   via the `home_widget` plugin, and taps deep-link back through
   `nudge://task/<id>` and `nudge://quickadd`.

Requires iOS 17+ for `containerBackground` (lower the deployment target by
replacing that modifier with a plain `.background` if you need iOS 16).

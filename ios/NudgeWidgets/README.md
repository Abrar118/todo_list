# Nudge iOS widgets

`NudgeWidgets.swift` is built by the `NudgeWidgets` Widget Extension target
(bundle ID `com.abrar118.nudge.NudgeWidgets`, iOS 17+), which Runner embeds via
its "Embed Foundation Extensions" phase. That phase must stay *before* Flutter's
"Thin Binary" script phase, or Xcode reports a dependency cycle.

Wiring that must stay in sync:

- App Group `group.com.abrar118.nudge` is declared in both
  `Runner/Runner.entitlements` and `NudgeWidgets/NudgeWidgets.entitlements`,
  and must match `HomeWidgetService.iosAppGroup` and the `appGroup` constant in
  `NudgeWidgets.swift`.
- `Runner/Info.plist` registers the `nudge` URL scheme. Without it widget taps
  never reach the app.
- Every link in `NudgeWidgets.swift` goes through `deepLink(_:)`, which appends
  the `homeWidget` query item the plugin's iOS side requires before it forwards
  a URL to Dart.

Widget kinds (`NudgeUpNextWidget`, `NudgeFocusWidget`) are wired to the Flutter
side: the app pushes data on every change via `home_widget`, and taps deep-link
back through `nudge://task/<id>`, `nudge://quickadd` and `nudge://focus`.

## Known gaps

- **No complete button.** Android completes a task from a background broadcast
  (`nudge://complete/<id>`). The iOS equivalent would be an `AppIntent` in this
  extension calling the `HomeWidget.registerInteractivityCallback` worker. The
  Dart side is already registered; the intent isn't written yet.

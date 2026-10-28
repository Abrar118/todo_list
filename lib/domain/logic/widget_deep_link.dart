enum WidgetDeepLinkKind { openTask, quickAdd, focus }

/// A `nudge://` URL sent by a home-screen widget, resolved to what the app
/// should do about it.
///
/// Android delivers the launch intent's data URI verbatim; iOS delivers the
/// same URL with a `homeWidget` query item, which the plugin requires before
/// it will forward anything to Dart. The marker carries no meaning here, so
/// routing only looks at the host and path and both platforms land in the
/// same place.
///
/// `nudge://complete/<id>` is deliberately not routable: completing from a
/// widget runs headlessly through `widget_action_handler.dart` and must never
/// depend on the app being in the foreground.
class WidgetDeepLink {
  final WidgetDeepLinkKind kind;

  /// Set only for [WidgetDeepLinkKind.openTask].
  final String? taskId;

  const WidgetDeepLink._(this.kind, {this.taskId});

  static WidgetDeepLink? parse(Uri? uri) {
    if (uri == null) return null;
    switch (uri.host) {
      case 'task':
        final segments = uri.pathSegments.where((s) => s.isNotEmpty);
        if (segments.isEmpty) return null;
        return WidgetDeepLink._(
          WidgetDeepLinkKind.openTask,
          taskId: segments.first,
        );
      case 'quickadd':
        return const WidgetDeepLink._(WidgetDeepLinkKind.quickAdd);
      case 'focus':
        return const WidgetDeepLink._(WidgetDeepLinkKind.focus);
      default:
        return null;
    }
  }
}

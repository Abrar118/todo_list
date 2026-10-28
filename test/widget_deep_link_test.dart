import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/domain/logic/widget_deep_link.dart';

void main() {
  group('WidgetDeepLink.parse', () {
    test('reads a task id out of the path', () {
      final link = WidgetDeepLink.parse(Uri.parse('nudge://task/abc-123'));
      expect(link?.kind, WidgetDeepLinkKind.openTask);
      expect(link?.taskId, 'abc-123');
    });

    test('recognizes quick add and focus', () {
      expect(
        WidgetDeepLink.parse(Uri.parse('nudge://quickadd'))?.kind,
        WidgetDeepLinkKind.quickAdd,
      );
      expect(
        WidgetDeepLink.parse(Uri.parse('nudge://focus'))?.kind,
        WidgetDeepLinkKind.focus,
      );
    });

    test('ignores the homeWidget marker iOS requires on the URL', () {
      // The iOS half of home_widget only forwards URLs carrying this query
      // item, so widget links arrive with it on iOS and without it on
      // Android. Both must route the same way.
      final ios = WidgetDeepLink.parse(
        Uri.parse('nudge://task/abc-123?homeWidget=true'),
      );
      expect(ios?.kind, WidgetDeepLinkKind.openTask);
      expect(ios?.taskId, 'abc-123');
      expect(
        WidgetDeepLink.parse(
          Uri.parse('nudge://quickadd?homeWidget=true'),
        )?.kind,
        WidgetDeepLinkKind.quickAdd,
      );
    });

    test('returns null for nothing to do', () {
      expect(WidgetDeepLink.parse(null), isNull);
      expect(WidgetDeepLink.parse(Uri.parse('nudge://task')), isNull);
      expect(WidgetDeepLink.parse(Uri.parse('nudge://task/')), isNull);
      expect(WidgetDeepLink.parse(Uri.parse('nudge://elsewhere')), isNull);
      expect(WidgetDeepLink.parse(Uri.parse('')), isNull);
    });

    test('complete links are not app-routable', () {
      // nudge://complete/<id> is handled headlessly by the Android widget
      // broadcast, never by the foreground router.
      expect(
        WidgetDeepLink.parse(Uri.parse('nudge://complete/abc-123')),
        isNull,
      );
    });
  });
}

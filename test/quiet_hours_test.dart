import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/domain/logic/quiet_hours.dart';

void main() {
  group('QuietHours', () {
    test('disabled never contains', () {
      const q = QuietHours(enabled: false);
      expect(q.contains(DateTime(2026, 7, 11, 23, 30)), isFalse);
    });

    test('same-day window', () {
      const q = QuietHours(
        enabled: true,
        startMinutes: 9 * 60,
        endMinutes: 17 * 60,
      );
      expect(q.contains(DateTime(2026, 7, 11, 8, 59)), isFalse);
      expect(q.contains(DateTime(2026, 7, 11, 9, 0)), isTrue);
      expect(q.contains(DateTime(2026, 7, 11, 16, 59)), isTrue);
      expect(q.contains(DateTime(2026, 7, 11, 17, 0)), isFalse);
    });

    test('midnight-crossing window', () {
      const q = QuietHours(enabled: true); // 23:00 -> 07:00
      expect(q.contains(DateTime(2026, 7, 11, 22, 59)), isFalse);
      expect(q.contains(DateTime(2026, 7, 11, 23, 0)), isTrue);
      expect(q.contains(DateTime(2026, 7, 12, 3, 0)), isTrue);
      expect(q.contains(DateTime(2026, 7, 12, 6, 59)), isTrue);
      expect(q.contains(DateTime(2026, 7, 12, 7, 0)), isFalse);
    });

    test('adjust delays into the window end, same day', () {
      const q = QuietHours(
        enabled: true,
        startMinutes: 9 * 60,
        endMinutes: 17 * 60,
      );
      expect(
        q.adjust(DateTime(2026, 7, 11, 10, 30)),
        DateTime(2026, 7, 11, 17, 0),
      );
      expect(
        q.adjust(DateTime(2026, 7, 11, 18, 0)),
        DateTime(2026, 7, 11, 18, 0),
      );
    });

    test('adjust across midnight lands next morning', () {
      const q = QuietHours(enabled: true); // 23:00 -> 07:00
      expect(
        q.adjust(DateTime(2026, 7, 11, 23, 30)),
        DateTime(2026, 7, 12, 7, 0),
      );
      expect(
        q.adjust(DateTime(2026, 7, 12, 2, 0)),
        DateTime(2026, 7, 12, 7, 0),
      );
    });
  });
}

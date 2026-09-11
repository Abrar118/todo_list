import '../models/date_only.dart';

/// Result of parsing natural-language date/time hints out of quick-add text.
class ParsedQuickAdd {
  /// The input with recognized date/time phrases removed.
  final String title;

  final DateOnly? dueDate;
  final int? dueMinutes;

  /// Labels written as `#tag`, in input order, without the `#`.
  final List<String> tags;

  /// The phrases that were recognized, for the "Detected …" hint.
  final List<String> matchedPhrases;

  const ParsedQuickAdd({
    required this.title,
    this.dueDate,
    this.dueMinutes,
    this.tags = const [],
    this.matchedPhrases = const [],
  });

  bool get hasMatch => matchedPhrases.isNotEmpty || tags.isNotEmpty;
}

/// Extracts a deadline from phrases like "call mom tomorrow 5pm",
/// "water plants fri", "dentist july 20 at 3", "report in 2 hours".
///
/// Understood forms (case-insensitive, word-bounded, the last occurrence
/// wins and is stripped from the title):
///
/// - keywords: today, tonight, tomorrow, tmrw/tmr, day after tomorrow,
///   next week, next month, (this) weekend
/// - weekdays, full or abbreviated, with optional this/next: "fri",
///   "next monday" (next = the one after the upcoming)
/// - month dates: "july 20", "jul 20th", "20 july" (past dates roll to
///   next year)
/// - relative: "in 3 days", "in 2 weeks", "in a month", "in 2 hours",
///   "in 30 minutes"
/// - times: "5pm", "5:30 pm", "17:30", "noon", "at 5" (1–7 → PM,
///   8–12 → AM), and morning/afternoon/evening/night attached to a date
///   ("tomorrow morning") or prefixed ("this evening")
/// - tags: "#work"
///
/// A "Detected" hint with a dismiss button guards the rare false positive
/// (e.g. "sat" as a verb). Pure Dart; [now] is injected for testability.
abstract final class QuickAddParser {
  static final _tagPattern = RegExp(r'(^|\s)#([\w-]+)');

  static const _weekdayNames =
      'monday|tuesday|wednesday|thursday|friday|saturday|sunday|'
      'tues|thurs|thur|weds|mon|tue|wed|thu|fri|sat|sun';

  static const _monthNames =
      'january|february|march|april|june|july|august|september|october|'
      'november|december|jan|feb|mar|apr|may|jun|jul|aug|sept|sep|oct|'
      'nov|dec';

  static const _dayWords = 'morning|afternoon|evening|night';

  /// "in 2 hours", "in 45 minutes", "in an hour" — resolves to an absolute
  /// date *and* time, so it takes precedence over date/time words.
  static final _relativeTime = RegExp(
    r'\bin\s+(?<n>\d{1,3}|an?|half an)\s*(?<unit>hours?|hrs?|minutes?|mins?)\b',
    caseSensitive: false,
  );

  static final _datePattern = RegExp(
    r'\b(?:'
    r'(?<kw>day after tomorrow|today|tonight|tomorrow|tmrw|tmr|'
    r'next week|next month|(?:this\s+)?weekend)'
    r'|(?<solo>this)\s+(?<soloday>'
    '$_dayWords'
    r')'
    r'|(?:(?<prefix>next|this)\s+)?(?<wd>'
    '$_weekdayNames'
    r')'
    r'|in\s+(?<inn>\d{1,2}|an?)\s+(?<inunit>days?|weeks?|months?)'
    r'|(?<mon1>'
    '$_monthNames'
    r')\.?\s+(?<d1>\d{1,2})(?:st|nd|rd|th)?'
    r'|(?<d2>\d{1,2})(?:st|nd|rd|th)?\s+(?<mon2>'
    '$_monthNames'
    r')'
    r')'
    r'(?:\s+(?<dayword>'
    '$_dayWords'
    r'))?'
    r'\b',
    caseSensitive: false,
  );

  static final _timePattern = RegExp(
    r'\b(?:at\s+)?(?:'
    r'(?<h12>\d{1,2})(?::(?<m12>[0-5]\d))?\s*(?<ampm>am|pm)'
    r'|(?<h24>[01]?\d|2[0-3]):(?<m24>[0-5]\d)'
    r'|(?<noon>noon|midday)'
    r')\b',
    caseSensitive: false,
  );

  /// "at 5" with no am/pm or minutes. Requires the "at" so bare numbers in
  /// titles ("buy 2 lamps") never match.
  static final _bareAtHour = RegExp(
    r'\bat\s+(?<h>\d{1,2})\b(?!\s*(?::|am|pm))',
    caseSensitive: false,
  );

  static const _weekdayByPrefix = {
    'mon': DateTime.monday,
    'tue': DateTime.tuesday,
    'wed': DateTime.wednesday,
    'thu': DateTime.thursday,
    'fri': DateTime.friday,
    'sat': DateTime.saturday,
    'sun': DateTime.sunday,
  };

  static const _monthByPrefix = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  static const _minutesByDayWord = {
    'morning': 9 * 60,
    'afternoon': 15 * 60,
    'evening': 19 * 60,
    'night': 21 * 60,
  };

  static ParsedQuickAdd parse(String input, DateTime now) {
    final today = DateOnly.fromDateTime(now);
    final matched = <String>[];
    var text = input;

    // Tags first, so "#friday" is a label rather than a date.
    final tags = <String>[];
    text = text.replaceAllMapped(_tagPattern, (m) {
      final tag = m.group(2)!;
      if (!tags.any((t) => t.toLowerCase() == tag.toLowerCase())) {
        tags.add(tag);
      }
      return m.group(1)!;
    });

    DateOnly? date;
    int? minutes;

    final rel = _lastMatch(_relativeTime, text);
    if (rel != null) {
      final target = _resolveRelative(rel, now);
      date = DateOnly.fromDateTime(target);
      minutes = target.hour * 60 + target.minute;
      matched.add(rel.group(0)!.trim());
      text = _cut(text, rel);
    }

    var eveningDefault = false;
    if (date == null) {
      final dateMatch = _lastMatch(_datePattern, text);
      if (dateMatch != null) {
        final resolved = _resolveDate(dateMatch, today);
        if (resolved != null) {
          date = resolved;
          final kw = dateMatch.namedGroup('kw')?.toLowerCase();
          eveningDefault = kw == 'tonight';
          final dayWord =
              (dateMatch.namedGroup('dayword') ??
                      dateMatch.namedGroup('soloday'))
                  ?.toLowerCase();
          if (dayWord != null) minutes = _minutesByDayWord[dayWord];
          matched.add(dateMatch.group(0)!.trim());
          text = _cut(text, dateMatch);
        }
      }
    }

    if (minutes == null) {
      final timeMatch = _lastMatch(_timePattern, text);
      if (timeMatch != null) {
        minutes = _resolveTime(timeMatch);
        if (minutes != null) {
          matched.add(timeMatch.group(0)!.trim());
          text = _cut(text, timeMatch);
        }
      }
    }
    if (minutes == null) {
      final atMatch = _lastMatch(_bareAtHour, text);
      if (atMatch != null) {
        minutes = _resolveBareHour(int.parse(atMatch.namedGroup('h')!));
        if (minutes != null) {
          matched.add(atMatch.group(0)!.trim());
          text = _cut(text, atMatch);
        }
      }
    }
    minutes ??= eveningDefault ? 20 * 60 : null;

    // A bare time means today — or tomorrow when that moment already passed.
    if (minutes != null && date == null) {
      final nowMinutes = now.hour * 60 + now.minute;
      date = minutes > nowMinutes ? today : today.addDays(1);
    }

    final title = text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return ParsedQuickAdd(
      // Never let parsing eat the whole title.
      title: title.isEmpty ? input.trim() : title,
      dueDate: date,
      dueMinutes: minutes,
      tags: tags,
      matchedPhrases: matched,
    );
  }

  static RegExpMatch? _lastMatch(RegExp pattern, String text) {
    RegExpMatch? last;
    for (final m in pattern.allMatches(text)) {
      last = m;
    }
    return last;
  }

  static String _cut(String text, RegExpMatch match) =>
      text.substring(0, match.start) + text.substring(match.end);

  static DateTime _resolveRelative(RegExpMatch match, DateTime now) {
    final raw = match.namedGroup('n')!.toLowerCase();
    final unit = match.namedGroup('unit')!.toLowerCase();
    final hours = unit.startsWith('h');
    if (raw == 'half an') {
      return now.add(Duration(minutes: hours ? 30 : 1));
    }
    final n = int.tryParse(raw) ?? 1; // "an hour", "a minute"
    return now.add(hours ? Duration(hours: n) : Duration(minutes: n));
  }

  static DateOnly? _resolveDate(RegExpMatch match, DateOnly today) {
    final kw = match.namedGroup('kw')?.toLowerCase();
    if (kw != null) {
      switch (kw) {
        case 'today':
        case 'tonight':
          return today;
        case 'tomorrow':
        case 'tmrw':
        case 'tmr':
          return today.addDays(1);
        case 'day after tomorrow':
          return today.addDays(2);
        case 'next week':
          return today.addDays(7);
        case 'next month':
          return today.addMonthsClamped(1);
      }
      if (kw.endsWith('weekend')) {
        final wd = today.weekday;
        if (wd == DateTime.saturday || wd == DateTime.sunday) return today;
        return today.addDays((DateTime.saturday - wd + 7) % 7);
      }
    }

    if (match.namedGroup('soloday') != null) return today;

    final wdName = match.namedGroup('wd')?.toLowerCase();
    if (wdName != null) {
      final weekday = _weekdayByPrefix[wdName.substring(0, 3)]!;
      final next = match.namedGroup('prefix')?.toLowerCase() == 'next';
      var ahead = (weekday - today.weekday + 7) % 7;
      if (ahead == 0) ahead = 7; // "friday" on a Friday means the next one
      if (next && ahead < 7) ahead += 7;
      return today.addDays(ahead);
    }

    final inUnit = match.namedGroup('inunit')?.toLowerCase();
    if (inUnit != null) {
      final raw = match.namedGroup('inn')!.toLowerCase();
      final count = int.tryParse(raw) ?? 1; // "in a week"
      if (inUnit.startsWith('month')) return today.addMonthsClamped(count);
      return today.addDays(inUnit.startsWith('week') ? count * 7 : count);
    }

    final monName = (match.namedGroup('mon1') ?? match.namedGroup('mon2'))
        ?.toLowerCase();
    if (monName != null) {
      final month = _monthByPrefix[monName.substring(0, 3)]!;
      final day = int.parse(
        (match.namedGroup('d1') ?? match.namedGroup('d2'))!,
      );
      if (day < 1 || day > DateOnly.daysInMonth(today.year, month)) {
        return null;
      }
      var candidate = DateOnly(today.year, month, day);
      if (candidate.isBefore(today)) {
        candidate = DateOnly(today.year + 1, month, day);
      }
      return candidate;
    }
    return null;
  }

  static int? _resolveTime(RegExpMatch match) {
    if (match.namedGroup('noon') != null) return 12 * 60;
    final ampm = match.namedGroup('ampm')?.toLowerCase();
    if (ampm != null) {
      final hour = int.parse(match.namedGroup('h12')!);
      if (hour < 1 || hour > 12) return null;
      final minute = int.parse(match.namedGroup('m12') ?? '0');
      final h24 = switch ((hour, ampm)) {
        (12, 'am') => 0,
        (12, 'pm') => 12,
        (_, 'pm') => hour + 12,
        _ => hour,
      };
      return h24 * 60 + minute;
    }
    // 24-hour "17:30" form.
    return int.parse(match.namedGroup('h24')!) * 60 +
        int.parse(match.namedGroup('m24')!);
  }

  /// "at 5" with no am/pm: working-hours heuristic — 1–7 → PM, 8–12 → AM
  /// (12 = noon), 13–23 as-is.
  static int? _resolveBareHour(int hour) {
    if (hour < 1 || hour > 23) return null;
    if (hour >= 13) return hour * 60;
    if (hour == 12) return 12 * 60;
    if (hour <= 7) return (hour + 12) * 60;
    return hour * 60;
  }
}

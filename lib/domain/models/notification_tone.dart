import 'swatch.dart';

enum NotificationTone {
  lime,
  cyan,
  sand,
  coral;

  /// Groups the decorative palette onto the four notification accents, so a
  /// task's or habit's colour carries over to its notification. Every swatch
  /// must appear exactly once — the switch is exhaustive on purpose, so a new
  /// swatch fails to compile until it is placed.
  static NotificationTone forSwatch(Swatch swatch) => switch (swatch) {
    Swatch.sage ||
    Swatch.moss ||
    Swatch.fern ||
    Swatch.olive ||
    Swatch.seafoam => NotificationTone.lime,
    Swatch.mist ||
    Swatch.teal ||
    Swatch.sky ||
    Swatch.denim => NotificationTone.cyan,
    Swatch.sand ||
    Swatch.ochre ||
    Swatch.apricot ||
    Swatch.clay ||
    Swatch.stone => NotificationTone.sand,
    Swatch.rose ||
    Swatch.lilac ||
    Swatch.iris ||
    Swatch.plum ||
    Swatch.berry ||
    Swatch.brick => NotificationTone.coral,
  };
}

/// The colour palettes a user can pick in Settings. Each one recolours the
/// whole app — the grass band, the buttons, the hero card, the tints — in
/// both light and dark; `AppColors.forPalette` holds the colours.
///
/// Pure Dart on purpose: `AppSettings` stores the choice by [name].
enum AppPalette {
  meadow('Green'),
  lagoon('Teal'),
  grape('Purple'),
  indigo('Indigo'),
  berry('Pink'),
  sunset('Orange'),
  space('Space black'),
  midnight('Midnight black');

  final String label;
  const AppPalette(this.label);
}

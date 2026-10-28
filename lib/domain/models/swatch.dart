/// The shared decorative identity used by tasks, habits and goals.
///
/// Declaration order is parallel to `AppColors.decorative`: a swatch resolves
/// to a colour by its [Enum.index], so the two lists must be reordered
/// together. `test/design_tokens_test.dart` pins their lengths.
enum Swatch {
  // The original eight, in their original order — existing data depends on it.
  sage,
  mist,
  lilac,
  clay,
  sand,
  rose,
  moss,
  stone,
  // Added later to widen the choice.
  brick,
  apricot,
  ochre,
  olive,
  fern,
  seafoam,
  teal,
  sky,
  denim,
  iris,
  plum,
  berry,
}

extension SwatchLabel on Swatch {
  /// Display name; the enum names are already single plain words.
  String get label => '${name[0].toUpperCase()}${name.substring(1)}';
}

/// Names written by the old `TaskBackground` enum. `automatic` is absent
/// because an automatic task simply omits the key.
const legacyTaskSwatches = <String, Swatch>{
  'lime': Swatch.sage,
  'cyan': Swatch.mist,
  'coral': Swatch.rose,
};

/// Names written by the old `HabitColor` enum. Deliberately separate from
/// [legacyGoalSwatches]: `violet` rendered sage on a habit but lilac on a
/// goal, so one shared map would silently recolour existing data.
const legacyHabitSwatches = <String, Swatch>{
  'violet': Swatch.sage,
  'blue': Swatch.mist,
  'green': Swatch.moss,
  'amber': Swatch.sand,
};

/// Names written by the old `GoalColor` enum.
const legacyGoalSwatches = <String, Swatch>{
  'lime': Swatch.sage,
  'cyan': Swatch.mist,
  'amber': Swatch.sand,
  'coral': Swatch.rose,
  'violet': Swatch.lilac,
};

/// Reads a persisted swatch, falling back to [legacy] names from before the
/// three per-subsystem colour enums were merged. Returns null when the value
/// is missing or unrecognised.
Swatch? swatchFromJson(Object? value, Map<String, Swatch> legacy) {
  if (value is! String) return null;
  for (final swatch in Swatch.values) {
    if (swatch.name == value) return swatch;
  }
  return legacy[value];
}

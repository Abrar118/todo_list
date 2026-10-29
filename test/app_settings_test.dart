import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/core/app_palette.dart';
import 'package:todo_list/data/app_settings.dart';

void main() {
  test('palette survives a JSON round trip', () {
    for (final palette in AppPalette.values) {
      final json = AppSettings(palette: palette).toJson();
      expect(AppSettings.fromJson(json).palette, palette);
    }
  });

  test('missing or unknown palette falls back to green', () {
    expect(AppSettings.fromJson(const {}).palette, AppPalette.meadow);
    expect(
      AppSettings.fromJson(const {'palette': 'neon'}).palette,
      AppPalette.meadow,
    );
  });
}

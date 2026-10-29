import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list/core/app_palette.dart';
import 'package:todo_list/services/app_icon_service.dart';

void main() {
  test('every palette has an iOS icon set registered with Xcode', () {
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    expect(AppIconService.iconName(AppPalette.meadow), isNull);
    for (final palette in AppPalette.values) {
      final name = AppIconService.iconName(palette);
      if (name == null) continue;
      expect(
        File(
          'ios/Runner/Assets.xcassets/$name.appiconset/icon.png',
        ).existsSync(),
        isTrue,
        reason: '$name: run tool/mascot/mascot.py',
      );
      expect(
        RegExp(
          'ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = "[^"]*\\b$name\\b',
        ).allMatches(project).length,
        3,
        reason: '$name missing from a Runner build configuration',
      );
    }
  });
}

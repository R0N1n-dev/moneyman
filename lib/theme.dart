import 'package:shadcn_flutter/shadcn_flutter.dart';

ThemeData buildTheme(int accentValue, Brightness brightness) {
  final base = brightness == Brightness.light
      ? ColorSchemes.lightZinc
      : ColorSchemes.darkZinc;
  final colorScheme = base.recolor(Color(accentValue));
  return ThemeData(
    colorScheme: colorScheme,
    radius: 0.6,
    scaling: 1.0,
  );
}

const List<int> kAccents = [
  0xFF00897B,
  0xFF3949AB,
  0xFF8E24AA,
  0xFFD81B60,
  0xFFF4511E,
  0xFFF9A825,
  0xFF43A047,
  0xFF1E88E5,
];

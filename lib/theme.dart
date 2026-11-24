import 'package:material_ui/material_ui.dart';

ThemeData buildTheme(Color seed, Brightness brightness) {
  final cs = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: cs.surface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: cs.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cs.surfaceContainer,
      indicatorColor: cs.primaryContainer,
    ),
    dividerColor: Colors.transparent,
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

import 'package:flutter/material.dart';

final themeCtrl = ValueNotifier<ThemeMode>(ThemeMode.dark);

void toggleArcTheme() {
  themeCtrl.value =
  themeCtrl.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}

bool get isArcDark => themeCtrl.value == ThemeMode.dark;

class ArcColors {
  const ArcColors._({
    required this.page,
    required this.surface,
    required this.chip,
    required this.line,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.cta,
    required this.ice,
  });

  final Color page;
  final Color surface;
  final Color chip;
  final Color line;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color cta;
  final Color ice;

  static const dark = ArcColors._(
    page: Color(0xFF050506),
    surface: Color(0xFF0C0E12),
    chip: Color(0xFF16181E),
    line: Color(0xFF2A2C32),
    ink: Color(0xFFE8EEF8),
    muted: Color(0xFF8B97AB),
    faint: Color(0xFF5C6B82),
    cta: Color(0xFF3B82F6),
    ice: Color(0xFFA8C5E8),
  );

  static const cream = ArcColors._(
    page: Color(0xFFF4EFE6),
    surface: Color(0xFFFFFBF4),
    chip: Color(0xFFEDE6D8),
    line: Color(0xFFD9D0C0),
    ink: Color(0xFF1C1914),
    muted: Color(0xFF6F675C),
    faint: Color(0xFF9A9184),
    cta: Color(0xFF3B82F6),
    ice: Color(0xFF3A5A8A),
  );

  static ArcColors of(BuildContext context) {
    return themeCtrl.value == ThemeMode.dark ? ArcColors.dark : ArcColors.cream;
  }
}

ThemeData arcDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ArcColors.dark.page,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3B82F6),
      surface: Color(0xFF0C0E12),
    ),
  );
}

ThemeData arcCreamTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: ArcColors.cream.page,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF3B82F6),
      surface: Color(0xFFFFFBF4),
    ),
  );
}
class ArcLogo extends StatelessWidget {
  const ArcLogo({super.key, this.height = 28});
  final double height;

  @override
  Widget build(BuildContext context) {
    final dark = themeCtrl.value == ThemeMode.dark;
    return Image.asset(
      dark ? 'assets/images/logo_white.png' : 'assets/images/logo.png',
      height: 36,
      filterQuality: FilterQuality.high,
    );
  }
}
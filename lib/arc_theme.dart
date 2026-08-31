import 'dart:ui';

import 'package:flutter/material.dart';

class ArcPalette extends ThemeExtension<ArcPalette> {
  const ArcPalette({
    required this.page,
    required this.card,
    required this.cardHi,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.onAccent,
    required this.chip,
    required this.chipInk,
    required this.sand,
    required this.sandInk,
    required this.nav,
    required this.glass,
    required this.stroke,
  });

  final Color page;
  final Color card;
  final Color cardHi;
  final Color ink;
  final Color muted;
  final Color line;
  final Color accent;
  final Color onAccent;
  final Color chip;
  final Color chipInk;
  final Color sand;
  final Color sandInk;
  final Color nav;
  final Color glass;
  final Color stroke;

  static ArcPalette of(BuildContext context) =>
      Theme.of(context).extension<ArcPalette>()!;

  @override
  ArcPalette copyWith({Color? page}) => this;

  @override
  ArcPalette lerp(ThemeExtension<ArcPalette>? other, double t) => this;
}

const _lightPal = ArcPalette(
  page: Color(0xFFF4F6FA),
  card: Color(0xFFFFFFFF),
  cardHi: Color(0xFFE8EEF8),
  ink: Color(0xFF0F1B2D),
  muted: Color(0xFF6B7A90),
  line: Color(0xFFE3E8F0),
  accent: Color(0xFF1B2B4B),
  onAccent: Colors.white,
  chip: Color(0xFFE8EEF8),
  chipInk: Color(0xFF2C3E5C),
  sand: Color(0xFFFFE8D2),
  sandInk: Color(0xFF8A5A28),
  nav: Color(0xFF0F1B2D),
  glass: Color(0x66FFFFFF),
  stroke: Color(0x99FFFFFF),
);

const _darkPal = ArcPalette(
  page: Color(0xFF070B14),
  card: Color(0xFF141A24),
  cardHi: Color(0xFF1A2740),
  ink: Color(0xFFF2F5FA),
  muted: Color(0xFF8B97AB),
  line: Color(0xFF2A3344),
  accent: Color(0xFF3B82F6),
  onAccent: Colors.white,
  chip: Color(0xFF1A2333),
  chipInk: Color(0xFFB8C7E0),
  sand: Color(0xFF3A2A18),
  sandInk: Color(0xFFE8C48A),
  nav: Color(0xFF0E131C),
  glass: Color(0x33182438),
  stroke: Color(0x55FFFFFF),
);

ThemeData arcLight() => _base(Brightness.light, _lightPal);
ThemeData arcDark() => _base(Brightness.dark, _darkPal);

ThemeData _base(Brightness b, ArcPalette p) {
  return ThemeData(
    useMaterial3: true,
    brightness: b,
    scaffoldBackgroundColor: p.page,
    colorScheme: ColorScheme(
      brightness: b,
      primary: p.accent,
      onPrimary: p.onAccent,
      secondary: p.accent,
      onSecondary: p.onAccent,
      surface: p.card,
      onSurface: p.ink,
      error: const Color(0xFFB4452C),
      onError: Colors.white,
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: p.ink,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: p.ink,
        height: 1.25,
      ),
      bodySmall: TextStyle(color: p.muted, fontSize: 14),
      bodyMedium: TextStyle(color: p.muted, fontSize: 14),
    ),
    extensions: [p],
  );
}

class ArcCard extends StatelessWidget {
  const ArcCard({
    super.key,
    required this.child,
    this.selected = false,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
  });

  final Widget child;
  final bool selected;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final p = ArcPalette.of(context);

    final fill = selected
        ? (dark ? const Color(0xFF1A2433) : const Color(0xFFEEF2F8))
        : (dark ? const Color(0xFF141A24) : const Color(0xFFF4F6FA));

    final shadowDark = dark
        ? Colors.black.withOpacity(0.55)
        : const Color(0xFFC8D0DC);
    final shadowLight = dark
        ? Colors.white.withOpacity(0.07)
        : Colors.white;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: shadowDark,
            offset: const Offset(6, 6),
            blurRadius: 14,
          ),
          BoxShadow(
            color: shadowLight,
            offset: const Offset(-5, -5),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }
}
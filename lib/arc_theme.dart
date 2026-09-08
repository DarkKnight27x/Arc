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

  static ArcPalette of(BuildContext context) {
    final ext = Theme.of(context).extension<ArcPalette>();
    if (ext != null) return ext;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? _darkPal : _creamPal;
  }

  @override
  ArcPalette copyWith({
    Color? page,
    Color? card,
    Color? cardHi,
    Color? ink,
    Color? muted,
    Color? line,
    Color? accent,
    Color? onAccent,
    Color? chip,
    Color? chipInk,
    Color? sand,
    Color? sandInk,
    Color? nav,
    Color? glass,
    Color? stroke,
  }) {
    return ArcPalette(
      page: page ?? this.page,
      card: card ?? this.card,
      cardHi: cardHi ?? this.cardHi,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      chip: chip ?? this.chip,
      chipInk: chipInk ?? this.chipInk,
      sand: sand ?? this.sand,
      sandInk: sandInk ?? this.sandInk,
      nav: nav ?? this.nav,
      glass: glass ?? this.glass,
      stroke: stroke ?? this.stroke,
    );
  }

  @override
  ArcPalette lerp(ThemeExtension<ArcPalette>? other, double t) {
    if (other is! ArcPalette) return this;
    return t < 0.5 ? this : other;
  }
}

const _creamPal = ArcPalette(
  page: Color(0xFFE7E0D4),
  card: Color(0xFFF4EFE6),
  cardHi: Color(0xFFFAF6EE),
  ink: Color(0xFF1A1814),
  muted: Color(0xFF6F675C),
  line: Color(0xB3B7A98F),
  accent: Color(0xFF141518),
  onAccent: Color(0xFFF3F6F8),
  chip: Color(0xFFD9D0C0),
  chipInk: Color(0xFF1A1814),
  sand: Color(0xFFE8D9C4),
  sandInk: Color(0xFF6A4E2A),
  nav: Color(0xFFD4CBBB),
  glass: Color(0x66F4EFE6),
  stroke: Color(0xB3B7A98F),
);

const _darkPal = ArcPalette(
  page: Color(0xFF121317),
  card: Color(0xFF1C1E24),
  cardHi: Color(0xFF24262D),
  ink: Color(0xFFE8EEF4),
  muted: Color(0xFF8B939E),
  line: Color(0x66C5CCD6),
  accent: Color(0xFF141518),
  onAccent: Color(0xFFF3F6F8),
  chip: Color(0xFF16181D),
  chipInk: Color(0xFFE8EEF4),
  sand: Color(0xFF3A2A18),
  sandInk: Color(0xFFE8C48A),
  nav: Color(0xFF0B0C0F),
  glass: Color(0x331C1E24),
  stroke: Color(0x66C5CCD6),
);

ThemeData arcLight() => _base(Brightness.light, _creamPal);
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
      secondary: const Color(0xFF5B8DEF),
      onSecondary: Colors.white,
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
    final p = ArcPalette.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.line, width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            selected ? p.cardHi : Color.lerp(p.cardHi, p.ink, 0.06)!,
            p.card,
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
import 'package:flutter/material.dart';

import '../theme_ctrl.dart';

/// Local control colors keep the profile readable in both ARC themes.
ThemeData profileTheme(BuildContext context, ArcColors c) {
  final base = Theme.of(context);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: c.line),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink),
    colorScheme: base.colorScheme.copyWith(
      primary: c.ink,
      onPrimary: c.page,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.muted,
      error: isArcDark ? const Color(0xFFFFB4AB) : const Color(0xFF9B2525),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.chip,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(borderSide: BorderSide(color: c.ink)),
      labelStyle: TextStyle(color: c.muted),
      hintStyle: TextStyle(color: c.muted),
      floatingLabelStyle: TextStyle(color: c.ink),
      contentPadding: const EdgeInsets.all(16),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.ink,
      selectionColor: c.muted.withValues(alpha: .3),
      selectionHandleColor: c.ink,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.ink,
        foregroundColor: c.page,
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        minimumSize: const Size(48, 48),
        side: BorderSide(color: c.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.ink,
        minimumSize: const Size(48, 48),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: c.chip,
      selectedColor: c.ink,
      disabledColor: c.chip,
      checkmarkColor: c.page,
      side: BorderSide(color: c.line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.title,
    required this.children,
  });
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: isArcDark
          ? metalPanel(c)
          : metalPanel(c).copyWith(
              boxShadow: [
                BoxShadow(
                  color: c.ink.withValues(alpha: .07),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: c.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

String profileNumber(num? value) => value == null
    ? ''
    : value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

String profileLabel(String? value) =>
    value == null || value.trim().isEmpty ? 'Not set' : value.trim();

String dietLabel(String? value) => switch (value) {
  'Veg' => 'Vegetarian',
  'Nonveg' => 'Non-vegetarian',
  'Eggetarian' => 'Eggetarian',
  _ => profileLabel(value),
};

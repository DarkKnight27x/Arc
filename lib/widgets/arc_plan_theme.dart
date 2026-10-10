import 'package:flutter/material.dart';

import '../theme_ctrl.dart';

/// Scoped to the plan builder: preserves ARC tokens without changing app themes.
class ArcPlanTheme extends StatelessWidget {
  const ArcPlanTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final c = ArcColors.of(context);
    final base = Theme.of(context);
    final error = isArcDark ? const Color(0xFFFFB4AB) : const Color(0xFF9B2525);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: c.line),
    );
    final button = FilledButton.styleFrom(
      foregroundColor: c.page,
      backgroundColor: c.ink,
      disabledForegroundColor: c.muted,
      disabledBackgroundColor: c.chip,
      minimumSize: const Size(48, 52),
    );
    return Theme(
      data: base.copyWith(
        brightness: isArcDark ? Brightness.dark : Brightness.light,
        textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink),
        primaryTextTheme: base.primaryTextTheme.apply(
          bodyColor: c.ink,
          displayColor: c.ink,
        ),
        disabledColor: c.muted,
        colorScheme: base.colorScheme.copyWith(
          brightness: isArcDark ? Brightness.dark : Brightness.light,
          primary: c.ink,
          onPrimary: c.page,
          surface: c.surface,
          onSurface: c.ink,
          onSurfaceVariant: c.muted,
          error: error,
        ),
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: c.page,
          foregroundColor: c.ink,
          surfaceTintColor: Colors.transparent,
        ),
        iconTheme: IconThemeData(color: c.ink),
        cardTheme: base.cardTheme.copyWith(
          color: c.surface,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: c.chip,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(borderSide: BorderSide(color: c.ink)),
          labelStyle: TextStyle(color: c.muted),
          floatingLabelStyle: TextStyle(color: c.ink),
          hintStyle: TextStyle(color: c.muted),
          helperStyle: TextStyle(color: c.muted),
          errorStyle: TextStyle(color: error),
          errorMaxLines: 3,
        ),
        filledButtonTheme: FilledButtonThemeData(style: button),
        elevatedButtonTheme: ElevatedButtonThemeData(style: button),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: c.ink,
            disabledForegroundColor: c.muted,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: c.ink,
            disabledForegroundColor: c.muted,
          ),
        ),
        chipTheme: base.chipTheme.copyWith(
          backgroundColor: c.chip,
          selectedColor: c.ink,
          disabledColor: c.chip,
          labelStyle: TextStyle(color: c.ink),
          secondaryLabelStyle: TextStyle(color: c.page),
          checkmarkColor: c.page,
          side: BorderSide(color: c.line),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: c.ink,
          circularTrackColor: c.line,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: c.surface,
          textStyle: TextStyle(color: c.ink),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: c.surface,
          titleTextStyle: base.textTheme.titleLarge?.copyWith(color: c.ink),
          contentTextStyle: base.textTheme.bodyMedium?.copyWith(color: c.ink),
        ),
      ),
      child: child,
    );
  }
}

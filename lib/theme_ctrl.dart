import
'package:flutter/material.dart';

final themeCtrl = ValueNotifier<ThemeMode>(ThemeMode.light);

void toggleArcTheme() {
  themeCtrl.value =
  themeCtrl.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}
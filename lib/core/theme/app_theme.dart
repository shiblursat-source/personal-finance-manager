import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();
  static const Color seed = Color(0xFF0E7C61);
  static ThemeData light() => ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light), useMaterial3: true, inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(), isDense: true));
  static ThemeData dark() => ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark), useMaterial3: true);
}

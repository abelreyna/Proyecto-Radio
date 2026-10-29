import 'package:flutter/material.dart';

/// Colores y estilos de la app para Modo Claro y Modo Oscuro.
abstract final class AppTheme {
  /// Rojo de la bandera del Perú como color semilla de Material 3.
  static const Color seedColor = Color(0xFFD91023);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seedColor);
    return _base(scheme);
  }

  /// El modo oscuro usa negro puro de fondo: en pantallas OLED los píxeles
  /// negros se apagan y se ahorra batería.
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ).copyWith(surface: Colors.black);
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      visualDensity: VisualDensity.standard,
    );
  }
}

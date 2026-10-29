import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/station_model.dart';

/// Lectura y escritura de Favoritos y preferencias en la memoria del
/// dispositivo. No requiere inicio de sesión.
class StorageService {
  StorageService(this._prefs);

  static Future<StorageService> create() async =>
      StorageService(await SharedPreferences.getInstance());

  final SharedPreferences _prefs;

  static const String _kFavoriteIds = 'favorite_ids';
  static const String _kFavoriteSnapshots = 'favorite_snapshots';
  static const String _kThemeMode = 'theme_mode';
  static const String _kCuratedCache = 'curated_catalog_cache';

  // ---------------------------------------------------------------------------
  // Favoritos
  // ---------------------------------------------------------------------------

  /// IDs de las emisoras favoritas, en el orden en que se agregaron.
  List<String> getFavoriteIds() => _prefs.getStringList(_kFavoriteIds) ?? [];

  /// Copia de los datos de cada favorito. Permite mostrarlos aunque la emisora
  /// ya no venga en el catálogo descargado (por ejemplo, sin conexión).
  Map<String, Station> getFavoriteSnapshots() {
    final raw = _prefs.getString(_kFavoriteSnapshots);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final stations = list
          .whereType<Map<String, dynamic>>()
          .map(Station.fromJson)
          .where((station) => station.isValid);
      return {for (final station in stations) station.id: station};
    } on FormatException {
      return {};
    }
  }

  Future<void> saveFavorites(List<Station> favorites) async {
    await _prefs.setStringList(
      _kFavoriteIds,
      favorites.map((station) => station.id).toList(),
    );
    await _prefs.setString(
      _kFavoriteSnapshots,
      jsonEncode(favorites.map((station) => station.toJson()).toList()),
    );
  }

  // ---------------------------------------------------------------------------
  // Tema
  // ---------------------------------------------------------------------------

  ThemeMode getThemeMode() {
    final value = _prefs.getString(_kThemeMode);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) =>
      _prefs.setString(_kThemeMode, mode.name);

  // ---------------------------------------------------------------------------
  // Caché del catálogo curado
  // ---------------------------------------------------------------------------

  /// Último `radios_peru.json` descargado correctamente desde GitHub.
  String? getCuratedCache() => _prefs.getString(_kCuratedCache);

  Future<void> saveCuratedCache(String json) =>
      _prefs.setString(_kCuratedCache, json);
}

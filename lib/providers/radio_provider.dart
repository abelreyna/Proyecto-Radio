import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/text_utils.dart';
import '../models/station_model.dart';
import '../services/audio_handler.dart';
import '../services/deep_link_service.dart';
import '../services/radio_api_service.dart';
import '../services/storage_service.dart';

/// Estado global de la app: catálogo, filtros, reproducción, favoritos,
/// temporizador y tema.
class RadioProvider extends ChangeNotifier {
  RadioProvider({
    required this._api,
    required StorageService storage,
    required RadioPlayer player,
  })  : _storage = storage,
        _player = player,
        _themeMode = storage.getThemeMode(),
        _favoriteIds = storage.getFavoriteIds().toList(),
        _favoriteSnapshots = storage.getFavoriteSnapshots() {
    _subscriptions
      ..add(player.statusStream.listen(_onStatus))
      ..add(player.nowPlayingStream.listen(_onNowPlaying))
      ..add(player.errorStream.listen(_onPlayerError));
  }

  final RadioApiService _api;
  final StorageService _storage;
  final RadioPlayer _player;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  // ---------------------------------------------------------------------------
  // Catálogo
  // ---------------------------------------------------------------------------

  List<Station> _stations = const [];
  Map<String, Station> _byId = const {};
  bool _isLoading = false;
  bool _radioBrowserAvailable = true;

  List<Station> get stations => _stations;
  bool get isLoading => _isLoading;
  bool get hasStations => _stations.isNotEmpty;

  /// `false` si no se pudo consultar Radio Browser y solo se muestra el
  /// catálogo curado.
  bool get radioBrowserAvailable => _radioBrowserAvailable;

  List<Station> get featuredStations =>
      _stations.where((station) => station.esDestacada).toList();

  Future<void> loadStations() async {
    if (_isLoading) return;
    _isLoading = true;
    notifyListeners();
    try {
      final catalog = await _api.loadCatalog();
      _stations = catalog.stations;
      _byId = {for (final station in _stations) station.id: station};
      _radioBrowserAvailable = catalog.radioBrowserAvailable;
      _refreshFilterOptions();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    final pending = _pendingStationId;
    if (pending != null) {
      _pendingStationId = null;
      await playStationById(pending);
    }
  }

  // ---------------------------------------------------------------------------
  // Buscador y filtros
  // ---------------------------------------------------------------------------

  String _query = '';
  String? _region;
  String? _genre;
  List<String> _regions = const [];
  List<String> _genres = const [];

  String get query => _query;
  String? get selectedRegion => _region;
  String? get selectedGenre => _genre;

  /// Regiones presentes en el catálogo, en orden alfabético.
  List<String> get regions => _regions;

  /// Géneros presentes en el catálogo, en el orden de
  /// [AppConstants.genreOrder].
  List<String> get genres => _genres;

  bool get hasActiveFilters =>
      _query.isNotEmpty || _region != null || _genre != null;

  /// Emisoras que cumplen la búsqueda y los filtros activos.
  List<Station> get filteredStations {
    if (!hasActiveFilters) return _stations;
    final terms = normalizeText(_query)
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
    return _stations.where((station) {
      if (_region != null && station.region != _region) return false;
      if (_genre != null && station.genero != _genre) return false;
      return terms.every(station.searchKey.contains);
    }).toList();
  }

  void setQuery(String value) {
    final trimmed = value.trim();
    if (trimmed == _query) return;
    _query = trimmed;
    notifyListeners();
  }

  /// Selecciona una región; volver a pulsar la misma la quita.
  void setRegion(String? region) {
    _region = region == _region ? null : region;
    notifyListeners();
  }

  /// Selecciona un género; volver a pulsar el mismo lo quita.
  void setGenre(String? genre) {
    _genre = genre == _genre ? null : genre;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _region = null;
    _genre = null;
    notifyListeners();
  }

  void _refreshFilterOptions() {
    _regions = {
      for (final station in _stations)
        if (station.region.isNotEmpty) station.region,
    }.toList()
      ..sort(compareNormalized);

    final present = {for (final station in _stations) station.genero};
    final order = AppConstants.genreOrder;
    _genres = present.toList()
      ..sort((a, b) {
        final ia = order.indexOf(a);
        final ib = order.indexOf(b);
        if (ia == -1 && ib == -1) return compareNormalized(a, b);
        if (ia == -1) return 1;
        if (ib == -1) return -1;
        return ia.compareTo(ib);
      });

    if (_region != null && !_regions.contains(_region)) _region = null;
    if (_genre != null && !_genres.contains(_genre)) _genre = null;
  }

  // ---------------------------------------------------------------------------
  // Reproducción
  // ---------------------------------------------------------------------------

  Station? _current;
  PlaybackStatus _status = PlaybackStatus.idle;
  String? _nowPlaying;
  String? _errorMessage;
  String? _pendingStationId;

  Station? get currentStation => _current;
  PlaybackStatus get status => _status;
  bool get isPlaying => _status == PlaybackStatus.playing;
  bool get isBusy => _status == PlaybackStatus.loading;

  /// Canción o programa en curso según los metadatos ICY de la emisora.
  String? get nowPlaying => _nowPlaying;

  /// Último error de reproducción, para mostrarlo en el reproductor.
  String? get errorMessage => _errorMessage;

  bool isCurrent(Station station) => _current?.id == station.id;

  Future<void> play(Station station) async {
    _current = station;
    _status = PlaybackStatus.loading;
    _nowPlaying = null;
    _errorMessage = null;
    notifyListeners();
    await _player.playStation(station);
  }

  /// Play/Pausa de la emisora actual. Si estaba en error, reintenta.
  Future<void> togglePlayPause() async {
    final station = _current;
    if (station == null) return;
    switch (_status) {
      case PlaybackStatus.playing:
      case PlaybackStatus.loading:
        _status = PlaybackStatus.paused;
        notifyListeners();
        await _player.pause();
      case PlaybackStatus.paused:
        await _player.resume();
      case PlaybackStatus.idle:
      case PlaybackStatus.error:
        await play(station);
    }
  }

  /// Detiene el audio y oculta el mini reproductor.
  Future<void> stop() async {
    await _player.stop();
    _current = null;
    _status = PlaybackStatus.idle;
    _nowPlaying = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _onStatus(PlaybackStatus status) {
    // Tras un error el reproductor pasa a "idle"; se conserva el error para
    // que el usuario vea qué ocurrió.
    if (_status == PlaybackStatus.error && status == PlaybackStatus.idle) {
      return;
    }
    // Mientras se conecta una emisora nueva el reproductor pasa un instante
    // por "idle" o "pausado" antes de empezar a sonar; se ignoran.
    if (_status == PlaybackStatus.loading &&
        (status == PlaybackStatus.idle || status == PlaybackStatus.paused)) {
      return;
    }
    if (status == _status) return;
    _status = status;
    if (status == PlaybackStatus.playing) _errorMessage = null;
    notifyListeners();
  }

  void _onNowPlaying(String? title) {
    if (title == _nowPlaying) return;
    _nowPlaying = title;
    notifyListeners();
  }

  void _onPlayerError(String message) {
    _status = PlaybackStatus.error;
    _errorMessage = message;
    _nowPlaying = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Temporizador de apagado
  // ---------------------------------------------------------------------------

  ValueListenable<Duration?> get sleepRemaining => _player.sleepRemaining;

  /// Programa el apagado automático; `null` lo cancela.
  void setSleepTimer(Duration? duration) {
    if (duration == null) {
      _player.cancelSleepTimer();
    } else {
      _player.setSleepTimer(duration);
    }
  }

  // ---------------------------------------------------------------------------
  // Favoritos
  // ---------------------------------------------------------------------------

  final List<String> _favoriteIds;
  final Map<String, Station> _favoriteSnapshots;

  /// Favoritos en el orden en que se guardaron. Si una emisora ya no está en
  /// el catálogo se usa la copia guardada en el dispositivo.
  List<Station> get favoriteStations => [
        for (final id in _favoriteIds) ?(_byId[id] ?? _favoriteSnapshots[id]),
      ];

  bool isFavorite(Station station) => _favoriteIds.contains(station.id);

  Future<void> toggleFavorite(Station station) async {
    if (isFavorite(station)) {
      _favoriteIds.remove(station.id);
      _favoriteSnapshots.remove(station.id);
    } else {
      _favoriteIds.add(station.id);
      _favoriteSnapshots[station.id] = station;
    }
    notifyListeners();
    await _storage.saveFavorites(favoriteStations);
  }

  // ---------------------------------------------------------------------------
  // Enlaces profundos
  // ---------------------------------------------------------------------------

  /// Abre la emisora indicada en un enlace compartido y la reproduce.
  Future<void> handleDeepLink(Uri uri) async {
    final id = DeepLinkService.stationIdFrom(uri);
    if (id == null) return;
    if (_isLoading || !hasStations) {
      // El catálogo aún no está listo: se reproduce al terminar de cargar.
      _pendingStationId = id;
      return;
    }
    await playStationById(id);
  }

  Future<void> playStationById(String id) async {
    if (_current?.id == id && _status != PlaybackStatus.error) return;
    final station = _byId[id] ??
        _favoriteSnapshots[id] ??
        await _api.fetchRadioBrowserStation(id);
    if (station == null) {
      _errorMessage = 'La emisora compartida ya no está disponible.';
      notifyListeners();
      return;
    }
    await play(station);
  }

  // ---------------------------------------------------------------------------
  // Tema
  // ---------------------------------------------------------------------------

  ThemeMode _themeMode;
  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _storage.saveThemeMode(mode);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}

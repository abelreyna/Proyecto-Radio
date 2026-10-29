import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../core/text_utils.dart';
import '../models/station_model.dart';
import 'storage_service.dart';

/// Resultado de cargar el catálogo híbrido.
class StationCatalog {
  const StationCatalog({
    required this.stations,
    required this.curatedFromNetwork,
    required this.radioBrowserAvailable,
  });

  final List<Station> stations;

  /// `true` si el JSON curado se descargó de GitHub en esta carga (y no de la
  /// caché o de la copia empaquetada).
  final bool curatedFromNetwork;

  /// `false` si ningún servidor de Radio Browser respondió.
  final bool radioBrowserAvailable;
}

/// Servicio híbrido: combina el JSON curado de GitHub con las emisoras
/// peruanas de Radio Browser API.
class RadioApiService {
  RadioApiService({
    required this._storage,
    http.Client? client,
    AssetBundle? bundle,
  })  : _client = client ?? http.Client(),
        _bundle = bundle ?? rootBundle;

  final StorageService _storage;
  final http.Client _client;
  final AssetBundle _bundle;

  static const Map<String, String> _headers = {
    'User-Agent': AppConstants.userAgent,
  };

  /// Descarga ambos catálogos en paralelo y los une.
  Future<StationCatalog> loadCatalog() async {
    final curatedFuture = _loadCurated();
    final automatedFuture = fetchRadioBrowserStations();
    final (curated, fromNetwork) = await curatedFuture;
    final automated = await automatedFuture;
    return StationCatalog(
      stations: mergeStations(curated, automated ?? const []),
      curatedFromNetwork: fromNetwork,
      radioBrowserAvailable: automated != null,
    );
  }

  /// Catálogo curado: primero GitHub, luego la última copia descargada y, si
  /// todo falla, el JSON empaquetado en la app.
  Future<(List<Station>, bool)> _loadCurated() async {
    try {
      final response = await _client
          .get(Uri.parse(AppConstants.curatedJsonUrl), headers: _headers)
          .timeout(AppConstants.networkTimeout);
      if (response.statusCode == 200) {
        final body = utf8.decode(response.bodyBytes);
        final stations = parseCuratedJson(body);
        if (stations.isNotEmpty) {
          await _storage.saveCuratedCache(body);
          return (stations, true);
        }
      }
    } catch (_) {
      // Sin conexión o repositorio privado: se usa la copia local.
    }

    final cached = _storage.getCuratedCache();
    if (cached != null) {
      final stations = parseCuratedJson(cached);
      if (stations.isNotEmpty) return (stations, false);
    }

    final bundled = await _bundle.loadString(AppConstants.curatedAssetPath);
    return (parseCuratedJson(bundled), false);
  }

  /// Emisoras peruanas de Radio Browser ordenadas por popularidad. Devuelve
  /// `null` si ningún servidor espejo respondió.
  Future<List<Station>?> fetchRadioBrowserStations() async {
    for (final host in AppConstants.radioBrowserHosts) {
      try {
        final uri = Uri.https(host, '/json/stations/search', {
          'countrycode': AppConstants.radioBrowserCountryCode,
          'hidebroken': 'true',
          'order': 'clickcount',
          'reverse': 'true',
          'limit': '${AppConstants.radioBrowserLimit}',
        });
        final response = await _client
            .get(uri, headers: _headers)
            .timeout(AppConstants.networkTimeout);
        if (response.statusCode == 200) {
          return parseRadioBrowserJson(utf8.decode(response.bodyBytes));
        }
      } catch (_) {
        // Se prueba con el siguiente servidor espejo.
      }
    }
    return null;
  }

  /// Busca una emisora concreta de Radio Browser por su ID (`rb_<uuid>`).
  /// Se usa cuando un enlace compartido apunta a una emisora que no está en
  /// la lista descargada.
  Future<Station?> fetchRadioBrowserStation(String stationId) async {
    if (!stationId.startsWith('rb_')) return null;
    final uuid = stationId.substring(3);
    for (final host in AppConstants.radioBrowserHosts) {
      try {
        final uri = Uri.https(host, '/json/stations/byuuid/$uuid');
        final response = await _client
            .get(uri, headers: _headers)
            .timeout(AppConstants.networkTimeout);
        if (response.statusCode == 200) {
          final stations =
              parseRadioBrowserJson(utf8.decode(response.bodyBytes));
          return stations.isEmpty ? null : stations.first;
        }
      } catch (_) {
        // Se prueba con el siguiente servidor espejo.
      }
    }
    return null;
  }

  static List<Station> parseCuratedJson(String body) =>
      _parseList(body, Station.fromJson);

  static List<Station> parseRadioBrowserJson(String body) =>
      _parseList(body, Station.fromRadioBrowser);

  /// Decodifica una lista JSON de emisoras ignorando entradas inválidas. Un
  /// cuerpo mal formado devuelve una lista vacía en lugar de lanzar error.
  static List<Station> _parseList(
    String body,
    Station Function(Map<String, dynamic>) parse,
  ) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      return const [];
    }
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(parse)
        .where((station) => station.isValid)
        .toList();
  }

  /// Une el catálogo curado con el automático. El curado tiene prioridad: se
  /// descartan las emisoras de Radio Browser que repiten una curada (mismo
  /// stream o mismo nombre en la misma región) y los duplicados internos de
  /// Radio Browser.
  static List<Station> mergeStations(
    List<Station> curated,
    List<Station> automated,
  ) {
    final result = <Station>[];
    final seenIds = <String>{};
    final seenStreams = <String>{};
    final seenNames = <String, Set<String>>{};

    bool isDuplicate(Station station) {
      if (seenIds.contains(station.id)) return true;
      if (seenStreams.contains(streamKey(station.urlStream))) return true;
      final name = nameKey(station.nombre);
      final regions = seenNames[name];
      if (name.isEmpty || regions == null) return false;
      return station.region.isEmpty ||
          regions.contains('') ||
          regions.contains(station.region);
    }

    void add(Station station) {
      result.add(station);
      seenIds.add(station.id);
      seenStreams.add(streamKey(station.urlStream));
      final name = nameKey(station.nombre);
      if (name.isNotEmpty) {
        seenNames.putIfAbsent(name, () => <String>{}).add(station.region);
      }
    }

    for (final station in curated) {
      if (!seenIds.contains(station.id)) add(station);
    }
    for (final station in automated) {
      if (!isDuplicate(station)) add(station);
    }
    return result;
  }

  /// Clave de comparación de una URL de stream: sin esquema, parámetros ni
  /// barra final.
  static String streamKey(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return url.trim().toLowerCase();
    var path = uri.path;
    while (path.endsWith('/') || path.endsWith(';')) {
      path = path.substring(0, path.length - 1);
    }
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.host.toLowerCase()}$port$path';
  }

  static const Set<String> _nameStopWords = {
    'radio', 'fm', 'am', 'f', 'm', 'la', 'el', 'lima', 'peru', 'en', 'vivo',
    'online', 'de', 'stereo', 'estereo',
  };

  /// Clave de comparación de un nombre: sin tildes, números, signos ni
  /// palabras genéricas ("Radio Corazón (94.3 FM Lima)" → "corazon").
  static String nameKey(String name) {
    return normalizeText(name)
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) =>
            word.isNotEmpty &&
            !_nameStopWords.contains(word) &&
            int.tryParse(word) == null)
        .join(' ');
  }
}

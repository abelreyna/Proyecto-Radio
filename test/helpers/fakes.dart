import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:radios_peru_mix/core/constants.dart';
import 'package:radios_peru_mix/models/station_model.dart';
import 'package:radios_peru_mix/services/audio_handler.dart';

/// Reproductor falso que registra las llamadas sin usar plugins nativos.
class FakeRadioPlayer implements RadioPlayer {
  final StreamController<PlaybackStatus> _status = StreamController.broadcast();
  final StreamController<String?> _nowPlaying = StreamController.broadcast();
  final StreamController<String> _errors = StreamController.broadcast();
  final ValueNotifier<Duration?> _sleep = ValueNotifier(null);

  final List<Station> played = [];
  int pauses = 0;
  int stops = 0;

  /// Si es `true`, la próxima emisora falla al conectar.
  bool failNext = false;

  @override
  Stream<PlaybackStatus> get statusStream => _status.stream;
  @override
  Stream<String?> get nowPlayingStream => _nowPlaying.stream;
  @override
  Stream<String> get errorStream => _errors.stream;
  @override
  ValueListenable<Duration?> get sleepRemaining => _sleep;

  void emitNowPlaying(String? title) => _nowPlaying.add(title);

  @override
  Future<void> playStation(Station station) async {
    played.add(station);
    if (failNext) {
      failNext = false;
      _errors.add('No se pudo conectar con ${station.nombre}.');
      _status.add(PlaybackStatus.idle);
    } else {
      _status.add(PlaybackStatus.playing);
    }
  }

  @override
  Future<void> pause() async {
    pauses++;
    _status.add(PlaybackStatus.paused);
  }

  @override
  Future<void> resume() async => _status.add(PlaybackStatus.playing);

  @override
  Future<void> stop() async {
    stops++;
    _sleep.value = null;
    _status.add(PlaybackStatus.idle);
  }

  @override
  void setSleepTimer(Duration duration) => _sleep.value = duration;

  @override
  void cancelSleepTimer() => _sleep.value = null;
}

/// Catálogo curado de ejemplo (sin logos, para no hacer peticiones de red en
/// las pruebas de interfaz).
const List<Map<String, Object>> sampleCurated = [
  {
    'id': 'pe_rpp_lima',
    'nombre': 'RPP Noticias',
    'frecuencia': '89.7 FM',
    'region': 'Lima',
    'genero': 'Noticias',
    'url_stream': 'https://example.com/rpp',
    'url_logo': '',
    'es_destacada': true,
  },
  {
    'id': 'pe_moda_lima',
    'nombre': 'Radio Moda',
    'frecuencia': '97.3 FM',
    'region': 'Lima',
    'genero': 'Urbano',
    'url_stream': 'https://example.com/moda',
    'url_logo': '',
    'es_destacada': false,
  },
  {
    'id': 'pe_yaravi_arequipa',
    'nombre': 'Radio Yaraví',
    'frecuencia': '',
    'region': 'Arequipa',
    'genero': 'Noticias',
    'url_stream': 'https://example.com/yaravi',
    'url_logo': '',
    'es_destacada': false,
  },
];

/// Respuesta de Radio Browser de ejemplo: una emisora nueva y un duplicado
/// de RPP que debe descartarse al unir catálogos.
const List<Map<String, Object>> sampleRadioBrowser = [
  {
    'stationuuid': 'aaaa-1111',
    'name': 'Radio Salkantay 101.5 FM',
    'url': 'https://example.com/salkantay',
    'url_resolved': '',
    'favicon': '',
    'tags': 'cumbia peruana,tropical',
    'state': 'Cusco',
  },
  {
    'stationuuid': 'bbbb-2222',
    'name': 'Radio RPP Noticias',
    'url': 'https://example.com/rpp-otro',
    'url_resolved': '',
    'favicon': '',
    'tags': 'news',
    'state': 'Lima',
  },
];

/// Cliente HTTP falso: sirve el catálogo curado y la respuesta de Radio
/// Browser indicados; devuelve 503 si se pasa `null`.
http.Client fakeHttpClient({
  List<Map<String, Object>>? curated = sampleCurated,
  List<Map<String, Object>>? radioBrowser = sampleRadioBrowser,
}) {
  return MockClient((request) async {
    final url = request.url.toString();
    if (url == AppConstants.curatedJsonUrl) {
      return curated == null
          ? http.Response('', 503)
          : _json(curated);
    }
    if (request.url.path.startsWith('/json/stations/byuuid/')) {
      final uuid = request.url.pathSegments.last;
      final matches = (radioBrowser ?? const [])
          .where((station) => station['stationuuid'] == uuid)
          .toList();
      return _json(matches);
    }
    if (request.url.path == '/json/stations/search') {
      return radioBrowser == null
          ? http.Response('', 503)
          : _json(radioBrowser);
    }
    return http.Response('', 404);
  });
}

http.Response _json(Object body) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      200,
      headers: {'content-type': 'application/json'},
    );

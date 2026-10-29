import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radios_peru_mix/core/constants.dart';
import 'package:radios_peru_mix/models/station_model.dart';
import 'package:radios_peru_mix/services/radio_api_service.dart';
import 'package:radios_peru_mix/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.create();
  });

  group('radios_peru.json empaquetado', () {
    test('todas las emisoras son válidas y sus IDs únicos', () async {
      final body = await rootBundle.loadString(AppConstants.curatedAssetPath);
      final stations = RadioApiService.parseCuratedJson(body);

      expect(stations, isNotEmpty);
      expect(stations.map((s) => s.id).toSet().length, stations.length);
      for (final station in stations) {
        expect(station.isValid, isTrue, reason: station.id);
        expect(AppConstants.genreOrder, contains(station.genero),
            reason: '${station.id}: género "${station.genero}"');
      }
      expect(stations.where((s) => s.esDestacada), isNotEmpty);
    });
  });

  group('loadCatalog', () {
    test('une el catálogo curado y Radio Browser sin duplicados', () async {
      final api = RadioApiService(storage: storage, client: fakeHttpClient());
      final catalog = await api.loadCatalog();

      expect(catalog.curatedFromNetwork, isTrue);
      expect(catalog.radioBrowserAvailable, isTrue);
      expect(catalog.stations.map((s) => s.id), [
        'pe_rpp_lima',
        'pe_moda_lima',
        'pe_yaravi_arequipa',
        'rb_aaaa-1111',
      ]);

      final salkantay = catalog.stations.last;
      expect(salkantay.source, StationSource.radioBrowser);
      expect(salkantay.region, 'Cusco');
      expect(salkantay.genero, 'Cumbia');
      expect(salkantay.frecuencia, '101.5 FM');
    });

    test('guarda el JSON descargado y lo usa si GitHub no responde', () async {
      await RadioApiService(storage: storage, client: fakeHttpClient())
          .loadCatalog();

      final offline = RadioApiService(
        storage: storage,
        client: fakeHttpClient(curated: null, radioBrowser: null),
      );
      final catalog = await offline.loadCatalog();

      expect(catalog.curatedFromNetwork, isFalse);
      expect(catalog.radioBrowserAvailable, isFalse);
      expect(catalog.stations.map((s) => s.id),
          ['pe_rpp_lima', 'pe_moda_lima', 'pe_yaravi_arequipa']);
    });

    test('sin red ni caché usa el JSON empaquetado', () async {
      final api = RadioApiService(
        storage: storage,
        client: fakeHttpClient(curated: null, radioBrowser: null),
      );
      final catalog = await api.loadCatalog();

      expect(catalog.stations.length, greaterThan(20));
      expect(catalog.stations.first.id, 'pe_rpp_lima');
    });
  });

  test('fetchRadioBrowserStation busca por UUID', () async {
    final api = RadioApiService(storage: storage, client: fakeHttpClient());

    final station = await api.fetchRadioBrowserStation('rb_aaaa-1111');
    expect(station?.nombre, 'Radio Salkantay 101.5 FM');
    expect(await api.fetchRadioBrowserStation('pe_rpp_lima'), isNull);
  });

  group('claves de duplicados', () {
    test('nameKey ignora palabras genéricas, números y tildes', () {
      expect(RadioApiService.nameKey('Radio Corazón (94.3 FM Lima)'), 'corazon');
      expect(RadioApiService.nameKey('Radio Exitosa 95.5 f.m'), 'exitosa');
      expect(RadioApiService.nameKey('La Karibeña'), 'karibena');
    });

    test('streamKey ignora esquema, parámetros y barra final', () {
      expect(
        RadioApiService.streamKey('http://host.pe:8000/stream/;?token=1'),
        RadioApiService.streamKey('https://HOST.pe:8000/stream'),
      );
    });

    test('mantiene emisoras homónimas de regiones distintas', () {
      final curated = [
        Station(id: 'a', nombre: 'Radio Nova', region: 'Áncash', urlStream: 'https://a.pe/1'),
      ];
      final automated = [
        Station(id: 'b', nombre: 'Radio Nova', region: 'Lima', urlStream: 'https://b.pe/2'),
        Station(id: 'c', nombre: 'Nova', region: 'Áncash', urlStream: 'https://c.pe/3'),
      ];
      final merged = RadioApiService.mergeStations(curated, automated);
      expect(merged.map((s) => s.id), ['a', 'b']);
    });
  });
}

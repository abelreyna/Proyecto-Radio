import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radios_peru_mix/models/station_model.dart';
import 'package:radios_peru_mix/providers/radio_provider.dart';
import 'package:radios_peru_mix/services/audio_handler.dart';
import 'package:radios_peru_mix/services/deep_link_service.dart';
import 'package:radios_peru_mix/services/radio_api_service.dart';
import 'package:radios_peru_mix/services/share_service.dart';
import 'package:radios_peru_mix/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late FakeRadioPlayer player;

  Future<RadioProvider> createProvider({bool load = true}) async {
    final provider = RadioProvider(
      api: RadioApiService(storage: storage, client: fakeHttpClient()),
      storage: storage,
      player: player,
    );
    if (load) await provider.loadStations();
    return provider;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.create();
    player = FakeRadioPlayer();
  });

  group('filtros', () {
    test('expone regiones y géneros presentes en orden', () async {
      final provider = await createProvider();
      expect(provider.regions, ['Arequipa', 'Cusco', 'Lima']);
      expect(provider.genres, ['Noticias', 'Cumbia', 'Urbano']);
    });

    test('combina búsqueda, región y género', () async {
      final provider = await createProvider();

      provider.setGenre('Noticias');
      expect(provider.filteredStations.map((s) => s.id),
          ['pe_rpp_lima', 'pe_yaravi_arequipa']);

      provider.setRegion('Arequipa');
      expect(provider.filteredStations.map((s) => s.id), ['pe_yaravi_arequipa']);

      // Volver a pulsar la misma región la quita.
      provider.setRegion('Arequipa');
      provider.setGenre(null);
      provider.setQuery('yarav');
      expect(provider.filteredStations.map((s) => s.id), ['pe_yaravi_arequipa']);

      provider.setQuery('97.3');
      expect(provider.filteredStations.map((s) => s.id), ['pe_moda_lima']);

      provider.clearFilters();
      expect(provider.hasActiveFilters, isFalse);
      expect(provider.filteredStations.length, 4);
    });
  });

  group('favoritos', () {
    test('se guardan en el dispositivo y se recuperan', () async {
      final provider = await createProvider();
      final moda = provider.stations[1];

      await provider.toggleFavorite(moda);
      expect(provider.isFavorite(moda), isTrue);
      expect(storage.getFavoriteIds(), ['pe_moda_lima']);

      // Una sesión nueva sin catálogo cargado los muestra desde la copia local.
      final restored = await createProvider(load: false);
      expect(restored.favoriteStations.map((s) => s.nombre), ['Radio Moda']);

      await restored.toggleFavorite(moda);
      expect(storage.getFavoriteIds(), isEmpty);
    });
  });

  group('reproducción', () {
    test('reproduce, pausa, reanuda y detiene', () async {
      final provider = await createProvider();
      final rpp = provider.stations.first;

      await provider.play(rpp);
      await pumpEventQueue();
      expect(provider.currentStation, rpp);
      expect(provider.status, PlaybackStatus.playing);

      await provider.togglePlayPause();
      await pumpEventQueue();
      expect(provider.status, PlaybackStatus.paused);

      await provider.togglePlayPause();
      await pumpEventQueue();
      expect(provider.status, PlaybackStatus.playing);

      await provider.stop();
      expect(provider.currentStation, isNull);
      expect(player.stops, 1);
    });

    test('conserva el error de conexión y permite reintentar', () async {
      final provider = await createProvider();
      player.failNext = true;

      await provider.play(provider.stations.first);
      await pumpEventQueue();
      expect(provider.status, PlaybackStatus.error);
      expect(provider.errorMessage, contains('RPP Noticias'));

      await provider.togglePlayPause();
      await pumpEventQueue();
      expect(provider.status, PlaybackStatus.playing);
      expect(provider.errorMessage, isNull);
      expect(player.played.length, 2);
    });

    test('muestra la canción en curso (ICY)', () async {
      final provider = await createProvider();
      await provider.play(provider.stations.first);
      player.emitNowPlaying('Artista - Canción');
      await pumpEventQueue();
      expect(provider.nowPlaying, 'Artista - Canción');
    });

    test('programa y cancela el temporizador de apagado', () async {
      final provider = await createProvider();
      provider.setSleepTimer(const Duration(minutes: 30));
      expect(provider.sleepRemaining.value, const Duration(minutes: 30));
      provider.setSleepTimer(null);
      expect(provider.sleepRemaining.value, isNull);
    });
  });

  group('enlaces profundos', () {
    test('el enlace compartido abre la emisora correcta', () {
      final station = Station(
        id: 'rb_aaaa-1111',
        nombre: 'Radio Salkantay',
        urlStream: 'https://example.com',
      );
      final uri = DeepLinkService.stationUri(station);
      expect(uri.toString(), 'radiosperumix://station/rb_aaaa-1111');
      expect(DeepLinkService.stationIdFrom(uri), 'rb_aaaa-1111');
      expect(ShareService.stationMessage(station), contains(uri.toString()));
    });

    test('acepta enlaces web con /station/<id> o ?station=<id>', () {
      expect(
        DeepLinkService.stationIdFrom(
            Uri.parse('https://radiosperumix.pe/station/pe_rpp_lima')),
        'pe_rpp_lima',
      );
      expect(
        DeepLinkService.stationIdFrom(
            Uri.parse('https://radiosperumix.pe/?station=pe_moda_lima')),
        'pe_moda_lima',
      );
      expect(DeepLinkService.stationIdFrom(Uri.parse('radiosperumix://otro')),
          isNull);
    });

    test('si llega antes de cargar el catálogo, reproduce al terminar', () async {
      final provider = await createProvider(load: false);
      await provider.handleDeepLink(Uri.parse('radiosperumix://station/pe_moda_lima'));
      expect(player.played, isEmpty);

      await provider.loadStations();
      expect(player.played.single.id, 'pe_moda_lima');
    });

    test('busca en Radio Browser una emisora fuera de la lista', () async {
      final provider = await createProvider();
      await provider.playStationById('rb_aaaa-1111');
      expect(player.played.single.nombre, 'Radio Salkantay 101.5 FM');

      await provider.playStationById('rb_no-existe');
      expect(provider.errorMessage, contains('ya no está disponible'));
    });
  });

  test('recuerda el tema elegido', () async {
    final provider = await createProvider(load: false);
    expect(provider.themeMode, ThemeMode.system);
    await provider.setThemeMode(ThemeMode.dark);
    expect(storage.getThemeMode(), ThemeMode.dark);
  });
}

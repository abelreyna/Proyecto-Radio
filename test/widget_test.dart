import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radios_peru_mix/main.dart';
import 'package:radios_peru_mix/providers/radio_provider.dart';
import 'package:radios_peru_mix/services/radio_api_service.dart';
import 'package:radios_peru_mix/services/share_service.dart';
import 'package:radios_peru_mix/services/storage_service.dart';
import 'package:radios_peru_mix/ui/widgets/station_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeRadioPlayer player;
  late RadioProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    player = FakeRadioPlayer();
    provider = RadioProvider(
      api: RadioApiService(storage: storage, client: fakeHttpClient()),
      storage: storage,
      player: player,
    );
  });

  Future<void> pumpApp(WidgetTester tester) async {
    // Pantalla de teléfono alta para que toda la lista quede visible.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);

    await tester.runAsync(provider.loadStations);
    await tester.pumpWidget(
      RadiosPeruMixApp(provider: provider, shareService: ShareService()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el catálogo con destacadas y filtros', (tester) async {
    await pumpApp(tester);

    expect(find.text('Radios Perú Mix'), findsOneWidget);
    expect(find.text('Destacadas'), findsOneWidget);
    expect(find.text('Todo el Perú'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Arequipa'), findsOneWidget);
    expect(find.byType(StationCard), findsNWidgets(4));
  });

  testWidgets('el buscador filtra la lista', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(SearchBar), 'moda');
    await tester.pumpAndSettle();

    expect(find.byType(StationCard), findsOneWidget);
    expect(find.text('1 emisora'), findsOneWidget);
    expect(find.text('Destacadas'), findsNothing);
  });

  testWidgets('tocar una emisora la reproduce en el mini reproductor',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(StationCard, 'Radio Moda'));
    await tester.pumpAndSettle();

    expect(player.played.single.id, 'pe_moda_lima');
    expect(find.byTooltip('Detener'), findsOneWidget);

    await tester.tap(find.byTooltip('Detener'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Detener'), findsNothing);
  });

  testWidgets('el reproductor muestra la canción y programa el temporizador',
      (tester) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(StationCard, 'RPP Noticias'));
    await tester.pumpAndSettle();
    player.emitNowPlaying('Programa de la mañana');
    await tester.pumpAndSettle();

    // Abre el reproductor a pantalla completa desde el mini reproductor.
    await tester.tap(find.text('Programa de la mañana'));
    await tester.pumpAndSettle();
    expect(find.text('Escuchando ahora'), findsOneWidget);
    expect(find.text('EN VIVO'), findsOneWidget);

    await tester.tap(find.text('Temporizador de apagado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 minutos'));
    await tester.pumpAndSettle();
    expect(find.text('Se apagará en 30:00'), findsOneWidget);

    // Al detener, el reproductor se cierra y vuelve al inicio.
    await tester.tap(find.byTooltip('Detener'));
    await tester.pumpAndSettle();
    expect(find.text('Escuchando ahora'), findsNothing);
    expect(find.text('Destacadas'), findsOneWidget);
  });

  testWidgets('los favoritos aparecen en su pestaña', (tester) async {
    await pumpApp(tester);

    expect(find.text('Aún no tienes favoritas'), findsNothing);
    await tester.tap(find.descendant(
      of: find.widgetWithText(StationCard, 'Radio Yaraví'),
      matching: find.byTooltip('Agregar a favoritos'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favoritos'));
    await tester.pumpAndSettle();

    expect(find.byType(StationCard), findsOneWidget);
    expect(find.widgetWithText(StationCard, 'Radio Yaraví'), findsOneWidget);
  });
}

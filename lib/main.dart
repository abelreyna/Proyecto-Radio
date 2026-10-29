import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'providers/radio_provider.dart';
import 'services/audio_handler.dart';
import 'services/deep_link_service.dart';
import 'services/radio_api_service.dart';
import 'services/share_service.dart';
import 'services/storage_service.dart';
import 'ui/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await StorageService.create();
  // Servicio de audio en segundo plano (notificación y pantalla de bloqueo).
  final audioHandler = await RadioAudioHandler.init();

  if (AppConstants.enableAds) {
    unawaited(MobileAds.instance.initialize());
  }

  final provider = RadioProvider(
    api: RadioApiService(storage: storage),
    storage: storage,
    player: audioHandler,
  );

  // Se escucha desde el arranque para no perder el enlace con el que se abrió
  // la app (por ejemplo, una emisora compartida por WhatsApp).
  DeepLinkService().listen(provider.handleDeepLink);
  unawaited(provider.loadStations());

  runApp(RadiosPeruMixApp(provider: provider, shareService: ShareService()));
}

class RadiosPeruMixApp extends StatelessWidget {
  const RadiosPeruMixApp({
    super.key,
    required this.provider,
    required this.shareService,
  });

  final RadioProvider provider;
  final ShareService shareService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<RadioProvider>.value(value: provider),
        Provider<ShareService>.value(value: shareService),
      ],
      child: Selector<RadioProvider, ThemeMode>(
        selector: (_, provider) => provider.themeMode,
        builder: (context, themeMode, _) => MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          locale: const Locale('es', 'PE'),
          supportedLocales: const [Locale('es', 'PE'), Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const HomeScreen(),
        ),
      ),
    );
  }
}

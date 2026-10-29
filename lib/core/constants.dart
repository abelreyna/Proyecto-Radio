/// Configuración global de Radios Perú Mix.
///
/// Todo lo que pueda cambiar entre versiones (URLs, servidores, banderas de
/// monetización) se centraliza aquí para no tener que buscarlo en el código.
abstract final class AppConstants {
  static const String appName = 'Radios Perú Mix';

  // ---------------------------------------------------------------------------
  // Catálogo curado (JSON en GitHub)
  // ---------------------------------------------------------------------------

  /// Enlace *Raw* del catálogo curado. El repositorio debe ser **público** para
  /// que la app pueda descargarlo; si no responde se usa la última copia
  /// descargada y, en último caso, la versión empaquetada en [curatedAssetPath].
  static const String curatedJsonUrl =
      'https://raw.githubusercontent.com/abelreyna/Proyecto-Radio/main/assets/data/radios_peru.json';

  /// Copia del catálogo incluida en la app (funciona sin conexión).
  static const String curatedAssetPath = 'assets/data/radios_peru.json';

  // ---------------------------------------------------------------------------
  // Radio Browser API
  // ---------------------------------------------------------------------------

  /// Servidores espejo de Radio Browser; se prueban en orden hasta que uno
  /// responda.
  static const List<String> radioBrowserHosts = [
    'de1.api.radio-browser.info',
    'fi1.api.radio-browser.info',
    'de2.api.radio-browser.info',
  ];
  static const String radioBrowserCountryCode = 'PE';
  static const int radioBrowserLimit = 500;

  /// Radio Browser pide identificar la app en cada petición.
  static const String userAgent = 'RadiosPeruMix/1.0';
  static const Duration networkTimeout = Duration(seconds: 12);

  // ---------------------------------------------------------------------------
  // Compartir y enlaces profundos
  // ---------------------------------------------------------------------------

  static const String androidPackageId = 'com.radiosperumix.app';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidPackageId';

  /// Enlace de App Store. Se deja vacío hasta publicar la app en iOS; mientras
  /// esté vacío no se incluye en los mensajes de compartir.
  static const String appStoreUrl = '';

  /// Esquema propio: `radiosperumix://station/<id>` abre la app y reproduce la
  /// emisora indicada.
  static const String deepLinkScheme = 'radiosperumix';
  static const String deepLinkStationHost = 'station';

  // ---------------------------------------------------------------------------
  // Monetización (AdMob)
  // ---------------------------------------------------------------------------

  /// Interruptor de anuncios. La v1.0 sale sin publicidad y sin el SDK de
  /// AdMob; el README explica cómo agregarlo y activar los banners.
  static const bool enableAds = false;

  // ---------------------------------------------------------------------------
  // Reproductor
  // ---------------------------------------------------------------------------

  /// Opciones del temporizador de apagado, en minutos.
  static const List<int> sleepTimerMinutes = [15, 30, 45, 60];

  /// Tras una pausa larga se reconecta el stream para volver al directo en
  /// lugar de continuar con audio atrasado del búfer.
  static const Duration liveResyncAfterPause = Duration(seconds: 30);

  /// Orden en que se muestran los géneros en los filtros.
  static const List<String> genreOrder = [
    'Noticias',
    'Deportes',
    'Cumbia',
    'Salsa',
    'Rock & Pop',
    'Folklore',
    'Baladas',
    'Urbano',
    'Variado',
  ];
}

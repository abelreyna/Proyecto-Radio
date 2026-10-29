import 'dart:ui';

import 'package:share_plus/share_plus.dart';

import '../core/constants.dart';
import '../models/station_model.dart';
import 'deep_link_service.dart';

/// Genera los textos para compartir y abre el diálogo nativo (WhatsApp,
/// redes sociales, etc.).
class ShareService {
  /// Enlaces de descarga disponibles (App Store solo cuando esté publicada).
  static String get _downloadLinks {
    final links = ['Android: ${AppConstants.playStoreUrl}'];
    if (AppConstants.appStoreUrl.isNotEmpty) {
      links.add('iPhone: ${AppConstants.appStoreUrl}');
    }
    return links.join('\n');
  }

  static String stationMessage(Station station) {
    final details = station.frecuencia.isEmpty
        ? station.nombre
        : '${station.nombre} (${station.frecuencia})';
    return 'Estoy escuchando $details en ${AppConstants.appName} 📻\n'
        'Ábrela en la app: ${DeepLinkService.stationUri(station)}\n\n'
        '¿Aún no tienes la app? Descárgala gratis:\n$_downloadLinks';
  }

  static String appMessage() =>
      'Escucha las radios del Perú en vivo con ${AppConstants.appName} 📻🇵🇪\n'
      'Noticias, cumbia, salsa, rock & pop, folklore y emisoras de todas las '
      'regiones.\n\n$_downloadLinks';

  /// [origin] es la posición del botón que abrió el diálogo; iPad la necesita
  /// para ubicar la ventana emergente.
  Future<void> shareStation(Station station, {Rect? origin}) =>
      SharePlus.instance.share(ShareParams(
        text: stationMessage(station),
        subject: station.nombre,
        sharePositionOrigin: origin,
      ));

  Future<void> shareApp({Rect? origin}) =>
      SharePlus.instance.share(ShareParams(
        text: appMessage(),
        subject: AppConstants.appName,
        sharePositionOrigin: origin,
      ));
}

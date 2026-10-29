import 'dart:async';

import 'package:app_links/app_links.dart';

import '../core/constants.dart';
import '../models/station_model.dart';

/// Construye y procesa los enlaces profundos de la app.
///
/// Formato principal: `radiosperumix://station/<id>`. También se aceptan
/// enlaces web con `/station/<id>` o `?station=<id>` por si más adelante se
/// configura un dominio propio (App Links / Universal Links).
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  /// Escucha el enlace con el que se abrió la app y los que lleguen después.
  StreamSubscription<Uri> listen(void Function(Uri uri) onLink) =>
      _appLinks.uriLinkStream.listen(onLink);

  /// Enlace que abre la app reproduciendo [station].
  static Uri stationUri(Station station) => Uri(
        scheme: AppConstants.deepLinkScheme,
        host: AppConstants.deepLinkStationHost,
        path: '/${station.id}',
      );

  /// Extrae el ID de emisora de un enlace entrante, o `null` si el enlace no
  /// apunta a una emisora.
  static String? stationIdFrom(Uri uri) {
    if (uri.scheme == AppConstants.deepLinkScheme &&
        uri.host == AppConstants.deepLinkStationHost) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isNotEmpty) return segments.first;
    }

    final segments = uri.pathSegments;
    final index = segments.indexOf(AppConstants.deepLinkStationHost);
    if (index >= 0 && index + 1 < segments.length) {
      final id = segments[index + 1];
      if (id.isNotEmpty) return id;
    }

    final query = uri.queryParameters['station'];
    return (query == null || query.isEmpty) ? null : query;
  }
}

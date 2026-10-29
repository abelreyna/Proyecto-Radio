import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/station_model.dart';

/// Logo de la emisora guardado en caché. Si no tiene logo o falla la
/// descarga, muestra las iniciales sobre un color derivado del nombre.
class StationLogo extends StatelessWidget {
  const StationLogo({
    super.key,
    required this.station,
    this.size = 56,
    this.borderRadius = 12,
  });

  final Station station;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final fallback = _InitialsLogo(station: station, size: size);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox.square(
        dimension: size,
        child: station.urlLogo.isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: station.urlLogo,
                fit: BoxFit.cover,
                // Descarga el logo al tamaño en que se muestra para ahorrar
                // memoria y datos móviles.
                memCacheWidth: (size * pixelRatio).round(),
                fadeInDuration: const Duration(milliseconds: 200),
                placeholder: (context, url) => fallback,
                errorWidget: (context, url, error) => fallback,
              ),
      ),
    );
  }
}

class _InitialsLogo extends StatelessWidget {
  const _InitialsLogo({required this.station, required this.size});

  final Station station;
  final double size;

  static const List<Color> _palette = [
    Color(0xFFD91023),
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFEF6C00),
    Color(0xFF00838F),
    Color(0xFFAD1457),
    Color(0xFF4E342E),
  ];

  String get _initials {
    final words = station.nombre
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && word.toLowerCase() != 'radio')
        .toList();
    if (words.isEmpty) return '📻';
    if (words.length == 1) {
      final word = words.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _palette[station.nombre.hashCode.abs() % _palette.length];
    return ColoredBox(
      color: color,
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.34,
          ),
        ),
      ),
    );
  }
}

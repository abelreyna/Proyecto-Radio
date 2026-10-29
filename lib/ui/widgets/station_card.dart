import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/station_model.dart';
import '../../providers/radio_provider.dart';
import '../../services/audio_handler.dart';
import 'station_logo.dart';

/// Tarjeta individual de cada emisora en la lista.
class StationCard extends StatelessWidget {
  const StationCard({super.key, required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Solo se reconstruye la tarjeta cuando cambia algo que le afecta.
    final provider = context.read<RadioProvider>();
    final isFavorite =
        context.select<RadioProvider, bool>((p) => p.isFavorite(station));
    final status = context.select<RadioProvider, PlaybackStatus?>(
        (p) => p.isCurrent(station) ? p.status : null);
    final isCurrent = status != null;

    return Card(
      elevation: 0,
      color: isCurrent
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => isCurrent
            ? provider.togglePlayPause()
            : provider.play(station),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              StationLogo(station: station, size: 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCurrent ? scheme.onPrimaryContainer : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [station.subtitle, station.genero]
                          .where((part) => part.isNotEmpty)
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isCurrent
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent) _NowPlayingIndicator(status: status),
              IconButton(
                tooltip: isFavorite ? 'Quitar de favoritos' : 'Agregar a favoritos',
                onPressed: () => provider.toggleFavorite(station),
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? scheme.primary : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NowPlayingIndicator extends StatelessWidget {
  const _NowPlayingIndicator({required this.status});

  final PlaybackStatus status;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimaryContainer;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: switch (status) {
        PlaybackStatus.loading => SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
        PlaybackStatus.playing => Icon(Icons.graphic_eq, color: color),
        PlaybackStatus.error => Icon(Icons.error_outline, color: color),
        PlaybackStatus.paused || PlaybackStatus.idle =>
          Icon(Icons.pause, color: color),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/radio_provider.dart';
import '../../services/audio_handler.dart';
import '../screens/player_screen.dart';
import 'station_logo.dart';

/// Barra inferior persistente con controles rápidos de la emisora actual.
/// Al tocarla se abre el reproductor a pantalla completa.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RadioProvider>();
    final station = provider.currentStation;
    if (station == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = provider.status;
    final hasError = status == PlaybackStatus.error;
    final subtitle = hasError
        ? 'No se pudo conectar · toca para reintentar'
        : provider.nowPlaying ??
            (station.subtitle.isEmpty ? 'En vivo' : station.subtitle);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 2,
          child: status == PlaybackStatus.loading
              ? const LinearProgressIndicator(minHeight: 2)
              : null,
        ),
        InkWell(
          onTap: () => PlayerScreen.open(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              children: [
                Hero(
                  tag: 'logo-${station.id}',
                  child: StationLogo(station: station, size: 44, borderRadius: 10),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        station.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: hasError ? scheme.error : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PlayPauseButton(status: status, onPressed: provider.togglePlayPause),
                IconButton(
                  tooltip: 'Detener',
                  onPressed: provider.stop,
                  icon: const Icon(Icons.stop_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Botón de Play/Pausa que muestra un indicador mientras conecta.
class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({
    super.key,
    required this.status,
    required this.onPressed,
    this.size = 24,
    this.filled = false,
  });

  final PlaybackStatus status;
  final VoidCallback onPressed;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, String tooltip) = switch (status) {
      PlaybackStatus.playing => (Icons.pause_rounded, 'Pausar'),
      PlaybackStatus.loading => (Icons.pause_rounded, 'Pausar'),
      PlaybackStatus.error => (Icons.refresh_rounded, 'Reintentar'),
      PlaybackStatus.paused || PlaybackStatus.idle =>
        (Icons.play_arrow_rounded, 'Reproducir'),
    };

    final Widget child = status == PlaybackStatus.loading
        ? SizedBox.square(
            dimension: size * 0.8,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: filled ? Theme.of(context).colorScheme.onPrimary : null,
            ),
          )
        : Icon(icon, size: size);

    return filled
        ? IconButton.filled(
            tooltip: tooltip,
            onPressed: onPressed,
            iconSize: size,
            padding: EdgeInsets.all(size * 0.4),
            icon: child,
          )
        : IconButton(tooltip: tooltip, onPressed: onPressed, icon: child);
  }
}

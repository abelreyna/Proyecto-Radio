import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/station_model.dart';
import '../../providers/radio_provider.dart';
import '../../services/audio_handler.dart';
import '../../services/share_service.dart';
import '../widgets/mini_player.dart';
import '../widgets/share_origin.dart';
import '../widgets/station_logo.dart';

/// Reproductor a pantalla completa con carátula, metadatos en vivo,
/// temporizador de apagado y opción de compartir.
class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const PlayerScreen()),
      );

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RadioProvider>();
    final station = provider.currentStation;

    // Si se detiene la radio desde la notificación, se vuelve al inicio.
    if (station == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) navigator.pop();
      });
      return const Scaffold();
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Cerrar',
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Escuchando ahora'),
        centerTitle: true,
        actions: [
          Builder(
            builder: (buttonContext) => IconButton(
              tooltip: 'Compartir emisora',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => context.read<ShareService>().shareStation(
                    station,
                    origin: shareOriginOf(buttonContext),
                  ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final artSize = (constraints.maxWidth - 64)
                .clamp(160.0, 340.0)
                .toDouble();
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Hero(
                      tag: 'logo-${station.id}',
                      child: Material(
                        elevation: 8,
                        borderRadius: BorderRadius.circular(28),
                        clipBehavior: Clip.antiAlias,
                        child: StationLogo(
                          station: station,
                          size: artSize,
                          borderRadius: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _StationInfo(station: station),
                    const SizedBox(height: 16),
                    _LiveMetadata(
                      status: provider.status,
                      nowPlaying: provider.nowPlaying,
                      errorMessage: provider.errorMessage,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          tooltip: provider.isFavorite(station)
                              ? 'Quitar de favoritos'
                              : 'Agregar a favoritos',
                          iconSize: 28,
                          onPressed: () => provider.toggleFavorite(station),
                          icon: Icon(
                            provider.isFavorite(station)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: provider.isFavorite(station) ? scheme.primary : null,
                          ),
                        ),
                        PlayPauseButton(
                          status: provider.status,
                          onPressed: provider.togglePlayPause,
                          size: 44,
                          filled: true,
                        ),
                        IconButton(
                          tooltip: 'Detener',
                          iconSize: 32,
                          onPressed: provider.stop,
                          icon: const Icon(Icons.stop_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SleepTimerButton(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StationInfo extends StatelessWidget {
  const _StationInfo({required this.station});

  final Station station;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [station.frecuencia, station.region, station.genero]
        .where((part) => part.isNotEmpty)
        .join(' · ');
    return Column(
      children: [
        Text(
          station.nombre,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (details.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            details,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

/// Muestra la canción en curso (ICY), el estado de conexión o el error.
class _LiveMetadata extends StatelessWidget {
  const _LiveMetadata({
    required this.status,
    required this.nowPlaying,
    required this.errorMessage,
  });

  final PlaybackStatus status;
  final String? nowPlaying;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (status == PlaybackStatus.error) {
      return Text(
        errorMessage ?? 'No se pudo reproducir la emisora.',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
      );
    }

    final label = switch (status) {
      PlaybackStatus.loading => 'Conectando…',
      PlaybackStatus.paused => 'En pausa',
      _ => 'EN VIVO',
    };

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: status == PlaybackStatus.playing
                ? scheme.primary
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: status == PlaybackStatus.playing
                  ? scheme.onPrimary
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
        if (nowPlaying != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_note_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  nowPlaying!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Botón del temporizador de apagado con la cuenta regresiva.
class _SleepTimerButton extends StatelessWidget {
  const _SleepTimerButton();

  static String _format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<RadioProvider>();
    return ValueListenableBuilder<Duration?>(
      valueListenable: provider.sleepRemaining,
      builder: (context, remaining, _) {
        final active = remaining != null;
        return FilledButton.tonalIcon(
          onPressed: () => _showSleepTimerSheet(context, active),
          icon: Icon(active ? Icons.bedtime : Icons.bedtime_outlined),
          label: Text(
            active
                ? 'Se apagará en ${_format(remaining)}'
                : 'Temporizador de apagado',
          ),
        );
      },
    );
  }

  Future<void> _showSleepTimerSheet(BuildContext context, bool active) async {
    final provider = context.read<RadioProvider>();
    // Duration.zero representa "cancelar el temporizador".
    final selected = await showModalBottomSheet<Duration>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                'Apagar la radio en…',
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            for (final minutes in AppConstants.sleepTimerMinutes)
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text('$minutes minutos'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(Duration(minutes: minutes)),
              ),
            if (active)
              ListTile(
                leading: const Icon(Icons.timer_off_outlined),
                title: const Text('Cancelar temporizador'),
                onTap: () => Navigator.of(sheetContext).pop(Duration.zero),
              ),
          ],
        ),
      ),
    );
    if (selected == null) return;
    provider.setSleepTimer(selected == Duration.zero ? null : selected);
  }
}

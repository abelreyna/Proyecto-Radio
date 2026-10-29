import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../core/constants.dart';
import '../models/station_model.dart';

/// Estado simplificado del reproductor que consume la interfaz.
enum PlaybackStatus { idle, loading, playing, paused, error }

/// Contrato del reproductor de radio. La app usa [RadioAudioHandler]; las
/// pruebas pueden usar una implementación falsa sin plugins nativos.
abstract interface class RadioPlayer {
  Stream<PlaybackStatus> get statusStream;

  /// Título de la canción o programa en curso (metadatos ICY), si la emisora
  /// lo transmite.
  Stream<String?> get nowPlayingStream;

  /// Mensajes de error de conexión con el stream.
  Stream<String> get errorStream;

  /// Tiempo restante del temporizador de apagado, o `null` si está inactivo.
  ValueListenable<Duration?> get sleepRemaining;

  Future<void> playStation(Station station);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  void setSleepTimer(Duration duration);
  void cancelSleepTimer();
}

/// Controlador de audio basado en `just_audio` y `audio_service`.
///
/// `audio_service` mantiene la reproducción activa con la pantalla apagada y
/// publica la notificación nativa (Android) y los controles de la pantalla de
/// bloqueo (iOS) con Play/Pausa/Detener.
class RadioAudioHandler extends BaseAudioHandler implements RadioPlayer {
  RadioAudioHandler({AudioPlayer? player}) : _player = player ?? AudioPlayer() {
    _player.playbackEventStream.listen(
      (_) => _broadcastState(),
      onError: _onPlaybackError,
    );
    _player.playingStream.listen((_) => _broadcastState());
    _player.icyMetadataStream.listen(_onIcyMetadata);
  }

  /// Arranca el servicio de audio en segundo plano. Debe llamarse una sola vez
  /// antes de `runApp`.
  static Future<RadioAudioHandler> init() {
    return AudioService.init(
      builder: RadioAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.radiosperumix.app.audio',
        androidNotificationChannelName: 'Reproducción de radio',
        androidNotificationChannelDescription:
            'Controles de la emisora que se está escuchando',
        // Se usan los valores por defecto de androidStopForegroundOnPause (true)
        // y androidNotificationOngoing (false): al pausar o detener, el servicio
        // sale de primer plano y la notificación se puede descartar deslizándola.
        // Con otros valores quedaba fija tras pulsar Detener.
      ),
    );
  }

  final AudioPlayer _player;
  final StreamController<String> _errors = StreamController.broadcast();
  final StreamController<String?> _nowPlaying = StreamController.broadcast();
  final ValueNotifier<Duration?> _sleepRemaining = ValueNotifier(null);

  Station? _station;
  DateTime? _pausedAt;
  Timer? _sleepTicker;

  @override
  Stream<PlaybackStatus> get statusStream =>
      _player.playerStateStream.map(_toStatus).distinct();

  @override
  Stream<String?> get nowPlayingStream => _nowPlaying.stream;

  @override
  Stream<String> get errorStream => _errors.stream;

  @override
  ValueListenable<Duration?> get sleepRemaining => _sleepRemaining;

  // ---------------------------------------------------------------------------
  // Reproducción
  // ---------------------------------------------------------------------------

  @override
  Future<void> playStation(Station station) async {
    _station = station;
    _pausedAt = null;
    _nowPlaying.add(null);

    final item = MediaItem(
      id: station.id,
      title: station.nombre,
      artist: station.subtitle.isEmpty ? AppConstants.appName : station.subtitle,
      album: AppConstants.appName,
      genre: station.genero,
      artUri: station.urlLogo.isEmpty ? null : Uri.tryParse(station.urlLogo),
      isLive: true,
    );
    mediaItem.add(item);

    try {
      await _player.setAudioSource(
        AudioSource.uri(Uri.parse(station.urlStream), tag: item),
      );
      // play() termina cuando se detiene la reproducción, por eso no se espera.
      unawaited(_player.play());
    } on PlayerInterruptedException {
      // Se pidió otra emisora antes de que esta terminara de cargar.
    } catch (error) {
      _onPlaybackError(error);
    }
  }

  /// En radio en vivo, tras una pausa larga se reconecta para volver al
  /// directo en lugar de continuar con audio atrasado del búfer.
  @override
  Future<void> resume() async {
    final station = _station;
    if (station == null) return;
    final pausedAt = _pausedAt;
    final needsResync = _player.processingState == ProcessingState.idle ||
        (pausedAt != null &&
            DateTime.now().difference(pausedAt) >
                AppConstants.liveResyncAfterPause);
    if (needsResync) {
      await playStation(station);
    } else {
      _pausedAt = null;
      unawaited(_player.play());
    }
  }

  @override
  Future<void> play() => resume();

  @override
  Future<void> pause() async {
    _pausedAt = DateTime.now();
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    cancelSleepTimer();
    _pausedAt = null;
    await _player.stop();
    _nowPlaying.add(null);
    // Con el estado en "idle" el sistema retira la notificación.
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.idle,
      playing: false,
    ));
  }

  /// El usuario cerró la app desde recientes (Android): se detiene el audio.
  @override
  Future<void> onTaskRemoved() => stop();

  // ---------------------------------------------------------------------------
  // Temporizador de apagado
  // ---------------------------------------------------------------------------

  @override
  void setSleepTimer(Duration duration) {
    cancelSleepTimer();
    final endsAt = DateTime.now().add(duration);
    _sleepRemaining.value = duration;
    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = endsAt.difference(DateTime.now());
      if (left <= Duration.zero) {
        stop();
      } else {
        _sleepRemaining.value = left;
      }
    });
  }

  @override
  void cancelSleepTimer() {
    _sleepTicker?.cancel();
    _sleepTicker = null;
    _sleepRemaining.value = null;
  }

  // ---------------------------------------------------------------------------
  // Estado, errores y metadatos
  // ---------------------------------------------------------------------------

  static PlaybackStatus _toStatus(PlayerState state) {
    switch (state.processingState) {
      case ProcessingState.idle:
      case ProcessingState.completed:
        return PlaybackStatus.idle;
      case ProcessingState.loading:
      case ProcessingState.buffering:
        return state.playing ? PlaybackStatus.loading : PlaybackStatus.paused;
      case ProcessingState.ready:
        return state.playing ? PlaybackStatus.playing : PlaybackStatus.paused;
    }
  }

  /// Publica el estado para la notificación y la pantalla de bloqueo.
  void _broadcastState() {
    final playing = _player.playing;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.play,
        MediaAction.pause,
        MediaAction.playPause,
        MediaAction.stop,
      },
      androidCompactActionIndices: const [0, 1],
      processingState: switch (_player.processingState) {
        ProcessingState.idle => AudioProcessingState.idle,
        ProcessingState.loading => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      },
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
    ));
  }

  void _onPlaybackError(Object error, [StackTrace? stackTrace]) {
    final name = _station?.nombre ?? 'la emisora';
    _errors.add('No se pudo conectar con $name. '
        'Revisa tu conexión o intenta con otra emisora.');
    playbackState.add(playbackState.value.copyWith(
      processingState: AudioProcessingState.error,
      playing: false,
    ));
  }

  void _onIcyMetadata(IcyMetadata? metadata) {
    final title = cleanIcyTitle(metadata?.info?.title, _station?.nombre);
    _nowPlaying.add(title);
    final current = mediaItem.value;
    if (current != null) {
      // Muestra la canción en la notificación en lugar de la frecuencia.
      mediaItem.add(current.copyWith(
        artist: title ?? _station?.subtitle ?? AppConstants.appName,
      ));
    }
  }

  /// Limpia el título ICY: descarta valores vacíos, genéricos, iguales al
  /// nombre de la emisora o códigos internos sin espacios (algunas emisoras
  /// envían, por ejemplo, "GRPP-OXIGENO" en lugar de la canción).
  @visibleForTesting
  static String? cleanIcyTitle(String? raw, String? stationName) {
    final title = raw?.trim() ?? '';
    if (title.isEmpty || title == '-' || title.length < 3) return null;
    if (!title.contains(' ')) return null;
    final lower = title.toLowerCase();
    if (stationName != null && lower == stationName.trim().toLowerCase()) {
      return null;
    }
    const generic = {'unknown', 'live', 'en vivo', 'advertisement', 'ads'};
    if (generic.contains(lower)) return null;
    return title;
  }
}

import 'package:flutter/foundation.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerHandler extends BaseAudioHandler {
  final _player = AudioPlayer();

  AudioPlayerHandler() {
    _notifyAudioHandlerAboutPlaybackEvents();
    _listenToPlaybackState();
    _listenToCurrentPosition();
    _listenToDuration();
    _listenToCurrentItem();
  }

  AudioPlayer get player => _player;

  void _notifyAudioHandlerAboutPlaybackEvents() {
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
           
          ],
          systemActions: const {MediaAction.seek},
          androidCompactActionIndices: const [0, 1, 3],
          processingState: const {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: event.currentIndex,
        ),
      );
    });
  }

  void _listenToPlaybackState() {
    _player.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = playerState.processingState;
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        playbackState.add(
          playbackState.value.copyWith(
            processingState: AudioProcessingState.buffering,
          ),
        );
      } else if (!playing) {
        playbackState.add(
          playbackState.value.copyWith(
            playing: false,
            processingState: AudioProcessingState.ready,
          ),
        );
      } else if (processingState == ProcessingState.completed) {
        playbackState.add(
          playbackState.value.copyWith(
            playing: false,
            processingState: AudioProcessingState.completed,
          ),
        );
      } else {
        playbackState.add(
          playbackState.value.copyWith(
            playing: true,
            processingState: AudioProcessingState.ready,
          ),
        );
      }
    });
  }

  void _listenToCurrentPosition() {
    _player.positionStream.listen((position) {
      final oldState = playbackState.value;
      playbackState.add(oldState.copyWith(updatePosition: position));
    });
  }

  void _listenToDuration() {
    _player.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current != null && duration != null) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });
  }

  void _listenToCurrentItem() {
    _player.sequenceStateStream.listen((sequenceState) {
      final sequence = sequenceState?.sequence;
      final index = sequenceState?.currentIndex;
      if (sequence == null || index == null || index >= sequence.length) return;
      final source = sequence[index];
      final metadata = source.tag as MediaItem?;
      if (metadata != null) {
        mediaItem.add(metadata);
      }
    });
  }

  VoidCallback? onNext;
  VoidCallback? onPrevious;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  Future<void> skipToNext() async => onNext?.call();

  @override
  Future<void> skipToPrevious() async => onPrevious?.call();
}

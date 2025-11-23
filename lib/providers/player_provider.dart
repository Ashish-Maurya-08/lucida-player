import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:lucida_player/models/music_item.dart';
import 'package:lucida_player/utils/utils.dart';

enum RepeatMode { off, all, one }

class PlayerState {
  final Track? currentTrack;
  final List<Track> queue;
  final int currentIndex;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final RepeatMode repeatMode;

  const PlayerState({
    this.currentTrack,
    this.queue = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.repeatMode = RepeatMode.off,
  });

  PlayerState copyWith({
    Track? currentTrack,
    List<Track>? queue,
    int? currentIndex,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    RepeatMode? repeatMode,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}

class PlayerController extends StateNotifier<PlayerState> {
  final AudioPlayer _player;
  final _api = APIClient();

  PlayerController(this._player) : super(const PlayerState()) {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      final isBuffering =
          processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering;

      if (processingState == ProcessingState.completed) {
        _onTrackFinished();
      }

      state = state.copyWith(isPlaying: isPlaying, isBuffering: isBuffering);
    });

    _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _player.durationStream.listen((duration) {
      state = state.copyWith(duration: duration ?? Duration.zero);
    });
  }

  void _onTrackFinished() {
    if (state.repeatMode == RepeatMode.one) {
      _player.seek(Duration.zero);
      _player.play();
    } else {
      next();
    }
  }

  Future<void> play(List<Track> tracks, int initialIndex) async {
    state = state.copyWith(queue: tracks, currentIndex: initialIndex);
    await _playTrackAt(initialIndex);
  }

  Future<void> _playTrackAt(int index) async {
    if (index < 0 || index >= state.queue.length) return;

    final track = state.queue[index];
    state = state.copyWith(currentTrack: track, currentIndex: index);

    try {
      final streamUrl = await _api.getStreamUrl(track.url);
      if (streamUrl != null) {
        await _player.setUrl(streamUrl);
        await _player.play();
      } else {
        log('Failed to get stream URL for track: ${track.title}');
      }
    } catch (e) {
      log('Error playing track: $e');
    }
  }

  Future<void> next() async {
    if (state.queue.isEmpty) return;

    int nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.queue.length) {
      if (state.repeatMode == RepeatMode.all) {
        nextIndex = 0;
      } else {
        return; // End of queue
      }
    }
    await _playTrackAt(nextIndex);
  }

  Future<void> previous() async {
    if (state.queue.isEmpty) return;

    if (state.position.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }

    int prevIndex = state.currentIndex - 1;
    if (prevIndex < 0) {
      if (state.repeatMode == RepeatMode.all) {
        prevIndex = state.queue.length - 1;
      } else {
        prevIndex = 0;
      }
    }
    await _playTrackAt(prevIndex);
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void toggleRepeat() {
    final nextMode = RepeatMode
        .values[(state.repeatMode.index + 1) % RepeatMode.values.length];
    state = state.copyWith(repeatMode: nextMode);
  }

  Future<void> addToQueue(Track track) async {
    final newQueue = List<Track>.from(state.queue)..add(track);
    state = state.copyWith(queue: newQueue);
  }

  Future<void> removeFromQueue(int index) async {
    if (index < 0 || index >= state.queue.length) return;

    final newQueue = List<Track>.from(state.queue);
    newQueue.removeAt(index);

    int newIndex = state.currentIndex;
    if (index < state.currentIndex) {
      newIndex--;
    } else if (index == state.currentIndex) {
      // If removing the current track, we need to decide what to do.
      // For now, let's just keep playing it but update the index if possible,
      // or stop if the queue becomes empty.
      if (newQueue.isEmpty) {
        await _player.stop();
        state = state.copyWith(
          queue: [],
          currentTrack: null,
          currentIndex: -1,
          isPlaying: false,
        );
        return;
      }
      // If we removed the last item and it was playing, newIndex needs adjustment
      if (newIndex >= newQueue.length) {
        newIndex =
            0; // Loop back or stop? Let's go to 0 for now or handle differently.
        // Actually, if we remove the playing track, maybe we should play the next one?
        // Let's keep it simple: if removing current, play the next one (which is now at the same index)
        // unless we were at the end.
        if (newIndex >= newQueue.length) {
          newIndex = newQueue.length - 1;
        }
        // We might want to auto-play the new track at this index?
        // For smoother UX, maybe just let the audio continue until it finishes?
        // But the track is gone from queue.
        // Let's just update index and queue for now.
      }
    }

    state = state.copyWith(queue: newQueue, currentIndex: newIndex);
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final newQueue = List<Track>.from(state.queue);
    final item = newQueue.removeAt(oldIndex);
    newQueue.insert(newIndex, item);

    int currentIndex = state.currentIndex;
    final currentTrack = state.queue[currentIndex];

    // Find the new index of the current track
    // This is a bit safer than calculating offsets manually
    int newCurrentIndex = newQueue.indexOf(currentTrack);

    state = state.copyWith(queue: newQueue, currentIndex: newCurrentIndex);
  }

  Future<void> addAlbumToQueue(Album album) async {
    final tracks = await _api.getAlbumTracks(album.url);
    if (tracks != null) {
      final newQueue = List<Track>.from(state.queue)..addAll(tracks);
      state = state.copyWith(queue: newQueue);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  return AudioPlayer();
});

final playerProvider = StateNotifierProvider<PlayerController, PlayerState>((
  ref,
) {
  final player = ref.watch(audioPlayerProvider);
  return PlayerController(player);
});

import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:lucida_player/models/music_item.dart';
import 'package:lucida_player/utils/utils.dart';

class PlayerState {
  final Track? currentTrack;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;

  const PlayerState({
    this.currentTrack,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  PlayerState copyWith({
    Track? currentTrack,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
  }) {
    return PlayerState(
      currentTrack: currentTrack ?? this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      position: position ?? this.position,
      duration: duration ?? this.duration,
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

      state = state.copyWith(isPlaying: isPlaying, isBuffering: isBuffering);
    });

    _player.positionStream.listen((position) {
      state = state.copyWith(position: position);
    });

    _player.durationStream.listen((duration) {
      state = state.copyWith(duration: duration ?? Duration.zero);
    });
  }

  Future<void> play(Track track) async {
    try {
      state = state.copyWith(currentTrack: track);
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

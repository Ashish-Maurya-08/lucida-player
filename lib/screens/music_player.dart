import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucida_player/providers/player_provider.dart';
import 'package:lucida_player/screens/full_player_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(playerProvider.select((s) => s.currentTrack));

    if (track == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          useSafeArea: true,
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          builder: (context) => const FullPlayerScreen(),
        );
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          border: const Border(
            top: BorderSide(color: Colors.white24, width: 1),
          ),
        ),
        child: Column(
          children: [
            const _MiniPlayerProgress(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Image.network(
                        track.coverArtworks.isNotEmpty
                            ? track.coverArtworks.first
                            : '',
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.music_note,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track.artists.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const _MiniPlayerPlayButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPlayerProgress extends ConsumerWidget {
  const _MiniPlayerProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      playerProvider.select((s) {
        if (s.duration.inMilliseconds > 0) {
          return s.position.inMilliseconds / s.duration.inMilliseconds;
        }
        return 0.0;
      }),
    );

    return LinearProgressIndicator(
      value: progress.clamp(0.0, 1.0),
      backgroundColor: Colors.transparent,
      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      minHeight: 2,
    );
  }
}

class _MiniPlayerPlayButton extends ConsumerWidget {
  const _MiniPlayerPlayButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(playerProvider.select((s) => s.isPlaying));

    return IconButton(
      onPressed: () {
        ref.read(playerProvider.notifier).togglePlayPause();
      },
      icon: Icon(
        isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
        color: Colors.white,
        size: 40,
      ),
    );
  }
}

// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:dio/dio.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:audio_session/audio_session.dart';
import 'package:lucida_player/screens/main_screen.dart';
// import 'package:lucida_player/screens/search_screen.dart';

// // =============================
// // HOW TO USE
// // 1) Add to pubspec.yaml:
// //
// // dependencies:
// //   flutter:
// //     sdk: flutter
// //   flutter_riverpod: ^2.5.1
// //   dio: ^5.5.0+1
// //   just_audio: ^0.9.38
// //   audio_session: ^0.1.16
// //
// // 2) Replace `kBaseUrl` below with your Express server URL (e.g. http://10.0.2.2:3000 on Android emulator)
// // 3) Run your app. Typing in the search field will debounce and query /search?q=...
// // 4) Tap a result to start playback. Mini player shows at the bottom with title + progress.
// // =============================

// // ----- CONFIG -----
// const kBaseUrl = "https://lucida-api.vercel.app"; // Android emulator -> host machine. Use your LAN IP on device.
// // const kBaseUrl = "http://192.168.1.4:3000";

// // ----- DATA MODEL -----
// class MusicItem {
//   final String id;
//   final String title;
//   final String artist;
//   final String url; // stream URL returned by backend
//   final Duration? duration; // optional

//   MusicItem({
//     required this.id,
//     required this.title,
//     required this.artist,
//     required this.url,
//     this.duration,
//   });

//   factory MusicItem.fromJson(Map<String, dynamic> json) {
//     return MusicItem(
//       id: json['id']?.toString() ?? '',
//       title: json['title'] ?? 'Unknown',
//       artist: '',
//       url: json['url'] ?? '',
//       duration: json['durationMs'] != null
//           ? Duration(milliseconds: (json['durationMs'] as num).toInt())
//           : null,
//     );
//   }
// }

// // ----- NETWORK LAYER -----
// final dioProvider = Provider<Dio>((ref) {
//   return Dio(BaseOptions(
//     baseUrl: kBaseUrl,
//     connectTimeout: const Duration(seconds: 10),
//     receiveTimeout: const Duration(seconds: 15),
//     responseType: ResponseType.json,
//     headers: {"Accept": "application/json"},
//   ));
// });

// Future<List<MusicItem>> fetchSearch(Dio dio, String query) async {
//   if (query.trim().isEmpty) return [];
//   final res = await dio.get('/qobuz/search', queryParameters: {"query": query});
//   final data = res.data;

//   if (data is List) {
//     return data.map((e) => MusicItem.fromJson(Map<String, dynamic>.from(e))).toList();
//   }
//   // If backend returns an object like { results: [...] }
//   if (data is Map && data['results'] is List) {
//     return (data['results'] as List)
//         .map((e) => MusicItem.fromJson(Map<String, dynamic>.from(e)))
//         .toList();
//   }
//   return [];
// }

// Future<String> fetchStreamUrl(Dio dio, String url) async {
//   final res = await dio.get('/qobuz/stream', queryParameters: {"url": url});
//   final data = res.data;
//   if (data is Map && data['streamUrl'] is String) {
//     return data['streamUrl'];
//   }
//   throw Exception('Invalid stream URL response');
// }

// // ----- SEARCH STATE -----
// class SearchState {
//   final String query;
//   final AsyncValue<List<MusicItem>> results;

//   const SearchState({
//     this.query = '',
//     this.results = const AsyncValue.data([]),
//   });

//   SearchState copyWith({String? query, AsyncValue<List<MusicItem>>? results}) =>
//       SearchState(query: query ?? this.query, results: results ?? this.results);
// }

// class SearchController extends StateNotifier<SearchState> {
//   SearchController(this._dio) : super(const SearchState());
//   final Dio _dio;
//   Timer? _debounce;

//   void onQueryChanged(String q) {
//     state = state.copyWith(query: q);
//     _debounce?.cancel();
//     _debounce = Timer(const Duration(milliseconds: 350), () async {
//       await _runSearch(q);
//     });
//   }

//   Future<void> _runSearch(String q) async {
//     if (q.trim().isEmpty) {
//       state = state.copyWith(results: const AsyncValue.data([]));
//       return;
//     }
//     state = state.copyWith(results: const AsyncValue.loading());
//     try {
//       final items = await fetchSearch(_dio, q);
//       state = state.copyWith(results: AsyncValue.data(items));
//     } catch (e, st) {
//       log('Search error: $e');
//       state = state.copyWith(results: AsyncValue.error(e, st));
//     }
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }
// }

// final searchControllerProvider =
//     StateNotifierProvider<SearchController, SearchState>((ref) {
//   final dio = ref.watch(dioProvider);
//   return SearchController(dio);
// });

// // ----- AUDIO PLAYER STATE -----
// class NowPlayingState {
//   final MusicItem? current;
//   final bool isBuffering;
//   final bool isPlaying;
//   final Duration position;
//   final Duration? duration;

//   const NowPlayingState({
//     this.current,
//     this.isBuffering = false,
//     this.isPlaying = false,
//     this.position = Duration.zero,
//     this.duration,
//   });

//   NowPlayingState copyWith({
//     MusicItem? current,
//     bool? isBuffering,
//     bool? isPlaying,
//     Duration? position,
//     Duration? duration,
//   }) =>
//       NowPlayingState(
//         current: current ?? this.current,
//         isBuffering: isBuffering ?? this.isBuffering,
//         isPlaying: isPlaying ?? this.isPlaying,
//         position: position ?? this.position,
//         duration: duration ?? this.duration,
//       );
// }

// class PlayerController extends StateNotifier<NowPlayingState> {
//   final AudioPlayer _player;

//   PlayerController(this._player) : super(const NowPlayingState()) {
//     // Listen to player events -> update state
//     _player.playerStateStream.listen((ps) {
//       final playing = ps.playing;
//       final buffering = ps.processingState == ProcessingState.loading ||
//           ps.processingState == ProcessingState.buffering;
//       state = state.copyWith(isPlaying: playing, isBuffering: buffering);
//     });
//     _player.positionStream.listen((p) {
//       state = state.copyWith(position: p);
//     });
//     _player.durationStream.listen((d) {
//       state = state.copyWith(duration: d);
//     });
//   }

//   Future<void> initAudioSession() async {
//     final session = await AudioSession.instance;
//     await session.configure(const AudioSessionConfiguration.music());
//   }

//   Future<void> playItem(MusicItem item) async {
//     try {
//       state = state.copyWith(current: item);

//       final dio = Dio(BaseOptions(
//         baseUrl: kBaseUrl,
//         connectTimeout: const Duration(seconds: 10),
//         receiveTimeout: const Duration(seconds: 15),
//         responseType: ResponseType.json,
//         headers: {"Accept": "application/json"},
//       ));

//       final playUrl = await fetchStreamUrl(dio, item.url);

// debugPrint('Playing URL: $playUrl');

//       // If your backend needs headers, pass them here
//       await _player.setUrl(playUrl /*, headers: {'Authorization': 'Bearer ...'}*/);

//       await _player.play();
//     } catch (e) {
//       debugPrint('Error playing: $e');
//     }
//   }

//   Future<void> togglePlayPause() async {
//     if (_player.playing) {
//       await _player.pause();
//     } else {
//       await _player.play();
//     }
//   }

//   Future<void> seek(Duration pos) => _player.seek(pos);

//   @override
//   Future<void> dispose() async {
//     await _player.dispose();
//     super.dispose();
//   }
// }

// final audioPlayerProvider = Provider<AudioPlayer>((ref) {
//   final player = AudioPlayer();
//   // no setAudioSource here; handled by controller
//   ref.onDispose(() => player.dispose());
//   return player;
// });

// final playerControllerProvider =
//     StateNotifierProvider<PlayerController, NowPlayingState>((ref) {
//   final p = PlayerController(ref.watch(audioPlayerProvider));
//   unawaited(p.initAudioSession());
//   return p;
// });

// ----- UI -----
Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Prototype',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 0),
        fontFamily: 'Gotham',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 255, 255, 255),
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

// class SearchScreen extends ConsumerStatefulWidget {
//   const SearchScreen({super.key});

//   @override
//   ConsumerState<SearchScreen> createState() => _SearchScreenState();
// }

// class _SearchScreenState extends ConsumerState<SearchScreen> {
//   final _controller = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _controller.addListener(() {
//       ref.read(searchControllerProvider.notifier).onQueryChanged(_controller.text);
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final searchState = ref.watch(searchControllerProvider);
//     final player = ref.watch(playerControllerProvider);

//     return Scaffold(
//       appBar: AppBar(title: const Text('Search & Play')),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: TextField(
//               controller: _controller,
//               decoration: InputDecoration(
//                 hintText: 'Search songs, artists... ',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//             ),
//           ),
//           Expanded(
//             child:switch (searchState.results) {
//               AsyncData(:final value) => _ResultsList(items: value),
//               AsyncError(:final error) => Center(child: Text('Error: ${error.toString()}')),
//               AsyncLoading() => const Center(child: CircularProgressIndicator()),
//               _ => const SizedBox.shrink(), // fallback exhaustive match
//             },
//           ),
//           if (player.current != null) MiniPlayer(item: player.current!),
//         ],
//       ),
//     );
//   }
// }

// class _ResultsList extends ConsumerWidget {
//   const _ResultsList({required this.items});
//   final List<MusicItem> items;

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     if (items.isEmpty) {
//       return const Center(child: Text('Type to search music'));
//     }
//     return ListView.separated(
//       itemCount: items.length,
//       separatorBuilder: (_, __) => const Divider(height: 1),
//       itemBuilder: (context, index) {
//         final item = items[index];
//         return ListTile(
//           leading: const Icon(Icons.music_note),
//           title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
//           subtitle: Text(item.artist),
//           onTap: () => ref.read(playerControllerProvider.notifier).playItem(item),
//         );
//       },
//     );
//   }
// }

// class MiniPlayer extends ConsumerWidget {
//   const MiniPlayer({super.key, required this.item});
//   final MusicItem item;

//   String _fmt(Duration d) {
//     final two = (int n) => n.toString().padLeft(2, '0');
//     final m = d.inMinutes;
//     final s = d.inSeconds % 60;
//     return '${two(m)}:${two(s)}';
//   }

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final state = ref.watch(playerControllerProvider);
//     final ctrl = ref.read(playerControllerProvider.notifier);

//     final duration = state.duration ?? item.duration ?? Duration.zero;
//     final pos = state.position;
//     final progress = (duration.inMilliseconds == 0)
//         ? 0.0
//         : pos.inMilliseconds / duration.inMilliseconds;

//     return Material(
//       elevation: 8,
//       child: InkWell(
//         onTap: () {}, // expand to full player later
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           child: Row(
//             children: [
//               const Icon(Icons.album, size: 36),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       item.title,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(fontWeight: FontWeight.w600),
//                     ),
//                     const SizedBox(height: 6),
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(4),
//                       child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(_fmt(pos), style: const TextStyle(fontSize: 12)),
//                         Text(_fmt(duration), style: const TextStyle(fontSize: 12)),
//                       ],
//                     )
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 12),
//               IconButton(
//                 onPressed: () => ctrl.togglePlayPause(),
//                 icon: state.isPlaying
//                     ? const Icon(Icons.pause_circle_filled, size: 36)
//                     : const Icon(Icons.play_circle_fill, size: 36),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

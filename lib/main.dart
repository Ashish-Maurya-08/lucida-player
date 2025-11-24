// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:dio/dio.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:audio_session/audio_session.dart';
import 'package:lucida_player/screens/main_screen.dart';
import 'package:lucida_player/utils/audiohandler.dart';
// import 'package:lucida_player/screens/search_screen.dart';

late AudioHandler audioHandler;
Future<void> main() async {
  await dotenv.load(fileName: ".env");
  audioHandler = await AudioService.init(
    builder: () => AudioPlayerHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.example.lucida_player.channel',
      androidNotificationChannelName: 'Music',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
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

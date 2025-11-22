import 'package:flutter/material.dart';
import 'package:lucida_player/screens/search_screen.dart';
import 'package:lucida_player/screens/music_player.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SearchScreen()),
          const Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayer()),
        ],
      ),
    );
  }
}

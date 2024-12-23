// main.dart
import 'package:flutter/material.dart';
import './screens/MoodSelectionScreen.dart';
import './api/CallbackHandler.dart';
import './api/AuthURL.dart';

void main() {
  runApp(const MoodPlaylistApp());
}

class MoodPlaylistApp extends StatelessWidget {
  const MoodPlaylistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Playlist App',
      theme: ThemeData(primarySwatch: Colors.teal),
      initialRoute: SpotifyAuth().isCallbackUrl() ? '/callback' : '/',
      routes: {
        '/': (context) => const MoodSelectionScreen(),
        '/callback': (context) => const CallbackHandler(),
      },
    );
  }
}
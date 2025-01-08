// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
      title: 'Mood Based Playlist',
      theme: ThemeData(
          textTheme: GoogleFonts.latoTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      )),
      home: const MoodSelectionScreen(),
    );
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import './screens/MoodSelectionScreen.dart';

void main() => runApp(const MoodPlaylistApp());

class MoodPlaylistApp extends StatelessWidget {
  const MoodPlaylistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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

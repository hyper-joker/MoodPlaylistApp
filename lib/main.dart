import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './screens/MoodSelectionScreen.dart';

void main() => runApp(const MoodPlaylistApp());

class MoodPlaylistApp extends StatelessWidget {
  const MoodPlaylistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Based Playlist',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const MoodSelectionScreen(),
    );
  }
}





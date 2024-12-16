import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Playlist Screen
class PlaylistScreen extends StatefulWidget {
  final String mood;

  const PlaylistScreen({Key? key, required this.mood}) : super(key: key);

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<dynamic> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists(); // Load the playlist based on mood
  }

  Future<void> _loadPlaylists() async {
    // Load JSON data
    final String response = await rootBundle.loadString('assets/playlists.json');
    final Map<String, dynamic> data = jsonDecode(response);

    // Update state with playlists for the selected mood
    setState(() {
      _playlists = data[widget.mood] ?? []; // Default to empty list if no match
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mood} Playlists'),
      ),
      body: _playlists.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Show loading
          : ListView.builder(
        itemCount: _playlists.length,
        itemBuilder: (context, index) {
          final playlist = _playlists[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(playlist['name']),
              subtitle: Text(playlist['artist']),
              trailing: const Icon(Icons.play_arrow),
              onTap: () {
                _showSongDetails(context, playlist['name'], playlist['url']);
              },
            ),
          );
        },
      ),
    );
  }

  void _showSongDetails(BuildContext context, String name, String url) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(name),
          content: Text('Link: $url'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            )
          ],
        );
      },
    );
  }
}
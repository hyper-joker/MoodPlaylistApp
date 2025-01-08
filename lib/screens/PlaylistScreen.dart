import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './FavoritesScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaylistScreen extends StatefulWidget {
  final String mood;

  const PlaylistScreen({Key? key, required this.mood}) : super(key: key);

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<dynamic> _playlists = [];

  final moodThemes = {
    'Happy': {
      'lighterColor': Color.fromARGB(255, 255, 229, 204),
      'mediumColor': Color.fromARGB(255, 244, 164, 96),
      'darkerColor': Color.fromARGB(255, 255, 69, 0),
    },
    'Sad': {
      'lighterColor': Color.fromARGB(255, 200, 223, 249),
      'mediumColor': Color.fromARGB(255, 140, 166, 209),
      'darkerColor': Color.fromARGB(255, 0, 31, 63),
    },
    'Hopeful': {
      'lighterColor': Color.fromARGB(255, 200, 249, 216),
      'mediumColor': Color.fromARGB(255, 143, 180, 143),
      'darkerColor': Color.fromARGB(255, 0, 59, 45),
    },
    'Party': {
      'lighterColor': Color.fromARGB(255, 255, 200, 200),
      'mediumColor': Color.fromARGB(255, 229, 153, 153),
      'darkerColor': Color.fromARGB(255, 176, 0, 32),
    },
  };

  @override
  void initState() {
    super.initState();
    _loadPlaylists(); // Load the playlist data based on mood
  }

  Future<void> _loadPlaylists() async {
    // Load JSON data
    final String response =
        await rootBundle.loadString('assets/playlists.json');
    final Map<String, dynamic> data = jsonDecode(response);

    setState(() {
      _playlists = data[widget.mood] ?? []; // Default to empty list if no match
    });
  }

  Future<void> _addToFavorites(Map<String, String> playlist) async {
    final prefs = await SharedPreferences.getInstance();

    // Fetch existing favorites (or start with an empty list)
    final String? existingFavorites = prefs.getString('favorites');
    List<dynamic> favorites =
        existingFavorites != null ? jsonDecode(existingFavorites) : [];

    // Determine the theme colors for the current mood
    final currentTheme = moodThemes[widget.mood] ??
        {
          'lighterColor': Colors.grey[200] ?? const Color(0xFFEEEEEE),
          'darkerColor': Colors.grey[800] ?? const Color(0xFF424242),
        };

    // Add the new favorite (if not already added)
    if (!favorites.any((item) => item['name'] == playlist['name'])) {
      favorites.add(playlist);
      await prefs.setString(
          'favorites', jsonEncode(favorites)); // Save back to SharedPreferences
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Added to Favorites!"),
        backgroundColor: currentTheme['darkerColor'] as Color,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Already in Favorites!"),
        backgroundColor: currentTheme['darkerColor'] as Color,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = moodThemes[widget.mood] ??
        {
          'lighterColor': Colors.grey[200] ?? const Color(0xFFEEEEEE),
          'darkerColor': Colors.grey[800] ?? const Color(0xFF424242),
        };

    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(
                widget.mood == 'Happy'
                    ? Icons.sunny
                    : widget.mood == 'Sad'
                        ? Icons.cloud
                        : widget.mood == 'Hopeful'
                            ? Icons.brightness_5
                            : Icons.bolt,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.mood} Playlist',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          backgroundColor: theme['darkerColor'] as Color,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              //??
              icon: const Icon(Icons.favorite),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FavoritesScreen()),
                );
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme['lighterColor'] as Color,
                theme['mediumColor'] as Color,
                theme['darkerColor'] as Color,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: _playlists.isEmpty
              ? const Center(child: CircularProgressIndicator()) // Show loading
              : ListView.builder(
                  itemCount: _playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = _playlists[index];
                    //de vazut
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      color: theme['mediumColor'] as Color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.music_note_outlined,
                            color: theme['darkerColor'] as Color),
                        title: Text(playlist['name'],
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: theme['darkerColor'] as Color,
                                    offset: Offset(2.0, 2.0),
                                  )
                                ])),
                        subtitle: Text(playlist['artist'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            )),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite_border,
                              color: Colors.white70),
                          onPressed: () {
                            //color change
                            _addToFavorites({
                              'name': playlist['name'],
                              'artist': playlist['artist'],
                              'mood': widget.mood,
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
        ));
  }
}

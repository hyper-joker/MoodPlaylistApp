import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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

    // Add the new favorite (if not already added)
    if (!favorites.any((item) => item['name'] == playlist['name'])) {
      favorites.add(playlist);
      await prefs.setString(
          'favorites', jsonEncode(favorites)); // Save back to SharedPreferences
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Added to Favorites!")));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Already in Favorites!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mood} Playlists'),
        actions: [
          IconButton(
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
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite_border),
                      onPressed: () {
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
    );
  }
}

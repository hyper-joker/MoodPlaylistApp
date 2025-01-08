// favoritesscreen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api/AuthURL.dart';
import 'package:url_launcher/url_launcher.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _favoritesPlaylistId;

  @override
  void initState() {
    super.initState();
    _fetchFavoritesPlaylist();
  }

  Future<void> _refreshFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _fetchFavoritesPlaylist();
    return Future.value();
  }

  // Fetch or create the "Favorites from Moods" playlist
  Future<void> _fetchFavoritesPlaylist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final spotifyAuth = SpotifyAuth();
      final accessToken = spotifyAuth.accessToken;

      if (accessToken == null) {
        throw Exception("User is not authenticated.");
      }

      // Check if the "Favorites from Moods" playlist already exists
      final playlistId = await _getFavoritesPlaylistId();

      if (playlistId != null) {
        // Playlist found, proceed to fetch the tracks
        _favoritesPlaylistId = playlistId;
        await _fetchTracksFromPlaylist(playlistId);
      } else {
        // If the playlist does not exist, create it
        final createdPlaylistId = await _createFavoritesPlaylist();

        if (createdPlaylistId != null && createdPlaylistId.isNotEmpty) {
          _favoritesPlaylistId = createdPlaylistId;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Created Favorites playlist!")),
          );
          await _fetchTracksFromPlaylist(createdPlaylistId);
        } else {
          throw Exception("Failed to create playlist.");
        }
      }
    } catch (error) {
      setState(() {
        _errorMessage = "Error: $error";
        _isLoading = false;
      });
    }
  }

  // Check if the "Favorites from Moods" playlist exists
  Future<String?> _getFavoritesPlaylistId() async {
    final spotifyAuth = SpotifyAuth();
    final accessToken = spotifyAuth.accessToken;

    if (accessToken == null) {
      throw Exception("User is not authenticated.");
    }

    const url = "https://api.spotify.com/v1/me/playlists";
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final playlists = data['items'] as List<dynamic>;

      final playlist = playlists.firstWhere(
            (p) => p['name'] == "Favorites from Moods",
        orElse: () => null,
      );

      return playlist?['id'];
    } else {
      throw Exception("Error fetching playlists: ${response.body}");
    }
  }

  // Create the "Favorites from Moods" playlist if it does not exist
  Future<String?> _createFavoritesPlaylist() async {
    final spotifyAuth = SpotifyAuth();
    final accessToken = spotifyAuth.accessToken;

    if (accessToken == null) {
      throw Exception("User is not authenticated.");
    }

    final userId = await spotifyAuth.getCurrentUserId();
    if (userId == null) throw Exception("Failed to get user ID.");

    final playlistId = await spotifyAuth.createPlaylist(userId, "Favorites from Moods");
    return playlistId;
  }

  // Fetch tracks from the "Favorites from Moods" playlist
  Future<void> _fetchTracksFromPlaylist(String playlistId) async {
    final String url =
        "https://api.spotify.com/v1/playlists/$playlistId/tracks";

    try {
      final spotifyAuth = SpotifyAuth();
      final accessToken = spotifyAuth.accessToken;

      if (accessToken == null) {
        throw Exception("User is not authenticated.");
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>;

        setState(() {
          _favorites = items.map((item) {
            final track = item['track'];
            return {
              'name': track['name'],
              'artists': (track['artists'] as List<dynamic>)
                  .map((artist) => artist['name'])
                  .join(', '),
              'url': track['external_urls']['spotify'],
              'uri': track['uri'],
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Error fetching tracks: ${response.body}";
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = "Error fetching tracks: $error";
        _isLoading = false;
      });
    }
  }

  // Add a track to the "Favorites from Moods" playlist
  Future<void> _addToFavorites(Map<String, dynamic> track) async {
    final spotifyAuth = SpotifyAuth();
    final playlistId = _favoritesPlaylistId;

    if (playlistId != null) {
      await spotifyAuth.addSongToFavoritesPlaylist(playlistId, track['uri']);
      setState(() {
        _favorites.add(track);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added to Favorites!")),
      );
    }
  }

  // Remove a track from the "Favorites from Moods" playlist
  Future<void> _removeFromFavorites(Map<String, dynamic> track) async {
    final spotifyAuth = SpotifyAuth();
    final playlistId = _favoritesPlaylistId;

    if (playlistId != null) {
      await spotifyAuth.removeSongFromFavoritesPlaylist(playlistId, track['uri']);
      setState(() {
        _favorites.removeWhere((item) => item['uri'] == track['uri']);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Removed from Favorites!")),
      );
    }
  }

  // Open the track's URL in Spotify
  void _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites from Moods'),
        backgroundColor: const Color.fromARGB(255, 29, 1, 76),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 103, 58, 183),
              Color.fromARGB(255, 29, 1, 76),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        )
            : _favorites.isEmpty
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border_rounded,
                  color: Colors.white, size: 50),
              SizedBox(height: 20),
              Text(
                "No favorites added yet!",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        )
            : ListView.builder(
          itemCount: _favorites.length,
          itemBuilder: (context, index) {
            final track = _favorites[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              color: Colors.white12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
              child: ListTile(
                title: Text(track['name'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    )),
                subtitle: Text(
                  track['artists'] ?? 'Unknown Artist',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.red),
                      onPressed: () {
                        _removeFromFavorites(track);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new,
                          color: Colors.green),
                      onPressed: () {
                        final url = track['url'];
                        if (url != null) {
                          _launchUrl(url);
                        } else {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "URL not available for this track")),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

//Playlistscreen.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api/AuthURL.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaylistScreen extends StatefulWidget {
  final String mood;

  PlaylistScreen({required this.mood});

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

void _launchUrl(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _playlistId; // Store playlist ID to delete it

  @override
  void initState() {
    super.initState();
    _checkAndFetchPlaylist();
  }

  Future<void> _addToFavorites(Map<String, dynamic> track) async {
    final spotifyAuth = SpotifyAuth();

    try {
      // First, try to find existing Favorites playlist
      String? playlistId = await _getFavoritesPlaylistId();

      // If no favorites playlist exists, create one on Spotify
      if (playlistId == null) {
        final userId = await spotifyAuth.getCurrentUserId();
        if (userId == null) throw Exception("Failed to get user ID.");

        // Create the playlist on Spotify
        playlistId = await spotifyAuth.createFavoritesPlaylist();
        if (playlistId == null) throw Exception("Failed to create Favorites playlist");
      }

      print('Adding track to playlist: $playlistId'); // Debug print
      print('Track URI: ${track['uri']}'); // Debug print

      // Add the track to the Spotify playlist
      await spotifyAuth.addSongToFavoritesPlaylist(playlistId, track['uri']);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Added to Favorites!"))
      );
    } catch (e, stackTrace) {
      print('Error adding to favorites: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add to Favorites. Error: $e"))
      );
    }
  }

  Future<String?> _getFavoritesPlaylistId() async {
    final spotifyAuth = SpotifyAuth();
    final playlists = await spotifyAuth.fetchUserPlaylists();

    for (var playlist in playlists) {
      print('Found playlist: ${playlist['name']}'); // Debug print
      if (playlist['name'] == 'Favorites from Moods') {
        return playlist['id'];
      }
    }
    return null;
  }

  Future<void> _checkAndFetchPlaylist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final playlistId = await _getPlaylistIdByName();
      _playlistId = playlistId; // Save the playlist ID for deletion

      if (playlistId != null) {
        await _fetchTracksFromPlaylist(playlistId);
      } else {
        await _createAndFetchPlaylist();
      }
    } catch (error) {
      setState(() {
        _errorMessage = "Error: $error";
        _isLoading = false;
      });
    }
  }

  Future<String?> _getPlaylistIdByName() async {
    final spotifyAuth = SpotifyAuth();
    final accessToken = spotifyAuth.accessToken;

    if (accessToken == null) {
      throw Exception("User is not authenticated.");
    }

    const String url = "https://api.spotify.com/v1/me/playlists";
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final playlists = data['items'] as List<dynamic>;

      final playlist = playlists.firstWhere(
            (p) => p['name'] == "${widget.mood} Playlist",
        orElse: () => null,
      );

      return playlist?['id'];
    } else {
      throw Exception("Error fetching playlists: ${response.body}");
    }
  }

  Future<void> _createAndFetchPlaylist() async {
    final spotifyAuth = SpotifyAuth();
    final accessToken = spotifyAuth.accessToken;

    if (accessToken == null) {
      throw Exception("User is not authenticated.");
    }

    final userId = await spotifyAuth.getCurrentUserId();
    if (userId == null) throw Exception("Failed to get user ID.");

    final playlistId =
    await spotifyAuth.createPlaylist(userId, "${widget.mood} Playlist");
    _playlistId = playlistId; // Save the playlist ID for deletion

    if (playlistId == null) throw Exception("Failed to create playlist.");

    final trackUris = await spotifyAuth.searchTracksByMood(widget.mood);
    if (trackUris.isEmpty) {
      setState(() {
        _errorMessage = "No tracks found for the given mood.";
        _isLoading = false;
      });
      return;
    }

    await spotifyAuth.addTracksToPlaylist(playlistId, trackUris);
    await _fetchTracksFromPlaylist(playlistId);
  }

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
          _tracks = items.map((item) {
            final track = item['track'];
            return {
              'name': track['name'],
              'artists': (track['artists'] as List<dynamic>)
                  .map((artist) => artist['name'])
                  .join(', '),
              'url': track['external_urls']['spotify'], // Add track URL here
              'uri': track['uri'], // Add track URI here
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

  /// Deletes the playlist
  Future<void> _deletePlaylist() async {
    if (_playlistId == null) {
      setState(() {
        _errorMessage = "No playlist to delete.";
      });
      return;
    }

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

      final String url =
          "https://api.spotify.com/v1/playlists/$_playlistId/followers";
      final response = await http.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _tracks = [];
          _playlistId = null;
          _isLoading = false;
          _errorMessage = "Playlist deleted successfully.";
        });
      } else {
        setState(() {
          _errorMessage = "Error deleting playlist: ${response.body}";
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = "Error deleting playlist: $error";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            // Deleting playlist functionality remains unchanged
            final shouldDelete = await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("Delete Playlist"),
                  content: Text("Are you sure you want to delete this playlist?"),
                  actions: [
                    TextButton(
                      child: Text("Cancel"),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                    TextButton(
                      child: Text("Delete"),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                );
              },
            );

            if (shouldDelete == true) {
              await _deletePlaylist();
            }
          },
        ),
        title: Text("${widget.mood} Playlist"),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
          : ListView.builder(
        itemCount: _tracks.length,
        itemBuilder: (context, index) {
          final track = _tracks[index];
          return ListTile(
            title: Text(track['name'] ?? 'Unknown'),
            subtitle: Text(track['artists'] ?? 'Unknown Artist'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.favorite, color: Colors.pink),
                  onPressed: () {
                    _addToFavorites(track);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.open_in_new, color: Colors.green),
                  onPressed: () {
                    final url = track['url'];
                    if (url != null) {
                      _launchUrl(url);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("URL not available for this track")),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

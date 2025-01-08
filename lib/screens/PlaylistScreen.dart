// PlaylistScreen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api/AuthURL.dart';
import './FavoritesScreen.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaylistScreen extends StatefulWidget {
  final String mood;

  const PlaylistScreen({required this.mood, Key? key}) : super(key: key);

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _playlistId;

  @override
  void initState() {
    super.initState();
    _checkAndFetchPlaylist();
  }

  Future<void> _deletePlaylist() async {
    // Show confirmation dialog
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Playlist'),
          content: const Text('Are you sure you want to delete this playlist?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true && _playlistId != null) {
      try {
        final spotifyAuth = SpotifyAuth();
        await spotifyAuth.deletePlaylist(_playlistId!);

        // Show success message and navigate back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Playlist deleted successfully')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete playlist: $e')),
          );
        }
      }
    }
  }

  Future<void> _checkAndFetchPlaylist() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final playlistId = await _getPlaylistIdByName();
      _playlistId = playlistId;

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

    const url = "https://api.spotify.com/v1/me/playlists";
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
    _playlistId = playlistId;

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
    final spotifyAuth = SpotifyAuth();
    final accessToken = spotifyAuth.accessToken;

    if (accessToken == null) {
      throw Exception("User is not authenticated.");
    }

    final url = "https://api.spotify.com/v1/playlists/$playlistId/tracks";

    try {
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

  Future<void> _addToFavorites(Map<String, dynamic> track) async {
    final spotifyAuth = SpotifyAuth();

    try {
      String? playlistId = await _getFavoritesPlaylistId();

      if (playlistId == null) {
        playlistId = await spotifyAuth.createFavoritesPlaylist();
      }

      if (playlistId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to create Favorites playlist.")),
        );
        return;
      }
      await spotifyAuth.addSongToFavoritesPlaylist(playlistId, track['uri']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Added to Favorites!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add to Favorites. Error: $e")),
      );
    }
  }

  Future<String?> _getFavoritesPlaylistId() async {
    final spotifyAuth = SpotifyAuth();
    final playlists = await spotifyAuth.fetchUserPlaylists();

    for (var playlist in playlists) {
      if (playlist['name'] == 'Favorites from Moods') {
        return playlist['id'];
      }
    }
    return null;
  }

  void _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch URL")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.mood} Playlist"),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FavoritesScreen()),
              );
            },

          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deletePlaylist,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      )
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
                  icon: const Icon(Icons.favorite, color: Colors.pink),
                  onPressed: () {
                    _addToFavorites(track);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.open_in_new, color: Colors.green),
                  onPressed: () {
                    final url = track['url'];
                    if (url != null) {
                      _launchUrl(url);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("URL not available for this track"),
                        ),
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

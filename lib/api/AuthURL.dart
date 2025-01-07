//Authurl.Dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:async';
import 'TokenStorage.dart'; // Import the TokenStorage file
import 'dart:math';

const String clientId = '91d93b29ea2e4d5589a6b0c6ccb2511b';
const String baseUrl =
    'http://localhost:5454'; // Update with your current ngrokg URL
const String redirectUri = '$baseUrl/callback';

final authStateController = StreamController<String?>.broadcast();

class SpotifyAuth {
  static final SpotifyAuth _instance = SpotifyAuth._internal();

  factory SpotifyAuth() => _instance;

  SpotifyAuth._internal();

  String? _accessToken;

  String? get accessToken => _accessToken;

  void authenticateWithSpotify() {
    final authUrl = Uri.https('accounts.spotify.com', '/authorize', {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': redirectUri,
      'scope': [
        'playlist-read-private',
        'playlist-read-collaborative',
        'playlist-modify-public',
        'playlist-modify-private',
        'user-library-read',
      ].join(' '),
    });

    html.window.location.href = authUrl.toString();
  }

  final Map<String, String> moodToGenre = {
    "Party": "Housemusic",
    "Happy": "popcore",
    "Sad": "sadcore",
    "Chill": "Chillcore",
  };

  Future<bool> handleCallback(BuildContext context) async {
    if (!isCallbackUrl()) return false;

    final uri = Uri.parse(html.window.location.href);
    final code = uri.queryParameters['code'];

    if (code != null) {
      final token = await exchangeCodeForToken(code);
      if (token != null) {
        _accessToken = token;
        await storeAccessToken(token);
        authStateController.add(token);

        // Navigate back to main app
        Navigator.of(context).pushReplacementNamed('/');
        return true;
      }
    }
    return false;
  }

  Future<String?> exchangeCodeForToken(String code) async {
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'client_secret': 'ce83057d80fb44a9a12cd5a0c1ec778f',
        // Replace with your client secret
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    }
    return null;
  }

  bool isCallbackUrl() {
    return html.window.location.pathname == '/callback';
  }

  bool isAuthenticated() {
    return _accessToken != null;
  }

  // Method to search tracks based on mood with randomness
  Future<List<String>> searchTracksByMood(String mood) async {
    final accessToken = this.accessToken;
    if (accessToken == null) throw Exception("User is not authenticated.");

    try {
      final genre = moodToGenre[mood];
      if (genre == null) {
        throw Exception("No genre mapping found for mood: $mood");
      }

      print(
          '\n=== Starting playlist search for mood: $mood (genre: $genre) ===\n');

      // 1. Search for playlists matching the genre
      final playlistSearchUrl = Uri.parse("https://api.spotify.com/v1/search")
          .replace(queryParameters: {
        'q': genre,
        'type': 'playlist',
        'limit': '20' // Fetch up to 20 playlists
      });

      print('Searching playlists with URL: $playlistSearchUrl');

      final playlistResponse = await http.get(
        playlistSearchUrl,
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (playlistResponse.statusCode != 200) {
        print('Error in playlist search: ${playlistResponse.body}');
        throw Exception("Error searching playlists: ${playlistResponse.body}");
      }

      final playlistData = jsonDecode(playlistResponse.body);
      final playlists = playlistData['playlists']['items'] as List<dynamic>;

      print('\n=== Found ${playlists.length} playlists ===\n');

      if (playlists.length < 2) {
        throw Exception("Not enough playlists found for mood: $mood");
      }

      // Randomly select 2 playlists from the fetched list
      playlists.shuffle();
      final selectedPlaylists = playlists.take(2).toList();

      print(
          '\n=== Randomly selected playlists: ${selectedPlaylists.map((p) => p['name']).join(', ')} ===\n');

      // 2. Get random tracks from each selected playlist
      Set<String> selectedTrackUris = {}; // Use Set to avoid duplicates
      final random = Random();

      for (var playlist in selectedPlaylists) {
        final playlistId = playlist['id'];

        print('\n=== Getting tracks from playlist: ${playlist['name']} ===\n');

        // Get all tracks from the playlist
        final tracksUrl =
        Uri.parse("https://api.spotify.com/v1/playlists/$playlistId/tracks")
            .replace(queryParameters: {
          'fields': 'items(track(uri,name,artists(name)))', // Only get needed fields
          'limit': '50' // Fetch up to 50 tracks to randomly select from
        });

        final tracksResponse = await http.get(
          tracksUrl,
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (tracksResponse.statusCode != 200) {
          print('Error getting playlist tracks: ${tracksResponse.body}');
          continue; // Skip to next playlist if this one fails
        }

        final tracksData = jsonDecode(tracksResponse.body);
        final tracks = tracksData['items'] as List<dynamic>;

        // Shuffle tracks and take 10 random ones
        final playlistTracks = tracks
            .where((item) =>
        item != null &&
            item['track'] != null &&
            item['track']['uri'] != null &&
            item['track']['name'] != null)
            .toList();

        playlistTracks.shuffle(random);

        // Take 10 random tracks from this playlist
        for (var item in playlistTracks.take(10)) {
          final track = item['track'];
          final artists = (track['artists'] as List<dynamic>)
              .map((artist) => artist['name'] as String)
              .join(', ');

          print('Selected track: ${track['name']} by $artists');
          selectedTrackUris.add(track['uri'] as String);
        }
      }

      final tracksList = selectedTrackUris.toList();
      print('\n=== Final track count: ${tracksList.length} ===\n');

      return tracksList;
    } catch (e, stackTrace) {
      print('\n=== Error in searchTracksByMood ===');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Method to create a new playlist on the user's account
  Future<String?> createPlaylist(String userId, String playlistName) async {
    final accessToken = this.accessToken;

    if (accessToken == null) throw Exception("User is not authenticated.");

    final url = "https://api.spotify.com/v1/users/$userId/playlists";
    final body = jsonEncode({
      'name': playlistName,
      'description': 'A playlist for $playlistName mood',
      'public': false,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else {
      throw Exception("Error creating playlist: ${response.body}");
    }
  }

  // Method to get the current user's Spotify user ID
  Future<String?> getCurrentUserId() async {
    final accessToken = this.accessToken;

    if (accessToken == null) throw Exception("User is not authenticated.");

    final url = "https://api.spotify.com/v1/me";
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['id'];
    } else {
      throw Exception("Error getting user ID: ${response.body}");
    }
  }

  // Method to add tracks to a playlist
  Future<void> addTracksToPlaylist(
      String playlistId, List<String> trackUris) async {
    final accessToken = this.accessToken;

    if (accessToken == null) throw Exception("User is not authenticated.");

    final url = "https://api.spotify.com/v1/playlists/$playlistId/tracks";

    final body = jsonEncode({
      'uris': trackUris,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 201) {
      throw Exception("Error adding tracks to playlist: ${response.body}");
    }
  }

  // Method to generate a playlist based on mood
  Future<void> generatePlaylist(String mood) async {
    final accessToken = this.accessToken;

    if (accessToken == null) throw Exception("User is not authenticated.");

    final userId = await getCurrentUserId();
    if (userId == null) throw Exception("Failed to get user ID.");

    // Create the playlist
    final playlistId = await createPlaylist(userId, "$mood Playlist");
    if (playlistId == null) throw Exception("Failed to create playlist.");

    // Get random tracks for the mood
    final trackUris = await searchTracksByMood(mood);
    if (trackUris.isEmpty) throw Exception("No tracks found for the mood.");

    // Add tracks to the playlist
    await addTracksToPlaylist(playlistId, trackUris);
  }

  // Method to fetch playlists of the current user
  Future<List<dynamic>> fetchUserPlaylists() async {
    final accessToken = this.accessToken;

    if (accessToken == null) throw Exception("User is not authenticated.");

    const String url = "https://api.spotify.com/v1/me/playlists";
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['items'];
    } else {
      throw Exception("Error fetching playlists: ${response.body}");
    }
  }
  // Create the "Favorites from Moods" playlist
  Future<String?> createFavoritesPlaylist() async {
    final accessToken = this.accessToken;
    if (accessToken == null) throw Exception("User is not authenticated.");

    final userId = await getCurrentUserId();
    if (userId == null) throw Exception("Failed to get user ID.");

    print('Creating Favorites playlist for user: $userId'); // Debug print

    final url = "https://api.spotify.com/v1/users/$userId/playlists";
    final body = jsonEncode({
      'name': 'Favorites from Moods',
      'description': 'Your favorite tracks from the Mood Playlist app!',
      'public': false,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('Create playlist response: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body}'); // Debug print

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'];
      } else {
        throw Exception("Error creating playlist: ${response.body}");
      }
    } catch (e, stackTrace) {
      print('Error creating playlist: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }

// Add a song to the "Favorites from Moods" playlist
  Future<void> addSongToFavoritesPlaylist(String playlistId, String trackUri) async {
    final accessToken = this.accessToken;
    if (accessToken == null) throw Exception("User is not authenticated.");

    print('Adding track: $trackUri to playlist: $playlistId'); // Debug print

    final url = "https://api.spotify.com/v1/playlists/$playlistId/tracks";
    final body = jsonEncode({
      'uris': [trackUri],
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('Add track response: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body}'); // Debug print

      if (response.statusCode != 201) {
        throw Exception("Error adding track to favorites playlist: ${response.body}");
      }
    } catch (e, stackTrace) {
      print('Error adding track: $e'); // Debug print
      print('Stack trace: $stackTrace'); // Debug print
      rethrow;
    }
  }

  // Remove a song from the "Favorites from Moods" playlist
  Future<void> removeSongFromFavoritesPlaylist(String playlistId, String trackUri) async {
    final accessToken = this.accessToken;
    if (accessToken == null) throw Exception("User is not authenticated.");

    final url = "https://api.spotify.com/v1/playlists/$playlistId/tracks";
    final body = jsonEncode({
      'tracks': [
        {'uri': trackUri},
      ],
    });

    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception("Error removing track from favorites playlist: ${response.body}");
    }
  }
}

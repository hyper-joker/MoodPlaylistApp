import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:async';
import 'TokenStorage.dart'; // Import the TokenStorage file

const String clientId = '91d93b29ea2e4d5589a6b0c6ccb2511b';
const String baseUrl = 'http://localhost:5454'; // Update with your current ngrok URL
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
      'scope': ['playlist-read-private', 'playlist-read-collaborative'].join(' '),
    });

    html.window.location.href = authUrl.toString();
  }

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
        'client_secret': 'ce83057d80fb44a9a12cd5a0c1ec778f', // Replace with your client secret
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

  Future<Map<String, dynamic>?> searchPlaylist(String keyword) async {
    if (_accessToken == null) {
      print('Access token is null. Cannot perform search.');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/search?q=$keyword&type=playlist&limit=1'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      print('Search Playlist Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Log the decoded JSON for debugging
        print('Search Playlist Decoded Response: ${jsonEncode(data)}');

        if (data['playlists']['items'].isNotEmpty) {
          print('First Playlist Found: ${data['playlists']['items'][0]}');
          return data['playlists']['items'][0]; // Return the first playlist
        } else {
          print('No playlists found for keyword: $keyword');
        }
      } else {
        print('Failed to search playlists. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error while searching playlists: $e');
    }

    return null; // Return null if no playlist is found
  }

  Future<List<Map<String, String>>> getPlaylistTracks(String playlistId) async {
    final String url = "https://api.spotify.com/v1/playlists/$playlistId/tracks";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      print("Get Playlist Tracks Response Status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        print("Get Playlist Tracks Decoded Response: $decodedResponse");

        // Extracting track names and other details
        final List<dynamic> items = decodedResponse['items'] ?? [];
        final List<Map<String, String>> tracks = items.map((item) {
          final track = item['track'] as Map<String, dynamic>;
          return {
            'name': track['name'] as String? ?? 'Unknown Name',
            'artist': (track['artists'] as List<dynamic>)
                .map((artist) => artist['name'] as String)
                .join(', '),
            'url': track['external_urls']['spotify'] as String,
          };
        }).toList();

        print("Tracks: $tracks");
        return tracks;
      } else {
        print("Error while fetching playlist tracks: ${response.body}");
        return [];
      }
    } catch (error) {
      print("Error while fetching playlist tracks: $error");
      return [];
    }
  }
}

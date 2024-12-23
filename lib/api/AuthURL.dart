// AuthURL.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:async';
import 'TokenStorage.dart';  // Import the TokenStorage file

const String clientId = '91d93b29ea2e4d5589a6b0c6ccb2511b';
const String baseUrl = 'http://localhost:5454';  // Update with your current ngrok URL
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
        'client_secret': 'ce83057d80fb44a9a12cd5a0c1ec778f',  // Replace with your client secret
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
}


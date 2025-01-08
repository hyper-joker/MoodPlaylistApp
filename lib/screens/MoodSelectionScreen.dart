// MoodSelectionScreen.dart
import 'package:flutter/material.dart';
import '../api/AuthURL.dart';
import 'PlaylistScreen.dart';
import '../api/TokenStorage.dart';
import 'FavoritesScreen.dart';
import 'package:google_fonts/google_fonts.dart';

// Mood Selection Screen
class MoodSelectionScreen extends StatefulWidget {
  const MoodSelectionScreen({Key? key}) : super(key: key);

  @override
  State<MoodSelectionScreen> createState() => _MoodSelectionScreenState();
}

class _MoodSelectionScreenState extends State<MoodSelectionScreen> {
  String? selectedMood;
  bool isUserAuthenticated = false;
  double _headerHeight = 0;

  @override
  void initState() {
    super.initState();

    // Check Spotify authentication status
    setState(() {
      isUserAuthenticated = SpotifyAuth().isAuthenticated();
    });

    authStateController.stream.listen((token) {
      setState(() {
        isUserAuthenticated = token != null;
      });
    });

    // Animate the header height
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _headerHeight = 157;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final italicHeaderStyle = GoogleFonts.playfairDisplay(
      fontSize: 30,
      color: Colors.white,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Playlist App'),
        backgroundColor: const Color.fromARGB(255, 29, 1, 76),
      ),
      backgroundColor: Colors.blueAccent[100],
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 103, 58, 183),
              Color.fromARGB(255, 29, 1, 76),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Animated header
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              height: _headerHeight,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 29, 1, 76),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Center(
                child: Text(
                  "How are you feeling?",
                  style: italicHeaderStyle,
                ),
              ),
            ),

            const SizedBox(height: 158),

            // Mood selection dropdown
            DropdownButton<String>(
              value: selectedMood,
              hint: const Text(
                "Select your mood",
                style: TextStyle(color: Colors.white),
              ),
              dropdownColor: const Color.fromARGB(255, 29, 1, 76),
              style: const TextStyle(color: Colors.white),
              underline: Container(
                height: 1.5,
                color: Colors.white70,
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              items: const [
                DropdownMenuItem(value: "Happy", child: Text("Happy")),
                DropdownMenuItem(value: "Sad", child: Text("Sad")),
                DropdownMenuItem(value: "Party", child: Text("Party")),
                DropdownMenuItem(value: "Chill", child: Text("Chill")),
              ],
              onChanged: (value) {
                setState(() {
                  selectedMood = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // Find Playlist button
            ElevatedButton(
              onPressed: selectedMood != null
                  ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistScreen(mood: value),
                  ),
                );
              }
                  : null,
              child: const Text('Find Playlist'),
            ),

            const SizedBox(height: 20),

            // Go to Favorites button
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavoritesScreen(),
                  ),
                );
              },
              child: const Text('Go to Favorites'),
            ),

            const SizedBox(height: 50),

            // Spotify Authentication button
            ElevatedButton(
              onPressed: isUserAuthenticated
                  ? null
                  : () => SpotifyAuth().authenticateWithSpotify(),
              child: Text(isUserAuthenticated
                  ? 'Connected to Spotify'
                  : 'Connect to Spotify'),
            ),
          ],
        ),
      ),
    );
  }
}

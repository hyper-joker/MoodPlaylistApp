// MoodSelectionScreen.dart
import 'package:flutter/material.dart';
import '../api/AuthURL.dart';
import '../api/TokenStorage.dart';

class MoodSelectionScreen extends StatefulWidget {
  const MoodSelectionScreen({Key? key}) : super(key: key);

  @override
  State<MoodSelectionScreen> createState() => _MoodSelectionScreenState();
}

class _MoodSelectionScreenState extends State<MoodSelectionScreen> {
  String? selectedMood;
  bool isUserAuthenticated = false;

  @override
  void initState() {
    super.initState();

    setState(() {
      isUserAuthenticated = SpotifyAuth().isAuthenticated();
    });

    authStateController.stream.listen((token) {
      setState(() {
        isUserAuthenticated = token != null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Playlist App')),
      backgroundColor: Colors.blueAccent[100],
      body: Column(
        children: [
          Container(
            height: 157,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 0, 24, 67),
            ),
            child: const Center(
              child: Text(
                "How are you feeling?",
                style: TextStyle(fontSize: 26, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 158),
          DropdownButton<String>(
            value: selectedMood,
            hint: const Text("Select your mood"),
            items: const [
              DropdownMenuItem(value: "Happy", child: Text("Happy")),
              DropdownMenuItem(value: "Sad", child: Text("Sad")),
              DropdownMenuItem(value: "Hopeful", child: Text("Hopeful")),
              DropdownMenuItem(value: "Angry", child: Text("Angry")),
            ],
            onChanged: (value) {
              setState(() {
                selectedMood = value;
              });
            },
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: isUserAuthenticated
                ? null
                : () => SpotifyAuth().authenticateWithSpotify(),
            child: Text(isUserAuthenticated ? 'Connected to Spotify' : 'Connect to Spotify'),
          ),
        ],
      ),
    );
  }
}
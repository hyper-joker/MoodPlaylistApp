import 'package:flutter/material.dart';

void main() => runApp(const MoodPlaylistApp());

class MoodPlaylistApp extends StatelessWidget {
  const MoodPlaylistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood based playlist',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const MoodSelectionScreen(),
    );
  }
}

class MoodSelectionScreen extends StatefulWidget {
  const MoodSelectionScreen({Key? key}) : super(key: key);

  @override
  State<MoodSelectionScreen> createState() => _MoodSelectionScreen();
}

class _MoodSelectionScreen extends State<MoodSelectionScreen> {
  String? selectedMood;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent[100],
      body: Column(
        children: [
          Container(
            height: 157,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 0, 24, 67),
            ),
            child: Center(
              child: Text(
                "How are you feeling?",
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                ),
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
        ],
      ),
    );
  }
}

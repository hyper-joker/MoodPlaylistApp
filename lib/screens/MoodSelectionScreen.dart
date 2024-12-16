import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './PlaylistScreen.dart';

// Mood Selection Screen
class MoodSelectionScreen extends StatefulWidget {
  const MoodSelectionScreen({Key? key}) : super(key: key);

  @override
  State<MoodSelectionScreen> createState() => _MoodSelectionScreenState();
}

class _MoodSelectionScreenState extends State<MoodSelectionScreen> {
  String? selectedMood;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

              if (value != null) {
                // Navigate to the playlist screen with the selected mood
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistScreen(mood: value),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
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
  double _headerHeight = 0;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _headerHeight = 157;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              hint: const Text("Select your mood",
                  style: TextStyle(color: Colors.white)),
              dropdownColor: Color.fromARGB(255, 29, 1, 76),
              style: const TextStyle(color: Colors.white),
              underline: Container(
                height: 1.5,
                color: Colors.white70,
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
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
      ),
    );
  }
}

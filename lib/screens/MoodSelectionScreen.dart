import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../api/AuthURL.dart';
import '../api/TokenStorage.dart';
import 'PlaylistScreen.dart';
import 'FavoritesScreen.dart';

class MoodSelectionScreen extends StatefulWidget {
  const MoodSelectionScreen({Key? key}) : super(key: key);

  @override
  State<MoodSelectionScreen> createState() => _MoodSelectionScreenState();
}

class _MoodSelectionScreenState extends State<MoodSelectionScreen> {
  String? selectedMood;
  bool isUserAuthenticated = false;
  double _headerHeight = 0;

  final List<Map<String, dynamic>> moodOptions = const [
    {"value": "Happy", "icon": Icons.sentiment_very_satisfied},
    {"value": "Sad", "icon": Icons.sentiment_very_dissatisfied},
    {"value": "Party", "icon": Icons.celebration},
    {"value": "Chill", "icon": Icons.cloud},
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
    _animateHeader();
  }

  void _checkAuthenticationStatus() {
    setState(() {
      isUserAuthenticated = SpotifyAuth().isAuthenticated();
    });

    authStateController.stream.listen((token) {
      if (mounted) {
        setState(() {
          isUserAuthenticated = token != null;
        });
      }
    });
  }

  void _animateHeader() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _headerHeight = 157;
        });
      }
    });
  }

  void _navigateToPlaylist() {
    if (selectedMood != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlaylistScreen(mood: selectedMood!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final italicHeaderStyle = GoogleFonts.playfairDisplay(
      fontSize: 30,
      color: Colors.white,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Playlist App'),
        backgroundColor: const Color.fromARGB(255, 29, 1, 76),
      ),
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
            _buildAnimatedHeader(italicHeaderStyle),
            const SizedBox(height: 100),
            _buildMoodDropdown(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader(TextStyle headerStyle) {
    return AnimatedContainer(
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
          style: headerStyle,
        ),
      ),
    );
  }

  Widget _buildMoodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DropdownButton<String>(
        value: selectedMood,
        hint: const Text(
          "Select your mood",
          style: TextStyle(color: Colors.white),
        ),
        isExpanded: true,
        dropdownColor: const Color.fromARGB(255, 29, 1, 76),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        underline: Container(
          height: 1.5,
          color: Colors.white70,
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
        items: moodOptions.map((mood) {
          return DropdownMenuItem<String>(
            value: mood['value'],
            child: Row(
              children: [
                Icon(mood['icon'] as IconData, color: Colors.white),
                const SizedBox(width: 10),
                Text(mood['value']),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            selectedMood = value;
          });
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 29, 1, 76),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          onPressed: selectedMood != null ? _navigateToPlaylist : null,
          child: const Text('Find Playlist'),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 29, 1, 76),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
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
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isUserAuthenticated
                ? Colors.grey
                : const Color.fromARGB(255, 29, 1, 76),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          ),
          onPressed: isUserAuthenticated
              ? null
              : () => SpotifyAuth().authenticateWithSpotify(),
          child: Text(
            isUserAuthenticated ? 'Connected to Spotify' : 'Connect to Spotify',
          ),
        ),
      ],
    );
  }
}
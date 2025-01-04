import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<dynamic> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites(); // Load favorites from SharedPreferences
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();

    // Fetch favorites from SharedPreferences
    final String? favoritesString = prefs.getString('favorites');
    setState(() {
      _favorites = favoritesString != null ? jsonDecode(favoritesString) : [];
    });
  }

  Future<void> _removeFromFavorites(String name) async {
    final prefs = await SharedPreferences.getInstance();

    // Remove favorite by name
    setState(() {
      _favorites.removeWhere((item) => item['name'] == name);
    });

    // Save the updated list back to SharedPreferences
    await prefs.setString('favorites', jsonEncode(_favorites));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Removed from Favorites!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFB0E0E6),
              Color(0xFF4682B4),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: _favorites.isEmpty
            ? const Center(child: Text("No favorites added yet!"))
            : ListView.builder(
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  final favorite = _favorites[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    color: Colors.white38,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    child: ListTile(
                      title: Text(favorite['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black26,
                              ),
                            ],
                          )),
                      subtitle: Text(
                        'Mood: ${favorite['mood']}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () {
                          _removeFromFavorites(favorite['name']);
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

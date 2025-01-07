import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Removed from Favorites!"),
      backgroundColor: Color.fromARGB(255, 29, 1, 76),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Favorites',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 29, 1, 76),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 103, 58, 183),
              Color.fromARGB(255, 29, 1, 76),
              Color.fromARGB(255, 29, 1, 76),
              Color.fromARGB(255, 103, 58, 183),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: _favorites.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        color: Colors.white, size: 50),
                    SizedBox(height: 20),
                    Text(
                      "No favorites added yet!",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: _favorites.length,
                itemBuilder: (context, index) {
                  final favorite = _favorites[index];
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    color: Colors.white12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    child: ListTile(
                      title: Text(favorite['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          )),
                      subtitle: Text(
                        'Mood: ${favorite['mood']}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white70),
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

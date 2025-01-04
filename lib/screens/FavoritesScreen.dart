//FavoritesScreen.dart
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removed from Favorites!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: _favorites.isEmpty
          ? const Center(child: Text("No favorites added yet!"))
          : ListView.builder(
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final favorite = _favorites[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(favorite['name']),
              subtitle: Text('Mood: ${favorite['mood']}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  _removeFromFavorites(favorite['name']);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

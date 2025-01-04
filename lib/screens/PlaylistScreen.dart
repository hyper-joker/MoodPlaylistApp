import 'package:flutter/material.dart';
import '../api/AuthURL.dart';

class PlaylistScreen extends StatefulWidget {
  final String mood;

  const PlaylistScreen({Key? key, required this.mood}) : super(key: key);

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<Map<String, String>> _tracks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPlaylist();
  }

  Future<void> _fetchPlaylist() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Search for a playlist by mood
      final playlist = await SpotifyAuth().searchPlaylist(widget.mood);
      if (playlist != null) {
        final playlistId = playlist['id'];

        // Fetch the tracks from the playlist
        final tracks = await SpotifyAuth().getPlaylistTracks(playlistId);

        setState(() {
          _tracks = tracks;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _tracks = [];
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching playlist or tracks: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.mood} Playlist'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
          ? const Center(child: Text("No playlist found for this mood!"))
          : ListView.builder(
        itemCount: _tracks.length,
        itemBuilder: (context, index) {
          final track = _tracks[index];
          return ListTile(
            title: Text(track['name']!),
            subtitle: Text(track['artist']!),
          );
        },
      ),
    );
  }
}

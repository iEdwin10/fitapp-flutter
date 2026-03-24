import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/playlist.dart';
import '../services/difficulty_service.dart';
import '../services/freemium_service.dart';

class PlaylistProvider extends ChangeNotifier {
  List<Playlist> _playlists = [];

  List<Playlist> get playlists => List.unmodifiable(_playlists);
  List<Playlist> get miniPlaylists => _playlists.where((p) => p.type == PlaylistType.mini).toList();
  List<Playlist> get standardPlaylists => _playlists.where((p) => p.type == PlaylistType.standard).toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('playlists');
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      _playlists = list.map((j) => Playlist.fromJson(j)).toList();
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playlists', jsonEncode(_playlists.map((p) => p.toJson()).toList()));
  }

  bool addPlaylist(Playlist p) {
    if (p.type == PlaylistType.mini && !FreemiumService.canCreateMiniPlaylist(miniPlaylists.length)) return false;
    final score = DifficultyService.compute(p);
    final withScore = Playlist(
      id: p.id, name: p.name, type: p.type, blocks: p.blocks,
      warmupPlaylistId: p.warmupPlaylistId,
      difficultyScore: score, createdAt: p.createdAt);
    _playlists.add(withScore);
    _save();
    notifyListeners();
    return true;
  }

  void deletePlaylist(String id) {
    _playlists.removeWhere((p) => p.id == id);
    _save();
    notifyListeners();
  }

  void updatePlaylist(Playlist updated) {
    final idx = _playlists.indexWhere((p) => p.id == updated.id);
    if (idx >= 0) {
      final score = DifficultyService.compute(updated);
      _playlists[idx] = Playlist(
        id: updated.id, name: updated.name, type: updated.type,
        blocks: updated.blocks, warmupPlaylistId: updated.warmupPlaylistId,
        difficultyScore: score, createdAt: updated.createdAt);
      _save();
      notifyListeners();
    }
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class FreemiumService {
  static const int maxExercisesFree      = 10;
  static const int maxExercisesPremium   = 25;
  static const int maxMiniPlaylistsFree  = 1;
  static const int maxCustomExercisesFree = 3;

  static bool _isPremium = false;
  static bool get isPremium => _isPremium;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('is_premium') ?? false;
  }

  static int get maxExercisesPerPlaylist =>
      _isPremium ? maxExercisesPremium : maxExercisesFree;

  static bool canAddExercise(int current) => current < maxExercisesPerPlaylist;
  static bool canCreateMiniPlaylist(int current) => _isPremium || current < maxMiniPlaylistsFree;
  static bool canAddCustomExercise(int current) => _isPremium || current < maxCustomExercisesFree;
}

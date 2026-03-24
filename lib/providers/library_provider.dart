import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import '../data/exercise_library.dart';
import '../services/freemium_service.dart';

class LibraryProvider extends ChangeNotifier {
  List<Exercise> _exercises = List.from(seedExercises);

  List<Exercise> get exercises => List.unmodifiable(_exercises);
  List<Exercise> get customExercises => _exercises.where((e) => e.isCustom).toList();

  Exercise? findById(String id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return _exercises.isNotEmpty ? _exercises.first : null;
    }
  }

  bool addCustomExercise(Exercise e) {
    if (!FreemiumService.canAddCustomExercise(customExercises.length)) return false;
    _exercises.add(e);
    notifyListeners();
    return true;
  }

  List<Exercise> search(String query) => _exercises
      .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
      .toList();
}

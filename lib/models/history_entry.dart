class HistoryEntry {
  final String id;
  final String playlistId;
  final String playlistName;
  final DateTime startedAt;
  final int durationSeconds;
  final int exercisesCompleted;
  final List<SetRecord> sets;

  const HistoryEntry({
    required this.id,
    required this.playlistId,
    required this.playlistName,
    required this.startedAt,
    required this.durationSeconds,
    required this.exercisesCompleted,
    required this.sets,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'playlistId': playlistId,
    'playlistName': playlistName,
    'startedAt': startedAt.toIso8601String(),
    'durationSeconds': durationSeconds,
    'exercisesCompleted': exercisesCompleted,
    'sets': sets.map((s) => s.toJson()).toList(),
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
    id: j['id'],
    playlistId: j['playlistId'],
    playlistName: j['playlistName'],
    startedAt: DateTime.parse(j['startedAt']),
    durationSeconds: j['durationSeconds'],
    exercisesCompleted: j['exercisesCompleted'],
    sets: (j['sets'] as List).map((s) => SetRecord.fromJson(s)).toList(),
  );
}

class SetRecord {
  final String exerciseId;
  final int reps;
  final double? weight;
  final DateTime performedAt;

  const SetRecord({
    required this.exerciseId,
    required this.reps,
    this.weight,
    required this.performedAt,
  });

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'reps': reps,
    'weight': weight,
    'performedAt': performedAt.toIso8601String(),
  };

  factory SetRecord.fromJson(Map<String, dynamic> j) => SetRecord(
    exerciseId: j['exerciseId'],
    reps: j['reps'],
    weight: (j['weight'] as num?)?.toDouble(),
    performedAt: DateTime.parse(j['performedAt']),
  );
}

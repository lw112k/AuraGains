class WorkoutLog {
  final int workoutLogId;
  final int set;
  final int reps;
  final double weight; // numeric in DB
  final int workoutId;
  final String userId; // uuid in DB

  WorkoutLog({
    required this.workoutLogId,
    required this.set,
    required this.reps,
    required this.weight,
    required this.workoutId,
    required this.userId,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) {
    return WorkoutLog(
      workoutLogId: json['workout_log_id'],
      set: json['set'],
      reps: json['reps'],
      weight: (json['weight'] as num).toDouble(),
      workoutId: json['workout_id'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() => {
        'workout_log_id': workoutLogId,
        'set': set,
        'reps': reps,
        'weight': weight,
        'workout_id': workoutId,
        'user_id': userId,
      };
}

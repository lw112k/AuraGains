

// --- workout_model.dart ---
import 'package:auragains/features/workout_management/models/equipment_model.dart';
import 'package:auragains/features/workout_management/models/target_muscle_model.dart';

class Workout {
  final int workoutId;
  final String workoutName;
  final int? equipId; 
  
  // Relational data useful for the UI
  final Equipment? equipment;
  final List<TargetMuscle>? targetMuscles;

  Workout({
    required this.workoutId,
    required this.workoutName,
    this.equipId,
    this.equipment,
    this.targetMuscles,
  });

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      workoutId: json['workout_id'],
      workoutName: json['workout_name'],
      equipId: json['equip_id'],
      // Assuming nested JSON objects if using joins in your backend (like Supabase or a REST API)
      equipment: json['equipment'] != null ? Equipment.fromJson(json['equipment']) : null,
      targetMuscles: json['target_muscles'] != null 
          ? (json['target_muscles'] as List).map((i) => TargetMuscle.fromJson(i)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'workout_id': workoutId,
        'workout_name': workoutName,
        'equip_id': equipId,
      };
}

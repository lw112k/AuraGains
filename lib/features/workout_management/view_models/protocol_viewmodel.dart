import 'package:flutter/material.dart';

// ==========================================
// 🗄️ DATABASE MODELS
// ==========================================
class Exercise {
  final String id;
  final String name;
  final String targetMuscle;
  Exercise({required this.id, required this.name, required this.targetMuscle});
}

class TargetMuscle {
  final String id;
  final String name;
  TargetMuscle({required this.id, required this.name});
}

class WorkoutLevel {
  final String id;
  final String name;
  WorkoutLevel({required this.id, required this.name});
}

// ==========================================
// 🧠 PROTOCOL VIEW MODEL (DATABASE LOGIC)
// ==========================================
class ProtocolViewModel extends ChangeNotifier {
  bool isLoading = false;

  List<TargetMuscle> muscles = [];
  List<WorkoutLevel> levels = [];
  List<Exercise> availableExercises = [];

  // Simulate fetching from `target_muscle` and `level` tables
  Future<void> fetchDropdownData() async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network

    muscles = [
      TargetMuscle(id: 'm1', name: 'Chest'),
      TargetMuscle(id: 'm2', name: 'Back'),
      TargetMuscle(id: 'm3', name: 'Legs'),
      TargetMuscle(id: 'm4', name: 'Core'),
      TargetMuscle(id: 'm5', name: 'Full Body'),
    ];

    levels = [
      WorkoutLevel(id: 'l1', name: 'Beginner'),
      WorkoutLevel(id: 'l2', name: 'Intermediate'),
      WorkoutLevel(id: 'l3', name: 'Advanced'),
      WorkoutLevel(id: 'l4', name: 'Pro'),
    ];

    isLoading = false;
    notifyListeners();
  }

  // Simulate fetching from `workout` table
  Future<void> fetchExercises() async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network

    availableExercises = [
      Exercise(id: 'w1', name: 'Barbell Bench Press', targetMuscle: 'Chest'),
      Exercise(id: 'w2', name: 'Squat', targetMuscle: 'Legs'),
      Exercise(id: 'w3', name: 'Deadlift', targetMuscle: 'Back'),
      Exercise(id: 'w4', name: 'Overhead Press', targetMuscle: 'Shoulders'),
      Exercise(id: 'w5', name: 'Bicep Curl', targetMuscle: 'Arms'),
      Exercise(id: 'w6', name: 'Leg Extension', targetMuscle: 'Legs'),
    ];

    isLoading = false;
    notifyListeners();
  }

  // Simulate saving to `training_protocol` table
  Future<bool> saveProtocol({
    required String name,
    required String targetMuscleId,
    required String levelId,
    required List<Exercise> selectedExercises,
  }) async {
    isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // Simulate network saving

    print("✅ SAVED TO training_protocol TABLE:");
    print("Protocol Name: $name");
    print("Muscle ID: $targetMuscleId");
    print("Level ID: $levelId");
    print("Total Exercises: ${selectedExercises.length}");

    isLoading = false;
    notifyListeners();
    return true; // Success
  }
}

// --- target_muscle_model.dart ---
class TargetMuscle {
  final int tarMuscId;
  final String name;

  TargetMuscle({required this.tarMuscId, required this.name});

  factory TargetMuscle.fromJson(Map<String, dynamic> json) {
    return TargetMuscle(
      tarMuscId: json['tar_musc_id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'tar_musc_id': tarMuscId,
        'name': name,
      };
}
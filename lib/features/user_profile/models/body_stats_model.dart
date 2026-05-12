class BodyStatsModel {
  final int bodyStatusId;
  final double heightCm;
  final double weightKg;
  final String heightFtIn;
  final double weightLbs;
  final String unitSystem;
  final String visibility;

  BodyStatsModel({
    required this.bodyStatusId,
    required this.heightCm,
    required this.weightKg,
    required this.heightFtIn,
    required this.weightLbs,
    required this.unitSystem,
    required this.visibility,
  });

  factory BodyStatsModel.fromJson(Map<String, dynamic> json) {
    return BodyStatsModel(
      // Handle BIGINT safely
      bodyStatusId: json['body_status_id'] is int
          ? json['body_status_id']
          : int.tryParse(json['body_status_id'].toString()) ?? 0,

      // Handle NUMERIC safely using .toDouble()
      heightCm: (json['height_cm'] ?? 0).toDouble(),
      weightKg: (json['weight_kg'] ?? 0).toDouble(),
      weightLbs: (json['weight_lbs'] ?? 0).toDouble(),

      heightFtIn: json['height_ft_in'] ?? "0'0\"",
      unitSystem:
          json['unit_system'] ?? 'cm/kg', // 💡 Default fallback as requested
      visibility: json['visibility'] ?? 'public',
    );
  }
}

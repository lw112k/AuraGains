class ChallengeModel {
  final int challId;
  final String name;
  final String description;
  final int pointReward;
  final bool isDaily;
  final bool isActive; 
  final bool isCompleted; 

  ChallengeModel({
    required this.challId,
    required this.name,
    required this.description,
    required this.pointReward,
    required this.isDaily,
    required this.isActive,
    required this.isCompleted,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      challId: json['chall_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      pointReward: json['point_reward'] ?? 0,
      isDaily: json['is_daily'] ?? true,
      isActive: json['is_active'] ?? true,
      isCompleted: json['is_completed'] ?? false,
    );
  }
}

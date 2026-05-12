class LevelModel {
  final int levelId;
  final String name;
  final String description;

  LevelModel({
    required this.levelId,
    required this.name,
    required this.description,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      levelId: json['level_id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

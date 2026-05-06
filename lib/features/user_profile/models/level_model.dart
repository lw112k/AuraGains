class LevelModel {
  final String id;
  final String name;
  final int minPoints;
  final String badgeColor;

  LevelModel({
    required this.id,
    required this.name,
    required this.minPoints,
    required this.badgeColor,
  });

  factory LevelModel.fromJson(Map<String, dynamic> json) {
    return LevelModel(
      id: json['id'] as String,
      name: json['name'] as String,
      minPoints: json['min_points'] as int,
      badgeColor: json['badge_color'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'min_points': minPoints,
      'badge_color': badgeColor,
    };
  }
}
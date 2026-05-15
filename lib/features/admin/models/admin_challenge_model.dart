// =====================================================================
// ADMIN CHALLENGE MODEL
// Maps to the `challenge` table.
// Schema: chall_id, name, description, point_reward, create_date,
//         is_daily, is_active
// =====================================================================

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  if (v is String) {
    final i = int.tryParse(v);
    if (i != null) return i;
    final d = double.tryParse(v);
    if (d != null) return d.toInt();
  }
  return null;
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is double) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  return null;
}

class AdminChallengeModel {
  final int challId;
  final String name;
  final String description;
  final int pointReward;
  final DateTime? createDate;
  final bool isDaily;
  final bool isActive;

  const AdminChallengeModel({
    required this.challId,
    required this.name,
    required this.description,
    required this.pointReward,
    this.createDate,
    required this.isDaily,
    required this.isActive,
  });

  factory AdminChallengeModel.fromJson(Map<String, dynamic> json) {
    return AdminChallengeModel(
      challId: _toInt(json['chall_id']) ??
          (throw ArgumentError('Missing required field: chall_id')),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      pointReward: _toInt(json['point_reward']) ?? 0,
      createDate: _toDate(json['create_date']),
      isDaily: json['is_daily'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'point_reward': pointReward,
        'is_daily': isDaily,
        'is_active': isActive,
      };

  AdminChallengeModel copyWith({
    int? challId,
    String? name,
    String? description,
    int? pointReward,
    DateTime? createDate,
    bool? isDaily,
    bool? isActive,
  }) =>
      AdminChallengeModel(
        challId: challId ?? this.challId,
        name: name ?? this.name,
        description: description ?? this.description,
        pointReward: pointReward ?? this.pointReward,
        createDate: createDate ?? this.createDate,
        isDaily: isDaily ?? this.isDaily,
        isActive: isActive ?? this.isActive,
      );
}

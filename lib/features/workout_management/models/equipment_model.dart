// --- equipment_model.dart ---
class Equipment {
  final int equipId;
  final String name;

  Equipment({required this.equipId, required this.name});

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      equipId: json['equip_id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() => {
        'equip_id': equipId,
        'name': name,
      };
}

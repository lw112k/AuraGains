class TagModel {
  final int tagId;
  final String name;
  final String tagType;

  TagModel({
    required this.tagId,
    required this.name,
    required this.tagType,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      tagId: json['tag_id'],
      name: json['name'],
      tagType: json['tag_type'],
    );
  }
}
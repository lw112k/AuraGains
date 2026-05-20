class SearchTagModel {
  final int tagId;
  final String name;
  final String type;

  SearchTagModel({
    required this.tagId,
    required this.name,
    required this.type,
  });

  factory SearchTagModel.fromJson(Map<String, dynamic> json) {
    return SearchTagModel(
      tagId: json['tag_id'] is int 
          ? json['tag_id'] 
          : int.tryParse(json['tag_id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['tag_type']?.toString() ?? 'system',
    );
  }
}
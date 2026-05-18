class PostMediaModel {
  final int mediaId;
  final String mediaUrl;
  final String mediaType;
  final int displayOrder;

  PostMediaModel({
    required this.mediaId,
    required this.mediaUrl,
    required this.mediaType,
    required this.displayOrder,
  });

  factory PostMediaModel.fromJson(Map<String, dynamic> json) {
    return PostMediaModel(
      mediaId: json['media_id'],
      mediaUrl: json['media_url'],
      mediaType: json['media_type'],
      displayOrder: json['display_order'],
    );
  }
}
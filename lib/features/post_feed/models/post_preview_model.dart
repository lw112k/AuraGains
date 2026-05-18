class PostPreviewModel {
  final int postId;
  final String title;
  final String? thumbnailUrl;
  final String? firstMediaUrl;
  final String? firstMediaType;

  final String creatorId;
  final String creatorUsername;
  final String? creatorProfileUrl;

  final int likeCount;
  final DateTime createDate;

  PostPreviewModel({
    required this.postId,
    required this.title,
    required this.thumbnailUrl,
    required this.firstMediaUrl,
    required this.firstMediaType,
    required this.creatorId,
    required this.creatorUsername,
    required this.creatorProfileUrl,
    required this.likeCount,
    required this.createDate,
  });

  factory PostPreviewModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return PostPreviewModel(
      postId: json['post_id'],
      title: json['title'],
      thumbnailUrl: json['thumbnail_url'],
      firstMediaUrl: json['first_media_url'],
      firstMediaType: json['first_media_type'],
      creatorId: json['creator_id'],
      creatorUsername: json['creator_username'],
      creatorProfileUrl: json['creator_profile_url'],
      likeCount: json['post_like'] ?? 0,
      createDate: DateTime.parse(json['create_date']),
    );
  }
}
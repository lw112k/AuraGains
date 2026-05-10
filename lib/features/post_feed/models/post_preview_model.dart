class PostPreviewModel {
  final int postId;
  final String title;
  final String? thumbnailUrl;

  final String creatorUsername;
  final String? creatorProfileUrl;

  final int likeCount;
  final DateTime createDate;

  PostPreviewModel({
    required this.postId,
    required this.title,
    required this.thumbnailUrl,
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
      creatorUsername: json['creator_username'],
      creatorProfileUrl: json['creator_profile_url'],
      likeCount: json['post_like'] ?? 0,
      createDate: DateTime.parse(json['create_date']),
    );
  }
}
// Path: AuraGains/lib/features/post_feed/models/post_model.dart

class PostDetailModel {
  final int postId;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String postType;
  final String visibility;
  final int likeCount;
  final DateTime createDate;

  final String creatorId;
  final String creatorUsername;
  final String? creatorProfilePicUrl;

  final List<PostMediaModel> mediaList;
  final List<TagModel> tags;

  final bool isLiked;
  final bool isSaved;

  PostDetailModel({
    required this.postId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.postType,
    required this.visibility,
    required this.likeCount,
    required this.createDate,
    required this.creatorId,
    required this.creatorUsername,
    required this.creatorProfilePicUrl,
    required this.mediaList,
    required this.tags,
    required this.isLiked,
    required this.isSaved,
  });

  factory PostDetailModel.fromJson(Map<String, dynamic> json) {
    return PostDetailModel(
      postId: json['post_id'],
      title: json['title'],
      description: json['description'],
      thumbnailUrl: json['thumbnail_url'],
      postType: json['post_type'],
      visibility: json['visibility'],
      likeCount: json['post_like'] ?? 0,
      createDate: DateTime.parse(json['create_date']),

      creatorId: json['user']['user_id'],
      creatorUsername: json['user']['username'],
      creatorProfilePicUrl: json['user']['profile_pic_url'],

      mediaList: (json['post_media'] as List<dynamic>? ?? [])
          .map((e) => PostMediaModel.fromJson(e))
          .toList(),

      tags: (json['post_tag'] as List<dynamic>? ?? [])
          .map((e) => TagModel.fromJson(e['tag']))
          .toList(),

      isLiked: json['is_liked'] ?? false,
      isSaved: json['is_saved'] ?? false,
    );
  }
  
}
import 'package:auragains/features/post_feed/models/post_media_model.dart';
import 'package:auragains/features/post_feed/models/tag_model.dart';

class PostDetailModel {
  final int postId;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String postType;
  final String visibility;
  int likeCount;
  final DateTime createDate;

  final String creatorId;
  final String creatorUsername;
  final String? creatorProfileUrl;

  final List<PostMediaModel> mediaList;
  final List<TagModel> tagList;

  int totalComment;
  int totalSave;

  bool isLiked;
  bool isSaved;

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
    required this.creatorProfileUrl,
    required this.mediaList,
    required this.tagList,
    required this.totalComment,
    required this.totalSave,
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

      creatorId: json['creator_id'],
      creatorUsername: json['creator_username'],
      creatorProfileUrl: json['creator_profile_url'],

      mediaList: (json['post_media'] as List<dynamic>? ?? [])
          .map((e) => PostMediaModel.fromJson(e))
          .toList(),

      tagList: (json['post_tag'] as List<dynamic>? ?? [])
          .map((e) => TagModel.fromJson(e['tag']))
          .toList(),

      totalComment: json['total_comment'] ?? 0,
      totalSave: json['total_save'] ?? 0,

      isLiked: json['is_liked'] ?? false,
      isSaved: json['is_saved'] ?? false,
    );
  }
  
}
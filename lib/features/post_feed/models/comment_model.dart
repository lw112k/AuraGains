class CommentModel {
  final int commentId;
  final int postId;
  final String userId;
  final String username;
  final String? profilePicUrl;
  final bool isExpert;

  final String text;
  int likeCount;
  int replyCount;
  final DateTime createDate;

  final int? parentId;

  final List<CommentModel> replies;

  bool repliesLoaded;
  bool showReplies;
  bool isLiked;

  CommentModel({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.username,
    required this.profilePicUrl,
    required this.isExpert,
    required this.text,
    required this.likeCount,
    required this.replyCount,
    required this.createDate,
    required this.parentId,
    required this.replies,
    this.repliesLoaded = false,
    this.showReplies = false,
    this.isLiked = false,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {

    return CommentModel(
      commentId: json['comment_id'],
      postId: json['post_id'],

      userId: json['user_id'],
      username: json['username'],
      profilePicUrl: json['profile_pic_url'],
      isExpert: json['is_expert'] ?? false,
      text: json['text'],

      likeCount: json['comment_like'] ?? 0,
      replyCount: json['reply_count'] ?? 0,

      createDate: DateTime.parse('${json['create_date']}Z').toLocal(),

      parentId: json['parent_id'],

      replies:
          (json['replies'] as List<dynamic>? ?? [])
              .map((e) => CommentModel.fromJson(e))
              .toList()
    );
  }
}
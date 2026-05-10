class CommentModel {
  final int commentId;
  final int postId;
  final String userId;
  final String username;
  final String? profilePicUrl;

  final String text;
  final int likeCount;
  final DateTime createDate;

  final int? parentId;

  CommentModel({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.username,
    required this.profilePicUrl,
    required this.text,
    required this.likeCount,
    required this.createDate,
    required this.parentId,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      commentId: json['comment_id'],
      postId: json['post_id'],
      userId: json['user_id'],
      username: json['username'],
      profilePicUrl: json['profile_pic_url'],
      text: json['text'],
      likeCount: json['comment_like'] ?? 0,
      createDate: DateTime.parse(json['create_date']),
      parentId: json['parent_id'],
    );
  }
}
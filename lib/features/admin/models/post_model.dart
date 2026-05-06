/// Post model for the admin feature — maps to the `posts` table.
///
/// DB schema: id, user_id, title, description, media_urls (array),
///            category, tags (array), audience, likes_count,
///            comments_count, saves_count, created_at
///
/// TEAM NOTE: The `posts` table has no `shares_count` column in the
/// current schema. The prototype's `post.shares` field has been omitted.
/// If shares tracking is added later, add `sharesCount` here and in the DB.
///
/// NOTE: The prototype used `post.imageUrl` and `post.caption` — these map
/// to `media_urls[0]` (first URL) and `description` respectively.
class PostModel {
  const PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.mediaUrls,
    required this.category,
    required this.tags,
    required this.audience,
    required this.likesCount,
    required this.commentsCount,
    required this.savesCount,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  /// Maps to `description` in the DB — used as the caption in the UI.
  final String description;
  /// Maps to `media_urls` array — first element used as the preview image.
  final List<String> mediaUrls;
  final String category;
  final List<String> tags;
  final String audience;
  final int likesCount;
  final int commentsCount;
  final int savesCount;
  final DateTime createdAt;

  /// Convenience getter: first media URL, or empty string if none.
  String get imageUrl => mediaUrls.isNotEmpty ? mediaUrls.first : '';

  /// Convenience alias matching the prototype's field name.
  String get caption => description;

  factory PostModel.fromSupabase(Map<String, dynamic> row) {
    // media_urls comes back as List<dynamic> from Supabase
    final rawUrls = row['media_urls'];
    final urls = rawUrls is List
        ? rawUrls.map((e) => e.toString()).toList()
        : <String>[];

    final rawTags = row['tags'];
    final tags = rawTags is List
        ? rawTags.map((e) => e.toString()).toList()
        : <String>[];

    return PostModel(
      id: row['id'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      title: row['title'] as String? ?? '',
      description: row['description'] as String? ?? '',
      mediaUrls: urls,
      category: row['category'] as String? ?? '',
      tags: tags,
      audience: row['audience'] as String? ?? '',
      likesCount: (row['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (row['comments_count'] as num?)?.toInt() ?? 0,
      savesCount: (row['saves_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

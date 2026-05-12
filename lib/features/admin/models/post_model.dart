/// Admin post model — maps to the `post` table.
///
/// DB column names used by the team's Supabase schema:
///   post_id, post_by (user FK), title, description,
///   thumbnail_url, post_type, create_date
///
/// Named [AdminPost] to avoid ambiguity with any future user-facing model.
class AdminPost {
  const AdminPost({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.postType,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String postType;
  final DateTime createdAt;

  factory AdminPost.fromSupabase(Map<String, dynamic> row) {
    return AdminPost(
      id: (row['post_id'] ?? '').toString(),
      userId: (row['post_by'] ?? row['user_id'] ?? '').toString(),
      title: row['title'] as String? ?? '(No title)',
      description: row['description'] as String? ?? '',
      thumbnailUrl: row['thumbnail_url'] as String? ?? '',
      postType: row['post_type'] as String? ?? '',
      createdAt: DateTime.tryParse(
              (row['create_date'] ?? row['created_at']) as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  String toString() => 'AdminPost(id: $id, title: $title)';
}

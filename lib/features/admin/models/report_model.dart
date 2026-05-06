/// Moderation report model — maps to the `reports` table.
///
/// DB schema: id, reporter_id, post_id, reason, status, created_at
/// The [fromSupabase] factory handles the joined reporter user fields
/// returned when the query includes `reporter:reporter_id(id, username, avatar_url)`.
class Report {
  const Report({
    required this.id,
    required this.postId,
    required this.reporterId,
    required this.reason,
    required this.status,
    required this.reportedAt,
    this.reporterUsername = '',
    this.reporterAvatar = '',
  });

  final String id;
  /// `post_id` from the DB — the flagged post.
  final String postId;
  /// `reporter_id` from the DB.
  final String reporterId;
  final String reason;
  final String status;
  final DateTime reportedAt;
  // Populated via JOIN `reporter:reporter_id(id, username, avatar_url)`
  final String reporterUsername;
  final String reporterAvatar;

  /// Convenience alias used by existing UI widgets.
  String get contentId => postId;

  /// Builds a Report from a Supabase row that includes the reporter join.
  factory Report.fromSupabase(Map<String, dynamic> row) {
    final reporter = row['reporter'] as Map<String, dynamic>?;
    return Report(
      id: row['id'] as String? ?? '',
      postId: row['post_id'] as String? ?? '',
      reporterId: row['reporter_id'] as String? ?? '',
      reason: row['reason'] as String? ?? '',
      status: row['status'] as String? ?? 'pending',
      reportedAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      reporterUsername: reporter?['username'] as String? ?? 'unknown',
      reporterAvatar: reporter?['avatar_url'] as String? ?? '',
    );
  }

  Report copyWith({String? status}) => Report(
        id: id,
        postId: postId,
        reporterId: reporterId,
        reason: reason,
        status: status ?? this.status,
        reportedAt: reportedAt,
        reporterUsername: reporterUsername,
        reporterAvatar: reporterAvatar,
      );

  @override
  String toString() =>
      'Report(id: $id, postId: $postId, reason: $reason, status: $status)';
}

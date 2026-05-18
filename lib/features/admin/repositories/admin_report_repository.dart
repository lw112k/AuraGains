import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/database_connection.dart';
import '../models/admin_model.dart';

// =====================================================================
// ADMIN REPORT REPOSITORY
// Dedicated data-access layer for report management.
// Uses DatabaseConnection.client only.
// =====================================================================
class AdminReportRepository {
  SupabaseClient get _db => DatabaseConnection.client;

  // Cached column info for the `report` table.
  String? _reportStatusColumn;
  Set<String>? _reportColumns;

  Future<void> _ensureColumns() async {
    if (_reportColumns != null) return;

    Set<String> cols = <String>{};
    try {
      final sample = await _db
          .from('report')
          .select('*')
          .limit(1)
          .maybeSingle();
      if (sample is Map<String, dynamic>) {
        cols = sample.keys.toSet();
      }
    } catch (_) {}

    if (cols.isEmpty) {
      // Fallback — known columns from schema discovery
      cols = {
        'report_id',
        'report_by',
        'target_type',
        'target_id',
        'reason',
        'create_date',
      };
    }

    _reportColumns = cols;
    final statusKey = cols.firstWhere(
      (k) => RegExp(r'(status|state|resolved|is_resolved|report_status)',
              caseSensitive: false)
          .hasMatch(k),
      orElse: () => '',
    );
    if (statusKey.isNotEmpty) _reportStatusColumn = statusKey;
  }

  // ─── Reports ───────────────────────────────────────────────────────

  Future<List<AdminReportModel>> fetchReports({String? status}) async {
    await _ensureColumns();

    final wanted = [
      'report_id',
      'report_by',
      'target_type',
      'target_id',
      'reason',
      'create_date',
    ];
    final fields = <String>[];
    for (final w in wanted) {
      if (_reportColumns!.contains(w)) fields.add(w);
    }
    if (_reportStatusColumn != null &&
        _reportColumns!.contains(_reportStatusColumn)) {
      fields.add(_reportStatusColumn!);
    }
    if (fields.isEmpty) fields.add('report_id');

    dynamic query = _db.from('report').select(fields.join(', '));

    if (status != null && status != 'all' && _reportStatusColumn != null) {
      query = query.eq(_reportStatusColumn!, status);
    }

    final dateCol = _reportColumns!.contains('create_date')
        ? 'create_date'
        : (_reportColumns!.contains('created_at') ? 'created_at' : null);
    final data = dateCol != null
        ? await query.order(dateCol, ascending: false)
        : await query;

    final list = (data as List)
        .map((e) =>
            AdminReportModel.fromJson(e as Map<String, dynamic>))
        .toList();

    if (status != null && status != 'all' && _reportStatusColumn == null) {
      return list
          .where((r) => (r.status ?? 'pending') == status)
          .toList();
    }
    return list;
  }

  Future<AdminReportModel?> fetchReportById(int reportId) async {
    await _ensureColumns();
    final wanted = [
      'report_id',
      'report_by',
      'target_type',
      'target_id',
      'reason',
      'create_date',
    ];
    final fields = <String>[];
    for (final w in wanted) {
      if (_reportColumns!.contains(w)) fields.add(w);
    }
    if (_reportStatusColumn != null &&
        _reportColumns!.contains(_reportStatusColumn)) {
      fields.add(_reportStatusColumn!);
    }
    if (fields.isEmpty) fields.add('report_id');

    final data = await _db
        .from('report')
        .select(fields.join(', '))
        .eq('report_id', reportId)
        .maybeSingle();
    if (data == null) return null;
    return AdminReportModel.fromJson(data);
  }

  Future<void> approveReport(int reportId) async {
    // Delete the flagged post and all reports targeting it.
    final postId = await _getPostIdForReport(reportId);
    if (postId != null) {
      await deletePost(postId);
      await deleteReportsByPostId(postId);
    }
  }

  Future<void> rejectReport(int reportId) async {
    // Simply delete the report row — no stamping, post stays intact.
    await _db
        .from('report')
        .delete()
        .eq('report_id', reportId);
  }

  Future<int?> _getPostIdForReport(int reportId) async {
    await _ensureColumns();
    final data = await _db
        .from('report')
        .select('target_id, target_type')
        .eq('report_id', reportId)
        .maybeSingle();
    if (data == null) return null;
    if ((data['target_type'] as String?) == 'post') {
      return data['target_id'] as int?;
    }
    return null;
  }

  // ─── Posts ─────────────────────────────────────────────────────────

  /// Delete all reports that reference a given post ID.
  Future<void> deleteReportsByPostId(int postId) async {
    await _db
        .from('report')
        .delete()
        .eq('target_type', 'post')
        .eq('target_id', postId);
  }

  /// Delete a single report by its ID.
  Future<void> deleteReportById(int reportId) async {
    await _db
        .from('report')
        .delete()
        .eq('report_id', reportId);
  }

  Future<AdminPostModel?> fetchPost(int postId) async {
    final cols = await _ensureTableColumns('post');
    final wanted = [
      'post_id',
      'post_by',
      'title',
      'description',
      'thumbnail_url',
      'post_type',
      'post_like',
      'create_date',
    ];
    final fields = wanted.where((f) => cols.contains(f)).toList();
    if (fields.isEmpty) fields.add('post_id');

    final data = await _db
        .from('post')
        .select(fields.join(', '))
        .eq('post_id', postId)
        .maybeSingle();
    if (data == null) return null;
    return AdminPostModel.fromJson(data);
  }

  Future<List<String>> fetchPostMediaUrls(int postId) async {
    final cols = await _ensureTableColumns('post_media');
    if (!cols.contains('media_url')) return [];
    dynamic query =
        _db.from('post_media').select('media_url').eq('post_id', postId);
    if (cols.contains('display_order')) query = query.order('display_order');
    final data = await query;
    return (data as List)
        .map<String>((e) => e['media_url'] as String)
        .where((url) => url.isNotEmpty)
        .toList();
  }

  Future<void> deletePost(int postId) async {
    try {
      await _db.from('post').delete().eq('post_id', postId);
    } catch (_) {}
  }

  // ─── Comments ────────────────────────────────────────────────────────

  Future<AdminCommentModel?> fetchComment(int commentId) async {
    final cols = await _ensureTableColumns('comment');
    final wanted = ['comment_id', 'post_id', 'user_id', 'content', 'create_date'];
    final fields = wanted.where((f) => cols.contains(f)).toList();
    if (fields.isEmpty) fields.add('comment_id');
    final data = await _db
        .from('comment')
        .select(fields.join(', '))
        .eq('comment_id', commentId)
        .maybeSingle();
    if (data == null) return null;
    return AdminCommentModel.fromJson(data);
  }

  Future<void> deleteComment(int commentId) async {
    try {
      await _db.from('comment').delete().eq('comment_id', commentId);
    } catch (_) {}
  }

  /// Delete all reports that reference a given comment ID.
  Future<void> deleteReportsByCommentId(int commentId) async {
    await _db
        .from('report')
        .delete()
        .eq('target_type', 'comment')
        .eq('target_id', commentId);
  }

  /// Find the parent post ID for a comment (used for comment report navigation).
  Future<int?> fetchParentPostIdForComment(int commentId) async {
    final data = await _db
        .from('comment')
        .select('post_id')
        .eq('comment_id', commentId)
        .maybeSingle();
    if (data == null) return null;
    return data['post_id'] as int?;
  }

  // ─── Users (for reporter info) ─────────────────────────────────────

  Future<Map<String, dynamic>?> fetchUserById(String userId) async {
    final data =
        await _db.from('user').select('*').eq('user_id', userId).maybeSingle();
    return data;
  }

  // ─── Column helpers ────────────────────────────────────────────────

  final Map<String, Set<String>> _tableColumnsCache = {};

  Future<Set<String>> _ensureTableColumns(String table) async {
    if (_tableColumnsCache.containsKey(table)) {
      return _tableColumnsCache[table]!;
    }
    Set<String> cols = <String>{};
    try {
      final raw =
          await _db.from(table).select().limit(1).maybeSingle();
      if (raw is Map<String, dynamic>) cols = raw.keys.toSet();
    } catch (_) {}
    if (cols.isEmpty) {
      if (table == 'post') {
        cols = {
          'post_id',
          'post_by',
          'create_date',
          'post_like',
          'title',
          'description',
          'thumbnail_url',
          'post_type',
          'visibility',
        };
      } else if (table == 'post_media') {
        cols = {
          'media_id',
          'post_id',
          'media_url',
          'media_type',
          'display_order',
        };
      }
    }
    _tableColumnsCache[table] = cols;
    return cols;
  }
}

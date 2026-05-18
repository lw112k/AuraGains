import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/database_connection.dart';
import '../models/admin_model.dart';

// =====================================================================
// ADMIN REPOSITORY
// Single admin data-access layer. Uses DatabaseConnection.client only.
// =====================================================================
class AdminRepository {
  SupabaseClient get _db => DatabaseConnection.client;

  // Cached column info for the `report` table. Some installs use different
  // column names (e.g. `status`, `report_status`, `is_resolved`, `post_id`).
  String? _reportStatusColumn;
  Set<String>? _reportColumns;

  final Map<String, Set<String>> _tableColumnsCache = {};

  Future<Set<String>> _ensureTableColumns(String table) async {
    if (_tableColumnsCache.containsKey(table)) return _tableColumnsCache[table]!;
    // Attempt to fetch a single row sample; don't let failures here abort the
    // metadata discovery flow (some DB setups restrict direct selects).
    Set<String> cols = <String>{};
    Map<String, dynamic>? sampleRow;
    try {
      final raw = await _db.from(table).select().limit(1).maybeSingle();
      if (raw is Map<String, dynamic>) sampleRow = raw;
    } catch (_) {
      // ignore - continue to information_schema / fallback
    }

    if (sampleRow != null) {
      cols = sampleRow.keys.toSet();
    } else {
      try {
        final colsResp = await _db
            .from('information_schema.columns')
            .select('column_name')
            .eq('table_name', table)
            .eq('table_schema', 'public');
        if (colsResp.isNotEmpty) {
          cols = colsResp
              .map((c) => (c)['column_name'] as String)
              .toSet();
        }
      } catch (_) {
        // ignore - information_schema may be restricted for some Supabase setups
      }

      // If lookup didn't populate cols (no rows, permissions, or other issues),
      // fall back to the authoritative schema provided earlier.
      if (cols.isEmpty) {
        if (table == 'report') {
          cols = {'report_id', 'report_by', 'target_type', 'target_id', 'reason', 'create_date'};
        } else if (table == 'user') {
          cols = {'user_id', 'username', 'profile_pic_url', 'system_role', 'gender', 'level_id', 'date_of_birth', 'is_banned'};
        } else if (table == 'expert_application') {
          cols = {'expert_application_id', 'user_id', 'expert_title', 'experience_year', 'experience_description', 'application_status', 'create_date'};
        } else if (table == 'post') {
          cols = {'post_id', 'post_by', 'create_date', 'post_like', 'title', 'description', 'thumbnail_url', 'post_type', 'visibility'};
        } else if (table == 'post_media') {
          cols = {'media_id', 'post_id', 'media_url', 'media_type', 'display_order'};
        } else if (table == 'comment') {
          cols = {'comment_id', 'post_id', 'user_id', 'text', 'create_date'};
        } else if (table == 'expert_application_image') {
          cols = {'expert_application_image_id', 'expert_application_id', 'image_url'};
        }
      }
    }

    _tableColumnsCache[table] = cols;
    // Helpful debug output when running against different Supabase schemas
    try {
      // ignore: avoid_print
      print('AdminRepository: columns for $table => ${cols.join(', ')}');
    } catch (_) {}
    return cols;
  }

  Future<void> _ensureReportColumns() async {
    if (_reportColumns != null) return;
    _reportColumns = await _ensureTableColumns('report');
    final statusKey = _reportColumns!.firstWhere(
      (k) => RegExp(r'(status|state|resolved|is_resolved|report_status)', caseSensitive: false).hasMatch(k),
      orElse: () => '',
    );
    if (statusKey.isNotEmpty) _reportStatusColumn = statusKey;
  }

  // ─── Dashboard ───────────────────────────────────────────────────────

  Future<AdminDashboardStats> fetchDashboardStats() async {
    final userCols = await _ensureTableColumns('user');
    final userWanted = ['user_id', 'is_banned'];
    final userSelect = userWanted.where((f) => userCols.contains(f)).join(', ');
    final usersRaw = userSelect.isNotEmpty
      ? await _db.from('user').select(userSelect)
      : await _db.from('user').select('user_id');

    // Fetch reports with reason field — status is derived from the reason prefix
    // ([APPROVED]/[DISMISSED]), not from a separate status column.
    await _ensureReportColumns();
    final reportsRaw = _reportColumns != null && _reportColumns!.contains('reason')
      ? await _db.from('report').select('report_id, reason')
      : await _db.from('report').select('report_id');

    final appCols = await _ensureTableColumns('expert_application');
    final appWanted = ['expert_application_id', 'application_status'];
    final appSelect = appWanted.where((f) => appCols.contains(f)).join(', ');
    final appsRaw = appSelect.isNotEmpty
      ? await _db.from('expert_application').select(appSelect)
      : await _db.from('expert_application').select('expert_application_id');

    final postCols = await _ensureTableColumns('post');
    final List postsRaw = postCols.contains('post_id')
      ? await _db.from('post').select('post_id')
      : <dynamic>[];

    final totalUsers = usersRaw.length;
    final bannedUsers = userCols.contains('is_banned')
      ? usersRaw.where((u) => u['is_banned'] == true).length
      : 0;
    // Pending means no [APPROVED] or [DISMISSED] prefix on the reason field.
    final pendingReports = _reportColumns != null && _reportColumns!.contains('reason')
      ? reportsRaw.where((r) {
          final reason = (r['reason'] as String?) ?? '';
          return !reason.startsWith('[APPROVED]') && !reason.startsWith('[DISMISSED]');
        }).length
      : reportsRaw.length;
    final pendingApplications = appCols.contains('application_status')
      ? appsRaw.where((a) => (a['application_status'] ?? 'pending') == 'pending').length
      : appsRaw.length;
    final totalPosts = postsRaw.length;

    return AdminDashboardStats(
      totalUsers: totalUsers,
      bannedUsers: bannedUsers,
      pendingReports: pendingReports,
      pendingApplications: pendingApplications,
      totalPosts: totalPosts,
    );
  }

  // ─── Users ───────────────────────────────────────────────────────────

  Future<List<AdminUserModel>> fetchUsers() async {
    final cols = await _ensureTableColumns('user');
    final wanted = [
      'user_id',
      'username',
      'email',
      'profile_pic_url',
      'system_role',
      'is_banned',
      'register_date',
      'gender'
    ];
    final fields = wanted.where((f) => cols.contains(f)).toList();
    if (fields.isEmpty) fields.add('user_id');
    dynamic query = _db.from('user').select(fields.join(', '));
    if (cols.contains('register_date')) query = query.order('register_date', ascending: false);
    final data = await query;
    try {
      // ignore: avoid_print
      print('AdminRepository.fetchApplications: dataType=${data.runtimeType} count=${data is List ? data.length : 'unknown'} sample=${data is List && data.isNotEmpty ? data.first : null}');
    } catch (_) {}
    try {
      // ignore: avoid_print
      print('AdminRepository.fetchUsers: data type=${data.runtimeType} count=${data is List ? data.length : 'unknown'} sample=${data is List && data.isNotEmpty ? data.first : null}');
    } catch (_) {}
    final List<AdminUserModel> list = (data as List).map<AdminUserModel>((e) => AdminUserModel.fromJson(e as Map<String, dynamic>)).toList();
    return list;
  }

  Future<void> banUser(String userId) async {
    final cols = await _ensureTableColumns('user');
    if (!cols.contains('is_banned')) return;
    await _db.from('user').update({'is_banned': true}).eq('user_id', userId);
  }

  Future<void> unbanUser(String userId) async {
    final cols = await _ensureTableColumns('user');
    if (!cols.contains('is_banned')) return;
    await _db.from('user').update({'is_banned': false}).eq('user_id', userId);
  }

  Future<void> setSystemRole(String userId, String role) async {
    // NB: user_role_type_enum must include 'expert' — run:
    //   ALTER TYPE user_role_type_enum ADD VALUE IF NOT EXISTS 'expert';
    final cols = await _ensureTableColumns('user');
    if (!cols.contains('system_role')) return;
    await _db.from('user').update({'system_role': role}).eq('user_id', userId);
  }

  // ─── Reports ─────────────────────────────────────────────────────────

  Future<List<AdminReportModel>> fetchReports({String? status}) async {
    await _ensureReportColumns();

    final wanted = [
      'report_id',
      'report_by',
      'target_type',
      'target_id',
      'reason',
      'create_date'
    ];
    final fields = <String>[];
    for (final w in wanted) {
      if (_reportColumns!.contains(w)) fields.add(w);
    }
    if (_reportStatusColumn != null && _reportColumns!.contains(_reportStatusColumn)) {
      fields.add(_reportStatusColumn!);
    }
    if (_reportColumns!.contains('post_id')) fields.add('post_id');

    // Ensure we select at least report_id
    if (fields.isEmpty) fields.add('report_id');

    dynamic query = _db.from('report').select(fields.join(', '));

    if (status != null && status != 'all' && _reportStatusColumn != null) {
        query = query.eq(_reportStatusColumn!, status);
        final dateCol = _reportColumns!.contains('create_date')
            ? 'create_date'
            : (_reportColumns!.contains('created_at') ? 'created_at' : null);
        final ordered = dateCol != null
            ? await query.order(dateCol, ascending: false)
            : await query;
        return (ordered as List).map<AdminReportModel>((e) => AdminReportModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    // Fallback: fetch without server-side status filtering and do a best-effort client-side filter
    final dateCol = _reportColumns!.contains('create_date')
        ? 'create_date'
        : (_reportColumns!.contains('created_at') ? 'created_at' : null);
    final data = dateCol != null
        ? await query.order(dateCol, ascending: false)
        : await query;
    try {
      // ignore: avoid_print
      print('AdminRepository.fetchReports: fields=${fields.join(', ')} dataType=${data.runtimeType} count=${data is List ? data.length : 'unknown'} sample=${data is List && data.isNotEmpty ? data.first : null}');
    } catch (_) {}
    final list = (data as List).map<AdminReportModel>((e) => AdminReportModel.fromJson(e as Map<String, dynamic>)).toList();
    if (status != null && status != 'all' && _reportStatusColumn == null) {
      return list.where((r) => (r.status ?? 'pending') == status).toList();
    }
    return list;
  }

  Future<void> updateReportStatus(int reportId, String status) async {
    await _ensureReportColumns();
    if (_reportStatusColumn != null) {
      await _db
          .from('report')
          .update({_reportStatusColumn!: status})
          .eq('report_id', reportId);
    } else {
      // No status-like column detected; do nothing (avoid throwing). Caller will update local state optimistically.
    }
  }

  // Compatibility wrappers used by higher-level providers.
  Future<int> fetchUserCount() async {
    final cols = await _ensureTableColumns('user');
    final result = await _db.from('user').select('user_id');
    return result.length;
  }

  Future<List<Map<String, dynamic>>> fetchPendingReports() async {
    await _ensureReportColumns();
    dynamic query = _db.from('report').select(_reportColumns != null && _reportColumns!.isNotEmpty ? _reportColumns!.join(',') : '*');
    if (_reportStatusColumn != null) query = query.eq(_reportStatusColumn!, 'pending');
    final dateCol = _reportColumns != null && _reportColumns!.contains('create_date')
        ? 'create_date'
        : (_reportColumns != null && _reportColumns!.contains('created_at') ? 'created_at' : null);
    final data = dateCol != null
        ? await query.order(dateCol, ascending: false)
        : await query;
    return (data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>?> fetchUserById(String userId) async {
    final data = await _db.from('user').select().eq('user_id', userId).maybeSingle();
    if (data == null) return null;
    return data;
  }

  Future<void> approveReport(int reportId) async {
    // Find the target post and delete it along with all related reports.
    final data = await _db
        .from('report')
        .select('target_id, target_type')
        .eq('report_id', reportId)
        .maybeSingle();
    if (data != null && (data['target_type'] as String?) == 'post') {
      final postId = data['target_id'] as int?;
      if (postId != null) {
        await deletePost(postId);
        await deleteReportsByPostId(postId);
      }
    }
  }

  Future<void> rejectReport(int reportId) async {
    // Simply delete the report row — no stamping, post stays intact.
    await _db
        .from('report')
        .delete()
        .eq('report_id', reportId);
  }

  Future<AdminReportModel?> fetchReportById(int reportId) async {
    await _ensureReportColumns();
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
    if (_reportStatusColumn != null && _reportColumns!.contains(_reportStatusColumn)) {
      fields.add(_reportStatusColumn!);
    }
    if (_reportColumns!.contains('post_id')) fields.add('post_id');
    if (fields.isEmpty) fields.add('report_id');
    final data = await _db
        .from('report')
        .select(fields.join(', '))
        .eq('report_id', reportId)
        .maybeSingle();
    if (data == null) return null;
    return AdminReportModel.fromJson(data);
  }

  // ─── Posts / Content ─────────────────────────────────────────────────

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
      'create_date'
    ];
    final fields = wanted.where((f) => cols.contains(f)).toList();
    if (fields.isEmpty) fields.add('post_id');
    dynamic query = _db.from('post').select(fields.join(', ')).eq('post_id', postId);
    final data = await query.maybeSingle();
    if (data == null) return null;
    return AdminPostModel.fromJson(data as Map<String, dynamic>);
  }

  Future<AdminUserModel?> fetchUser(String userId) async {
    final cols = await _ensureTableColumns('user');
    final wanted = [
      'user_id',
      'username',
      'email',
      'profile_pic_url',
      'system_role',
      'is_banned',
      'register_date',
      'gender'
    ];
    final fields = wanted.where((f) => cols.contains(f)).toList();
    if (fields.isEmpty) fields.add('user_id');
    final data = await _db.from('user').select(fields.join(', ')).eq('user_id', userId).maybeSingle();
    if (data == null) return null;
    return AdminUserModel.fromJson(data);
  }

  Future<List<String>> fetchPostMediaUrls(int postId) async {
    final cols = await _ensureTableColumns('post_media');
    if (!cols.contains('media_url')) return [];
    dynamic query = _db.from('post_media').select('media_url').eq('post_id', postId);
    if (cols.contains('display_order')) query = query.order('display_order');
    final data = await query;
    return (data as List).map<String>((e) => e['media_url'] as String).where((url) => url.isNotEmpty).toList();
  }

  Future<void> deletePost(int postId) async {
    try {
      await _db.from('post').delete().eq('post_id', postId);
    } catch (_) {
      // If post_id doesn't exist or delete fails, swallow to avoid crashing admin UI
    }
  }

  // ─── Comments ────────────────────────────────────────────────────────

  Future<AdminCommentModel?> fetchComment(int commentId) async {
    final cols = await _ensureTableColumns('comment');
    // DB column is named "text", not "content" — map it at fetch time.
    final wanted = <String>['comment_id', 'post_id', 'user_id', 'create_date'];
    if (cols.contains('content')) {
      wanted.add('content');
    } else if (cols.contains('text')) {
      wanted.add('text');
    }
    final fields = wanted.where((f) => cols.contains(f)).toList();
    if (fields.isEmpty) fields.add('comment_id');
    final data = await _db
        .from('comment')
        .select(fields.join(', '))
        .eq('comment_id', commentId)
        .maybeSingle();
    if (data == null) return null;
    // Remap DB "text" -> model "content"
    if (data.containsKey('text') && data['content'] == null) {
      data['content'] = data['text'];
    }
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

  // ─── Expert Applications ─────────────────────────────────────────────

  Future<List<AdminApplicationModel>> fetchApplications() async {
    final cols = await _ensureTableColumns('expert_application');
    final wanted = [
      'expert_application_id',
      'user_id',
      'expert_title',
      'experience_year',
      'experience_years',
      'experience_description',
      'application_status',
      'create_date'
    ];
    final fields = wanted.where((f) => cols.contains(f)).toList();
    if (fields.isEmpty) fields.add('expert_application_id');
    dynamic query = _db.from('expert_application').select(fields.join(', '));
    if (cols.contains('create_date')) query = query.order('create_date', ascending: false);
    final data = await query;

    final List<dynamic> rows = data as List;
    if (rows.isEmpty) return [];

    // ─ Batch fetch users ─────────────────────────────────────────────
    final userIds = rows
        .map((r) => (r as Map<String, dynamic>)['user_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final appIds = rows
        .map((r) => (r as Map<String, dynamic>)['expert_application_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    final userColsLocal = await _ensureTableColumns('user');
    final userSelectFields = ['user_id', 'username', 'email', 'profile_pic_url']
        .where((f) => userColsLocal.contains(f))
        .join(', ');

    final Map<String, Map<String, dynamic>> usersById = {};
    if (userIds.isNotEmpty && userSelectFields.isNotEmpty) {
      final usersRaw = await _db
          .from('user')
          .select(userSelectFields)
          .inFilter('user_id', userIds);
      for (final u in usersRaw) {
        usersById[(u as Map<String, dynamic>)['user_id'].toString()] =
            u as Map<String, dynamic>;
      }
    }

    // ─ Batch fetch images ────────────────────────────────────────────
    final imgCols = await _ensureTableColumns('expert_application_image');
    final Map<String, List<String>> imagesByAppId = {};
    if (imgCols.contains('image_url') && appIds.isNotEmpty) {
      final imagesRaw = await _db
          .from('expert_application_image')
          .select('expert_application_id, image_url')
          .inFilter('expert_application_id', appIds);
      for (final img in imagesRaw) {
        final m = img as Map<String, dynamic>;
        final aid = m['expert_application_id'].toString();
        imagesByAppId.putIfAbsent(aid, () => []).add(m['image_url'] as String);
      }
    }

    final List<AdminApplicationModel> result = [];
    for (final row in rows) {
      final r = row as Map<String, dynamic>;
      final userId = r['user_id']?.toString() ?? '';
      final appId = r['expert_application_id']?.toString() ?? '';
      result.add(
        AdminApplicationModel.fromJson(
          r,
          imageUrls: imagesByAppId[appId] ?? [],
          userJson: usersById[userId],
        ),
      );
    }
    return result;
  }

  /// Approve expert status for a user via expert_application table.
  /// If no application exists, creates a minimal one and approves it.
  Future<void> approveExpertForUser(String userId) async {
    final appCols = await _ensureTableColumns('expert_application');
    if (!appCols.contains('application_status')) return;

    // Check for existing application
    final existing = await _db
        .from('expert_application')
        .select('expert_application_id')
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await _db
          .from('expert_application')
          .update({'application_status': 'approved'})
          .eq('expert_application_id', existing['expert_application_id']);
    } else {
      // Create a minimal approved application
      await _db.from('expert_application').insert({
        'user_id': userId,
        'application_status': 'approved',
        'expert_title': 'Expert',
        if (appCols.contains('experience_year')) 'experience_year': 0,
        if (appCols.contains('experience_description')) 'experience_description': '',
      });
    }
  }

  Future<void> approveApplication(String applicationId, String userId) async {
    final appCols = await _ensureTableColumns('expert_application');
    if (appCols.contains('application_status')) {
      await _db
          .from('expert_application')
          .update({'application_status': 'approved'})
          .eq('expert_application_id', applicationId);
    }
    // Note: system_role is NOT updated here. Expert status is determined by
    // the expert_application.application_status = 'approved' flag alone.
  }

  Future<void> rejectApplication(String applicationId) async {
    final appCols = await _ensureTableColumns('expert_application');
    if (appCols.contains('application_status')) {
      await _db.from('expert_application').update({'application_status': 'rejected'}).eq('expert_application_id', applicationId);
    }
  }

  Future<Map<String, dynamic>?> fetchApplicationById(String applicationId) async {
    final cols = await _ensureTableColumns('expert_application');
    final wanted = [
      'expert_application_id',
      'user_id',
      'expert_title',
      'experience_year',
      'experience_years',
      'experience_description',
      'application_status',
      'create_date',
      'full_name',
      'email',
      'gender',
      'years_experience',
      'specialization',
      'bio',
      'cert_urls'
    ];
    final fields = wanted.where((f) => cols.contains(f)).toList();
    if (fields.isEmpty) fields.add('expert_application_id');

    final idField = cols.contains('expert_application_id') ? 'expert_application_id' : (cols.contains('id') ? 'id' : 'expert_application_id');
    final data = await _db.from('expert_application').select(fields.join(',')).eq(idField, applicationId).maybeSingle();
    if (data == null) return null;
    return data;
  }
}

───────────────────────────────────────
CODE REVIEW REPORT — AURAGAINS ADMIN
───────────────────────────────────────

FILE: [lib/main.dart](lib/main.dart)
  [ROUTING] Role switch omits valid user roles  
  → Problem: `AuthWrapper` only routes `admin` and `user`. Other valid `system_role` values like `expert` or `gym_member` fall into the default and route to `LoginView`, locking out logged-in users.  
  → Location: `AuthWrapper.build` switch on `authViewModel.currentUser!.role`.  
  → Fix: Add cases for the additional tokens or normalize roles before the switch, e.g.  
  ```dart
  switch (authViewModel.currentUser!.role) {
    case 'admin':
      return const AdminView();
    case 'user':
    case 'expert':
    case 'gym_member':
    case 'member':
      return const UserHomepageFrame();
    default:
      return const LoginView();
  }
  ```

FILE: [lib/core/services/database_connection.dart](lib/core/services/database_connection.dart)
  [SECURITY] Hardcoded Supabase URL and anon key  
  → Problem: Config is embedded in source; rotation requires rebuild and leaks in public repos. RLS is still required, but config should be externalized.  
  → Location: `DatabaseConnection.supabaseUrl` and `DatabaseConnection.supabaseAnonKey`.  
  → Fix: Load from environment (`const String.fromEnvironment`, dotenv, or build-time config) and keep secrets out of git.  

  [BUG] No controlled failure handling on initialization  
  → Problem: If `Supabase.initialize` fails, the app crashes without a user-facing error state.  
  → Location: `DatabaseConnection.initialize`.  
  → Fix: Wrap initialization in try/catch and surface a startup error screen; at minimum log and rethrow.  

FILE: [lib/core/routes/app_routes.dart](lib/core/routes/app_routes.dart)
  [DEAD CODE] `AppRouter` is defined but never used  
  → Problem: The app uses `MaterialApp(home: AuthWrapper)` so the GoRouter config never runs; routing logic is duplicated and can diverge.  
  → Location: `AppRouter.createRouter`.  
  → Fix: Switch to `MaterialApp.router` with `AppRouter.createRouter(authViewModel)` or remove the unused router.  

  [ROUTING] Invalid deep-link id is silently ignored  
  → Problem: Non-numeric `content/:id` falls back to `AdminView` without feedback, masking bad links.  
  → Location: `GoRoute` builder for `content/:id`.  
  → Fix: Validate id and show an error state or redirect to dashboard with logging.  

FILE: [lib/features/admin/models/admin_model.dart](lib/features/admin/models/admin_model.dart)
  [NULL] Critical IDs default to 0 when missing  
  → Problem: `reportId` and `postId` default to 0 if the payload is missing these fields; 0 can be treated as a real id, leading to incorrect updates/deletes.  
  → Location: `AdminReportModel.fromJson` and `AdminPostModel.fromJson`.  
  → Fix: Make these IDs nullable and handle missing cases, or throw if the field is required.  

FILE: [lib/features/admin/models/app_user_model.dart](lib/features/admin/models/app_user_model.dart)
  [BUG] `avatarUrl` ignores `profile_pic_url`  
  → Problem: If the user table provides `profile_pic_url` (used elsewhere in admin), `avatarUrl` will be empty.  
  → Location: `AppUser.fromSupabase` mapping for `avatarUrl`.  
  → Fix: Read both fields:  
  ```dart
  avatarUrl: (row['avatar_url'] ?? row['profile_pic_url']) as String? ?? '',
  ```

FILE: [lib/features/admin/models/report_model.dart](lib/features/admin/models/report_model.dart)
  [BUG] `reportedAt` falls back to `DateTime.now()` on parse failure  
  → Problem: Missing/malformed timestamps become "now", which is misleading for moderation timelines.  
  → Location: `Report.fromSupabase`.  
  → Fix: Use a sentinel value (epoch) or allow `reportedAt` to be nullable and handle it in UI.  

FILE: [lib/features/admin/repositories/admin_repository.dart](lib/features/admin/repositories/admin_repository.dart)
  [ARCH] Runtime schema discovery increases latency and fragility  
  → Problem: `_ensureTableColumns` queries `information_schema` and uses hardcoded fallbacks; this couples the app to multiple schemas and adds overhead on first load.  
  → Location: `_ensureTableColumns`.  
  → Fix: Lock to a canonical schema and remove runtime discovery (or preload once at startup and cache permanently).  

  [BUG] `fetchReports` orders by `create_date` even when absent  
  → Problem: If the report table uses `created_at`, the order clause can fail and break report loading.  
  → Location: `fetchReports` order clause.  
  → Fix: Choose the available date column before ordering, e.g.  
  ```dart
  final dateCol = _reportColumns!.contains('create_date')
      ? 'create_date'
      : (_reportColumns!.contains('created_at') ? 'created_at' : null);
  if (dateCol != null) {
    query = query.order(dateCol, ascending: false);
  }
  ```

  [PERF] N+1 queries in `fetchApplications`  
  → Problem: For each application, it queries `user` and `expert_application_image`, which scales poorly for large lists.  
  → Location: `fetchApplications` loop.  
  → Fix: Batch fetch users and images (e.g., `in_` on ids) or use a join.  

FILE: [lib/features/admin/view_models/admin_viewmodel.dart](lib/features/admin/view_models/admin_viewmodel.dart)
  [STATE] Public loading flags can be mutated without notifications  
  → Problem: `isLoading` and `isActionLoading` are public fields, so external writes can bypass `notifyListeners` and desync UI.  
  → Location: field declarations and `_setLoading`.  
  → Fix: Make them private with getters and update through dedicated setters.  

  [BUG] `loadContentDetail` depends on `_allReports` cache only  
  → Problem: When opening the content detail directly (e.g., via deep link), `_allReports` may be empty and `detailReport` stays null.  
  → Location: `loadContentDetail` block for `reportId`.  
  → Fix: If no cache match, fetch the report by id from the repository (add a repo method or filtered query).  

  [NULL] Empty `postBy`/`reportBy` values still trigger fetches  
  → Problem: Models can provide empty strings for `postBy`/`reportBy`, but `loadContentDetail` only checks for null and calls `fetchUser('')`.  
  → Location: `loadContentDetail` user fetch blocks.  
  → Fix: Guard with `isNotEmpty` before calling `fetchUser`.  

  [ARCH] Role normalization is fragile  
  → Problem: `_dbTokenForLabel` infers a DB token from `_allUsers` and uses dummy `AdminUserModel`s; new tokens can map to the wrong value.  
  → Location: `_userTokens`, `_expertTokens`, `_adminTokens`, `_dbTokenForLabel`.  
  → Fix: Replace with a const map/enum for supported roles and handle unknown values explicitly.  

  [ARCH] Manual model reconstruction in status updates  
  → Problem: `_updateReportStatus` and `_updateAppStatus` rebuild models field-by-field, increasing drift risk when models change.  
  → Location: `_updateReportStatus`, `_updateAppStatus`.  
  → Fix: Add `copyWith` to models and use it.  

FILE: [lib/features/admin/views/admin_users_view.dart](lib/features/admin/views/admin_users_view.dart)
  [UI] Email rendered twice  
  → Problem: `_UserTile` displays `user.email` in two consecutive lines, wasting space.  
  → Location: `_UserTile` email section.  
  → Fix: Remove the duplicate or show a joined date using `_formatDate(user.registerDate)`.  

  [DEAD CODE] `_RoleFilterChip` is unused  
  → Problem: The widget is declared but never used.  
  → Location: `_RoleFilterChip` class.  
  → Fix: Remove it or replace the inline filter buttons with this control.  

  [UI] Role pill shows raw DB token  
  → Problem: Displays raw `user.systemRole` values (e.g., `GYM_MEMBER`) that don't match the UI labels.  
  → Location: `_UserTile` role pill.  
  → Fix: Use a normalized label from `AdminViewModel` (expose a helper or add a computed label).  

FILE: [lib/features/admin/views/admin_applications_view.dart](lib/features/admin/views/admin_applications_view.dart)
  [PERF] `indexOf` inside itemBuilder  
  → Problem: `vm.filteredApplications.indexOf(app)` is O(n) and executed for every row.  
  → Location: `ListView.separated` itemBuilder.  
  → Fix: Use the builder index `i` directly.  

  [BUG] Filtered index used with `_allApplications`  
  → Problem: `selectApplication` indexes `_allApplications`, so using the filtered index can open the wrong application.  
  → Location: `_openDetail` and `AdminViewModel.selectApplication`.  
  → Fix: Pass the selected `AdminApplicationModel` (or translate to the correct index with `indexWhere`).  

FILE: [lib/features/admin/views/admin_content_detail_view.dart](lib/features/admin/views/admin_content_detail_view.dart)
  [UI] Error state not surfaced  
  → Problem: If loading fails, the screen shows "Post not found" even when `vm.errorMessage` is set.  
  → Location: `build` branch for `vm.detailPost == null`.  
  → Fix: Display `vm.errorMessage` with a retry action when present.  

FILE: [lib/features/auth/view_models/auth_viewmodel.dart](lib/features/auth/view_models/auth_viewmodel.dart)
  [STATE] `login` does not toggle `_isLoading`  
  → Problem: `isLoading` never reflects login progress; any UI relying on it won't show a loading state.  
  → Location: `login`.  
  → Fix: Set `_isLoading = true` before the request and reset it in `finally` with `notifyListeners()`.  

FILE: [lib/features/auth/repositories/auth_repository.dart](lib/features/auth/repositories/auth_repository.dart)
  [BUG] Profile insert omits `email`  
  → Problem: The profile row is created without `email`, but the app reads `email` from the user table, leading to blanks unless the DB fills it.  
  → Location: `registerUser` profile insert.  
  → Fix: Include `email` in the insert, e.g.  
  ```dart
  .insert({'user_id': authUser.id, 'username': username, 'email': email})
  ```

  [BUG] No client-side validation before sign-up  
  → Problem: Invalid emails/weak passwords are sent to Supabase, leading to avoidable errors and poor UX.  
  → Location: `registerUser` input handling.  
  → Fix: Validate inputs before calling `signUp` (basic format/length checks).  

REVIEW SUMMARY TABLE:
| # | File | Category | Severity (Critical/High/Medium/Low) | Status |
|---|------|----------|--------------------------------------|--------|
| 1 | [lib/main.dart](lib/main.dart) | [ROUTING] | Critical | Open |
| 2 | [lib/core/services/database_connection.dart](lib/core/services/database_connection.dart) | [SECURITY] | Medium | Open |
| 3 | [lib/core/services/database_connection.dart](lib/core/services/database_connection.dart) | [BUG] | High | Open |
| 4 | [lib/core/routes/app_routes.dart](lib/core/routes/app_routes.dart) | [DEAD CODE] | Low | Open |
| 5 | [lib/core/routes/app_routes.dart](lib/core/routes/app_routes.dart) | [ROUTING] | Medium | Open |
| 6 | [lib/features/admin/models/admin_model.dart](lib/features/admin/models/admin_model.dart) | [NULL] | Medium | Open |
| 7 | [lib/features/admin/models/app_user_model.dart](lib/features/admin/models/app_user_model.dart) | [BUG] | Low | Open |
| 8 | [lib/features/admin/models/report_model.dart](lib/features/admin/models/report_model.dart) | [BUG] | Medium | Open |
| 9 | [lib/features/admin/repositories/admin_repository.dart](lib/features/admin/repositories/admin_repository.dart) | [ARCH] | Medium | Open |
|10 | [lib/features/admin/repositories/admin_repository.dart](lib/features/admin/repositories/admin_repository.dart) | [BUG] | High | Open |
|11 | [lib/features/admin/repositories/admin_repository.dart](lib/features/admin/repositories/admin_repository.dart) | [PERF] | Medium | Open |
|12 | [lib/features/admin/view_models/admin_viewmodel.dart](lib/features/admin/view_models/admin_viewmodel.dart) | [STATE] | Medium | Open |
|13 | [lib/features/admin/view_models/admin_viewmodel.dart](lib/features/admin/view_models/admin_viewmodel.dart) | [BUG] | High | Open |
|14 | [lib/features/admin/view_models/admin_viewmodel.dart](lib/features/admin/view_models/admin_viewmodel.dart) | [NULL] | Medium | Open |
|15 | [lib/features/admin/view_models/admin_viewmodel.dart](lib/features/admin/view_models/admin_viewmodel.dart) | [ARCH] | Medium | Open |
|16 | [lib/features/admin/view_models/admin_viewmodel.dart](lib/features/admin/view_models/admin_viewmodel.dart) | [ARCH] | Medium | Open |
|17 | [lib/features/admin/views/admin_users_view.dart](lib/features/admin/views/admin_users_view.dart) | [UI] | Medium | Open |
|18 | [lib/features/admin/views/admin_users_view.dart](lib/features/admin/views/admin_users_view.dart) | [DEAD CODE] | Low | Open |
|19 | [lib/features/admin/views/admin_users_view.dart](lib/features/admin/views/admin_users_view.dart) | [UI] | Low | Open |
|20 | [lib/features/admin/views/admin_applications_view.dart](lib/features/admin/views/admin_applications_view.dart) | [PERF] | Low | Open |
|21 | [lib/features/admin/views/admin_applications_view.dart](lib/features/admin/views/admin_applications_view.dart) | [BUG] | High | Open |
|22 | [lib/features/admin/views/admin_content_detail_view.dart](lib/features/admin/views/admin_content_detail_view.dart) | [UI] | Low | Open |
|23 | [lib/features/auth/view_models/auth_viewmodel.dart](lib/features/auth/view_models/auth_viewmodel.dart) | [STATE] | Low | Open |
|24 | [lib/features/auth/repositories/auth_repository.dart](lib/features/auth/repositories/auth_repository.dart) | [BUG] | Medium | Open |
|25 | [lib/features/auth/repositories/auth_repository.dart](lib/features/auth/repositories/auth_repository.dart) | [BUG] | Low | Open |

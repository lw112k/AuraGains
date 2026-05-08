import 'package:flutter/material.dart';

import '../../../core/theme/constants.dart';
import '../../../core/services/database_connection.dart';
import '../models/trainer_application_model.dart';
import 'verify_trainer_screen.dart';

/// Lists all trainer applications with All / Pending / Approved / Rejected tabs.
///
/// Tapping an application card navigates to [VerifyTrainerScreen].
/// Uses local [StatefulWidget] state + direct Supabase queries — the same
/// pattern as [AdminContentScreen].
class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen>
    with SingleTickerProviderStateMixin {
  final _client = DatabaseConnection.client;

  List<TrainerApplication> _all = [];
  bool _isLoading = true;
  String? _error;

  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rows = await _client
          .from('expert_application')
          .select()
          .order('create_date', ascending: false);
      setState(() {
        _all = (rows as List)
            .map((r) =>
                TrainerApplication.fromSupabase(r as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<TrainerApplication> _filtered(String status) {
    if (status == 'all') return _all;
    return _all.where((a) => a.status == status).toList();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Trainer Applications',
            style: AppTextStyles.headlineLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accent),
            onPressed: _loadApplications,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: AppTextStyles.labelMedium,
          tabs: const [
            Tab(text: 'ALL'),
            Tab(text: 'PENDING'),
            Tab(text: 'APPROVED'),
            Tab(text: 'REJECTED'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _buildList('all'),
                    _buildList('pending'),
                    _buildList('approved'),
                    _buildList('rejected'),
                  ],
                ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Widget _buildList(String status) {
    final items = _filtered(status);
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              status == 'pending'
                  ? Icons.hourglass_empty_outlined
                  : Icons.check_circle_outline,
              size: AppIconSizes.xxl,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              status == 'all'
                  ? 'No applications yet.'
                  : 'No $status applications.',
              style:
                  AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildCard(items[index]),
      ),
    );
  }

  Widget _buildCard(TrainerApplication app) {
    final statusColor = switch (app.status) {
      'approved' => AppColors.accent,
      'rejected' => AppColors.error,
      _ => AppColors.warning,
    };

    final statusBg = switch (app.status) {
      'approved' => AppColors.acidBg,
      'rejected' => AppColors.errorBg,
      _ => AppColors.orangeBg,
    };

    return GestureDetector(
      onTap: () async {
        final changed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) =>
                VerifyTrainerScreen(applicationId: app.id),
          ),
        );
        // Refresh list if the verify screen changed the status.
        if (changed == true && mounted) _loadApplications();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.acidBg,
              child: Text(
                app.fullName.isNotEmpty
                    ? app.fullName[0].toUpperCase()
                    : '?',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.accent),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.fullName.isNotEmpty
                        ? app.fullName
                        : 'Unknown applicant',
                    style: AppTextStyles.bodyLarge,
                  ),
                  if (app.specialization.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(app.specialization, style: AppTextStyles.bodySmall),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    app.createdAt
                        .toLocal()
                        .toString()
                        .split(' ')
                        .first,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                app.status.toUpperCase(),
                style:
                    AppTextStyles.caption.copyWith(color: statusColor),
              ),
            ),

            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.error, size: AppIconSizes.xxl),
          const SizedBox(height: AppSpacing.lg),
          Text(
            _error!,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _loadApplications,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

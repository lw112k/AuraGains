import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/constants.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/admin/admin_stat_card.dart';
import '../../../widgets/admin/report_card.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Admin Panel',
          style: AppTextStyles.headlineLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accent),
            onPressed: () => context.read<AdminProvider>().loadData(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : provider.error != null
              ? _buildError(context, provider.error!)
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: () => context.read<AdminProvider>().loadData(),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      _buildWelcome(provider),
                      const SizedBox(height: AppSpacing.xl),
                      _buildStatsRow(provider),
                      const SizedBox(height: AppSpacing.xl),
                      _buildReportsSection(context, provider),
                    ],
                  ),
                ),
    );
  }

  Widget _buildWelcome(AdminProvider provider) {
    final name = provider.currentAdminUser?.username ?? 'Admin';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome back, $name', style: AppTextStyles.displayMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Here\'s what\'s happening today.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatsRow(AdminProvider provider) {
    return Row(
      children: [
        Expanded(
          child: AdminStatCard(
            title: 'Total Users',
            value: provider.userCount.toString(),
            icon: Icons.people,
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: AdminStatCard(
            title: 'Pending Reports',
            value: provider.reports.length.toString(),
            icon: Icons.flag,
            isAlert: provider.reports.isNotEmpty,
          ),
        ),
      ],
    );
  }

  Widget _buildReportsSection(BuildContext context, AdminProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pending Reports', style: AppTextStyles.headlineMedium),
        const SizedBox(height: AppSpacing.md),
        if (provider.reports.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.mdAll,
            ),
            child: const Center(
              child: Text(
                'No pending reports. All clear!',
                style: AppTextStyles.bodyMedium,
              ),
            ),
          )
        else
          ...provider.reports.map(
            (report) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ReportCard(
                report: report,
                onApprove: () => context.read<AdminProvider>().approveReport(report.id),
                onReject: () => context.read<AdminProvider>().rejectReport(report.id),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: AppSpacing.lg),
          Text(error, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: () => context.read<AdminProvider>().loadData(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

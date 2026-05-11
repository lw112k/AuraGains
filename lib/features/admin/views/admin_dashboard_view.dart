import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/admin_viewmodel.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/admin_report_card.dart';
import 'admin_content_detail_view.dart';
import 'package:auragains/features/admin/admin_palette.dart';
// Uses shared palette from AppTheme (no local palette)

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return Center(child: CircularProgressIndicator(color: AppTheme.accent));
        }
        if (vm.errorMessage != null) {
          return _ErrorState(
            message: vm.errorMessage!,
            onRetry: () => vm.loadDashboard(),
          );
        }
        return RefreshIndicator(
          color: AppTheme.accent,
          backgroundColor: AppTheme.card,
          onRefresh: vm.loadDashboard,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionLabel('PLATFORM OVERVIEW'),
              const SizedBox(height: 10),
              _StatsGrid(vm: vm),
              const SizedBox(height: 24),
              _SectionLabel('PENDING REPORT QUEUE'),
              const SizedBox(height: 10),
              _ReportQueue(vm: vm),
            ],
          ),
        );
      },
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.vm});

  final AdminViewModel vm;

  @override
  Widget build(BuildContext context) {
    final s = vm.stats;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        AdminStatCard(
          label: 'Total Users',
          value: s.totalUsers.toString(),
          icon: Icons.people_rounded,
        ),
        AdminStatCard(
          label: 'Pending Reports',
          value: s.pendingReports.toString(),
          icon: Icons.flag_rounded,
          variant: s.pendingReports > 0
              ? AdminStatVariant.warning
              : AdminStatVariant.normal,
        ),
      ],
    );
  }
}

class _ReportQueue extends StatelessWidget {
  const _ReportQueue({required this.vm});

  final AdminViewModel vm;

  @override
  Widget build(BuildContext context) {
    final reports = vm.recentReports;
    if (reports.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 36),
            const SizedBox(height: 8),
            const Text(
              'No pending reports',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'The queue is clear.',
              style: TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      children: reports
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AdminReportCard(
                report: r,
                onApprove: () => _onApprove(context, r.reportId),
                onDismiss: () => _onDismiss(context, r.reportId),
                onViewContent: r.postId != null
                    ? () => _viewContent(context, r.postId!, r.reportId)
                    : null,
              ),
            ),
          )
          .toList(),
    );
  }

  Future<void> _onApprove(BuildContext context, int reportId) async {
    final vm = context.read<AdminViewModel>();
    final ok = await vm.approveReport(reportId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Report approved.' : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? AppTheme.success : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _onDismiss(BuildContext context, int reportId) async {
    final vm = context.read<AdminViewModel>();
    final ok = await vm.dismissReport(reportId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Report dismissed.' : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? AppTheme.card : Colors.redAccent,
        ),
      );
    }
  }

  void _viewContent(BuildContext context, int postId, int reportId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminContentDetailView(
          postId: postId,
          reportId: reportId,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.muted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, color: AppTheme.muted, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.black),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

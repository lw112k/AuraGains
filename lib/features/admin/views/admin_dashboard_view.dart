import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/admin_viewmodel.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/admin_report_card.dart';
import 'admin_content_detail_view.dart';

// ─── Local palette ────────────────────────────────────────────────────────────
const Color _kBg = Color(0xFF121212);
const Color _kCard = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);
const Color _kAccent = Color(0xFF00E5FF);
const Color _kWarn = Color(0xFFFF6B35);
const Color _kSuccess = Color(0xFF00E676);
const Color _kMuted = Color(0xFF9E9E9E);

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
          return const Center(child: CircularProgressIndicator(color: _kAccent));
        }
        if (vm.errorMessage != null) {
          return _ErrorState(
            message: vm.errorMessage!,
            onRetry: () => vm.loadDashboard(),
          );
        }
        return RefreshIndicator(
          color: _kAccent,
          backgroundColor: _kCard,
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
          label: 'Total Posts',
          value: s.totalPosts.toString(),
          icon: Icons.photo_library_rounded,
        ),
        AdminStatCard(
          label: 'Pending Reports',
          value: s.pendingReports.toString(),
          icon: Icons.flag_rounded,
          variant: s.pendingReports > 0
              ? AdminStatVariant.warning
              : AdminStatVariant.normal,
        ),
        AdminStatCard(
          label: 'Pending Apps',
          value: s.pendingApplications.toString(),
          icon: Icons.assignment_rounded,
          variant: s.pendingApplications > 0
              ? AdminStatVariant.warning
              : AdminStatVariant.normal,
        ),
        AdminStatCard(
          label: 'Banned Users',
          value: s.bannedUsers.toString(),
          icon: Icons.block_rounded,
          variant: s.bannedUsers > 0
              ? AdminStatVariant.warning
              : AdminStatVariant.success,
        ),
        AdminStatCard(
          label: 'Active Users',
          value: (s.totalUsers - s.bannedUsers).toString(),
          icon: Icons.verified_user_rounded,
          variant: AdminStatVariant.success,
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
          color: _kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: _kSuccess, size: 36),
            SizedBox(height: 8),
            Text(
              'No pending reports',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4),
            Text(
              'The queue is clear.',
              style: TextStyle(color: _kMuted, fontSize: 13),
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
          backgroundColor: ok ? _kSuccess : Colors.redAccent,
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
          backgroundColor: ok ? _kCard : Colors.redAccent,
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
      style: const TextStyle(
        color: _kMuted,
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
            const Icon(Icons.cloud_off_rounded, color: _kMuted, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: _kAccent, foregroundColor: Colors.black),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

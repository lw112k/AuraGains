import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_model.dart';
import '../view_models/admin_report_viewmodel.dart';
import '../view_models/admin_viewmodel.dart';
import '../widgets/admin_report_card.dart';
import 'admin_content_detail_view.dart';
import 'package:auragains/features/admin/admin_palette.dart';

/// Standalone view for managing content reports.
/// Has its own ChangeNotifierProvider scoped locally.
class AdminReportsView extends StatelessWidget {
  const AdminReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminReportViewModel>(
      create: (_) => AdminReportViewModel(),
      child: const _ReportsShell(),
    );
  }
}

class _ReportsShell extends StatefulWidget {
  const _ReportsShell();

  @override
  State<_ReportsShell> createState() => _ReportsShellState();
}

class _ReportsShellState extends State<_ReportsShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminReportViewModel>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminReportViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          appBar: AppBar(
            backgroundColor: AppTheme.card,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Reports',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          body: vm.isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: AppTheme.accent),
                )
              : RefreshIndicator(
                  color: AppTheme.accent,
                  backgroundColor: AppTheme.card,
                  onRefresh: vm.loadReports,
                  child: vm.filteredReports.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 80),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.flag_rounded,
                                      size: 40, color: AppTheme.muted),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No reports found.',
                                    style: TextStyle(color: AppTheme.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: vm.filteredReports.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final report = vm.filteredReports[i];
                            return AdminReportCard(
                              report: report,
                              onApprove: () =>
                                  _onApprove(ctx, vm, report.reportId),
                              onDismiss: () =>
                                  _onReject(ctx, vm, report.reportId),
                              onViewContent: (report.postId != null || report.targetType == 'comment')
                                  ? () => _viewContent(
                                      ctx, vm, report)
                                  : null,
                            );
                          },
                        ),
                ),
        );
      },
    );
  }

  Future<void> _onApprove(
    BuildContext context,
    AdminReportViewModel vm,
    int reportId,
  ) async {
    final ok = await vm.approveReport(reportId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              ok ? 'Report approved.' : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? AppTheme.success : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _onReject(
    BuildContext context,
    AdminReportViewModel vm,
    int reportId,
  ) async {
    final ok = await vm.rejectReport(reportId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              ok ? 'Report rejected.' : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? AppTheme.card : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _viewContent(
    BuildContext context,
    AdminReportViewModel vm,
    AdminReportModel report,
  ) async {
    // Resolve the parent post ID — for post reports it's targetId,
    // for comment reports we fetch the comment's post_id.
    final postId = report.targetType == 'comment'
        ? await vm.resolveParentPostIdForReport(report.reportId)
        : report.targetId;

    if (postId == null) {
      if (report.targetType == 'comment' && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find the parent post for this comment.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final adminVm = context.read<AdminViewModel>();
    if (!context.mounted) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ChangeNotifierProvider<AdminViewModel>.value(
          value: adminVm,
          child: AdminContentDetailView(
            postId: postId,
            reportId: report.reportId,
          ),
        ),
      ),
    );
    // If an action was taken in content detail, refresh this VM's report list too
    if (changed == true && context.mounted) {
      vm.loadReports();
    }
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/admin_viewmodel.dart';
import '../widgets/admin_report_card.dart';
import 'admin_content_detail_view.dart';
import 'package:auragains/features/admin/admin_palette.dart';

class AdminReportsView extends StatefulWidget {
  const AdminReportsView({super.key});

  @override
  State<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends State<AdminReportsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return Center(child: CircularProgressIndicator(color: AppTheme.accent));
        }

        return Column(
          children: [
            // ─ Status filter ────────────────────────────
            _StatusTabBar(
              current: vm.reportStatusFilter,
              onChanged: vm.setReportStatusFilter,
            ),

            // ─ List ─────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.accent,
                backgroundColor: AppTheme.card,
                onRefresh: vm.loadReports,
                child: vm.filteredReports.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Text(
                              'No reports found.',
                              style: TextStyle(color: AppTheme.muted),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: vm.filteredReports.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final r = vm.filteredReports[i];
                          return AdminReportCard(
                            report: r,
                            onApprove: () => _onApprove(ctx, vm, r.reportId),
                            onDismiss: () => _onDismiss(ctx, vm, r.reportId),
                            onViewContent: r.postId != null
                                ? () => _viewContent(ctx, r.postId!, r.reportId)
                                : null,
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onApprove(
      BuildContext context, AdminViewModel vm, int reportId) async {
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

  Future<void> _onDismiss(
      BuildContext context, AdminViewModel vm, int reportId) async {
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

class _StatusTabBar extends StatelessWidget {
  const _StatusTabBar({required this.current, required this.onChanged});

  final String? current;
  final void Function(String?) onChanged;

  static const _tabs = [
    (label: 'All', value: null),
    (label: 'Pending', value: 'pending'),
    (label: 'Approved', value: 'approved'),
    (label: 'Dismissed', value: 'dismissed'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: _tabs.map((t) {
          final active = current == t.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(t.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? AppTheme.accent.withOpacity(0.15) : AppTheme.card,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: active ? AppTheme.accent : AppTheme.border),
                ),
                child: Text(
                  t.label,
                  style: TextStyle(
                    color: active ? AppTheme.accent : AppTheme.muted,
                    fontSize: 12,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

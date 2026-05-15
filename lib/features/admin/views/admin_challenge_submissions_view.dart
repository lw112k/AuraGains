import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/admin_challenge_viewmodel.dart';
import '../widgets/admin_submission_card.dart';
import 'package:auragains/features/admin/admin_palette.dart';

/// Standalone view for managing challenge submissions.
/// Used inside the Submissions tab of AdminChallengesView.
class AdminChallengeSubmissionsView extends StatefulWidget {
  const AdminChallengeSubmissionsView({super.key});

  @override
  State<AdminChallengeSubmissionsView> createState() =>
      _AdminChallengeSubmissionsViewState();
}

class _AdminChallengeSubmissionsViewState
    extends State<AdminChallengeSubmissionsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminChallengeViewModel>().loadSubmissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminChallengeViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.accent),
          );
        }

        return Column(
          children: [
            // ─ Filter bar ──────────────────────────────
            _FilterBar(
              current: vm.submissionFilter,
              onChanged: vm.setSubmissionFilter,
            ),

            // ─ List ────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.accent,
                backgroundColor: AppTheme.card,
                onRefresh: vm.loadSubmissions,
                child: vm.filteredSubmissions.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.inbox_rounded,
                                    size: 40, color: AppTheme.muted),
                                const SizedBox(height: 8),
                                Text(
                                  'No submissions found.',
                                  style: TextStyle(color: AppTheme.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: vm.filteredSubmissions.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final sub = vm.filteredSubmissions[i];
                          return AdminSubmissionCard(
                            submission: sub,
                            onApprove: () =>
                                _onApprove(ctx, vm, sub.challSubmissionId),
                            onReject: () =>
                                _onReject(ctx, vm, sub.challSubmissionId),
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
    BuildContext context,
    AdminChallengeViewModel vm,
    int id,
  ) async {
    final ok = await vm.approveSubmission(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Submission approved!' : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? AppTheme.success : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _onReject(
    BuildContext context,
    AdminChallengeViewModel vm,
    int id,
  ) async {
    // Show bottom sheet for reject reason
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _RejectReasonSheet(),
    );

    if (reason == null || reason.trim().isEmpty || !context.mounted) return;

    final ok = await vm.rejectSubmission(id, reason.trim());
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Submission rejected.' : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? AppTheme.card : Colors.redAccent,
        ),
      );
    }
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.current,
    required this.onChanged,
  });

  final String current;
  final void Function(String) onChanged;

  static const _tabs = [
    (label: 'Pending', value: 'pending'),
    (label: 'All', value: 'all'),
    (label: 'Approved', value: 'approved'),
    (label: 'Rejected', value: 'rejected'),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.accent.withOpacity(0.15)
                      : AppTheme.card,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: active ? AppTheme.accent : AppTheme.border,
                  ),
                ),
                child: Text(
                  t.label,
                  style: TextStyle(
                    color: active ? AppTheme.accent : AppTheme.muted,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
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

// ─── Reject reason bottom sheet ─────────────────────────────────────────

class _RejectReasonSheet extends StatefulWidget {
  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reject Submission',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Provide a reason for rejection:',
              style: TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: 3,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Insufficient evidence...',
                hintStyle: TextStyle(color: AppTheme.muted),
                filled: true,
                fillColor: AppTheme.backgroundDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.accent),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.muted,
                      side: BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () =>
                        Navigator.pop(context, _ctrl.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.warn,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

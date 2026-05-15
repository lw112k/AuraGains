import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/admin_challenge_viewmodel.dart';
import '../widgets/admin_challenge_card.dart';
import 'admin_challenge_form_view.dart';
import 'admin_challenge_submissions_view.dart';
import 'package:auragains/features/admin/admin_palette.dart';

/// Tab shell for challenges management.
/// Contains two tabs: Challenges (list) and Submissions.
class AdminChallengesView extends StatelessWidget {
  const AdminChallengesView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AdminChallengeViewModel>(
      create: (_) => AdminChallengeViewModel(),
      child: const _ChallengesShell(),
    );
  }
}

class _ChallengesShell extends StatefulWidget {
  const _ChallengesShell();

  @override
  State<_ChallengesShell> createState() => _ChallengesShellState();
}

class _ChallengesShellState extends State<_ChallengesShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        final vm = context.read<AdminChallengeViewModel>();
        vm.setTabIndex(_tabCtrl.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminChallengeViewModel>().loadChallenges();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminChallengeViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Challenges',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.muted,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Challenges'),
            Tab(text: 'Submissions'),
          ],
        ),
        actions: [
          if (_tabCtrl.index == 0)
            IconButton(
              icon: const Icon(Icons.add_rounded, color: AppTheme.accent),
              tooltip: 'Create Challenge',
              onPressed: () => _navigateToCreate(context),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Tab 0: Challenges List
          _ChallengesTab(vm: vm),
          // Tab 1: Submissions
          const AdminChallengeSubmissionsView(),
        ],
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<AdminChallengeViewModel>.value(
          value: context.read<AdminChallengeViewModel>(),
          child: const AdminChallengeFormView(),
        ),
      ),
    );
  }
}

// ─── Challenges List Tab ─────────────────────────────────────────────────

class _ChallengesTab extends StatelessWidget {
  const _ChallengesTab({required this.vm});

  final AdminChallengeViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      );
    }

    return RefreshIndicator(
      color: AppTheme.accent,
      backgroundColor: AppTheme.card,
      onRefresh: vm.loadChallenges,
      child: vm.challenges.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          size: 40, color: AppTheme.muted),
                      const SizedBox(height: 8),
                      Text(
                        'No challenges yet.',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vm.challenges.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final challenge = vm.challenges[i];
                return AdminChallengeCard(
                  challenge: challenge,
                  isActionLoading: vm.isActionLoading,
                  onEdit: () => _navigateToEdit(ctx, challenge),
                  onDelete: () => _onDelete(ctx, challenge.challId),
                  onToggleActive: (v) => vm.toggleActive(
                    challenge.challId,
                    v,
                  ),
                );
              },
            ),
    );
  }

  void _navigateToEdit(BuildContext context, dynamic challenge) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<AdminChallengeViewModel>.value(
          value: context.read<AdminChallengeViewModel>(),
          child: AdminChallengeFormView(existingChallenge: challenge),
        ),
      ),
    );
  }

  Future<void> _onDelete(BuildContext context, int challengeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text(
          'Delete Challenge?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This will permanently delete this challenge. This action cannot be undone.',
          style: TextStyle(color: AppTheme.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: TextStyle(color: AppTheme.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.warn),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final vm = context.read<AdminChallengeViewModel>();
    final ok = await vm.deleteChallenge(challengeId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              ok ? 'Challenge deleted.' : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? AppTheme.card : Colors.redAccent,
        ),
      );
    }
  }
}

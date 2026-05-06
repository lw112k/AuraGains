import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/constants.dart';
import '../models/app_user_model.dart';
import '../models/trainer_application_model.dart';
import '../view_models/verify_trainer_viewmodel.dart';

// NOTES ON PROTOTYPE DIFFERENCES:
// • cached_network_image   — NOT in pubspec.yaml → NetworkImage / CircleAvatar
// • go_router / context.pop() — NOT in pubspec → Navigator.of(context).pop()
// • AppNavBar              — currently an empty file → AppBar used directly
// • LoadingSpinner         — currently an empty file → CircularProgressIndicator
// • AppInputDecoration.standard() — doesn't exist → built inline
// • AppRadius.xl           — doesn't exist → 16.0
// • AppTextStyles.statSmall — doesn't exist → AppTextStyles.statMedium
// • CertificationCard widget — doesn't exist → private _CertCard built here
// • AdminProvider          — doesn't exist → VerifyTrainerViewModel
// • Application.certification — no such field; TrainerApplication.specialization used
// • Application.specialties (List) — no such field; specialization (String) split on ','
// • Application.appliedAt  — no such field; TrainerApplication.createdAt used
// • Application.appliedAt + fake offsets → cert issue/expiry not in schema; omitted
// • User.name              — not on AppUser; TrainerApplication.fullName used
// • User.avatar            — AppUser.avatarUrl
// • User.bio               — not on AppUser; TrainerApplication.bio used
// • User.followers/posts   — NOT in DB schema → replaced with real postCount
//                            and yearsExperience stats from the application row
// • User.isVerified        — AppUser.isExpert (role == 'expert')
// • AdminProvider.verifyTrainer(id) → VerifyTrainerViewModel.approveApplication()

/// Admin detail screen for reviewing and approving a trainer application.
///
/// Wraps itself in a local [ChangeNotifierProvider<VerifyTrainerViewModel>]
/// so it is fully self-contained — no changes to main.dart are needed.
///
/// Data sources (all via [VerifyTrainerViewModel] → [AdminRepository] → Supabase):
///   Application detail  → `trainer_applications` (single row by id)
///   User profile        → `users` (single row by user_id from application)
///   Post count          → `posts` (count where user_id = userId)
///   Report count        → `reports` (count where reporter_id = userId)
///   Approve             → `trainer_applications.status = 'approved'`
///                         + `users.role = 'expert'`
///   Reject              → `trainer_applications.status = 'rejected'`
class VerifyTrainerScreen extends StatelessWidget {
  const VerifyTrainerScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          VerifyTrainerViewModel(applicationId: applicationId),
      child: const _VerifyTrainerView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private stateful view — owns the expand-bio toggle
// ─────────────────────────────────────────────────────────────────────────────

class _VerifyTrainerView extends StatefulWidget {
  const _VerifyTrainerView();

  @override
  State<_VerifyTrainerView> createState() => _VerifyTrainerViewState();
}

class _VerifyTrainerViewState extends State<_VerifyTrainerView> {
  bool _showFullBio = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      // AppNavBar is currently an empty file — using AppBar directly.
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white, size: AppIconSizes.md),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('VERIFY TRAINER', style: AppTextStyles.displaySmall),
        centerTitle: false,
      ),
      body: Consumer<VerifyTrainerViewModel>(
        builder: (context, vm, _) {
          // ── Full-screen loading ───────────────────────────────────────
          if (vm.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.acid),
            );
          }

          // ── Error / not-found state ───────────────────────────────────
          if (vm.error != null || vm.application == null) {
            return _buildErrorState(context, vm);
          }

          final application = vm.application!;
          final user = vm.user;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.mdd),
            children: [
              _buildHeader(application, user, vm.memberSince),
              const SizedBox(height: AppSpacing.md),
              _buildQuickStats(
                application.yearsExperience,
                vm.postCount,
                vm.reportCount,
              ),
              const SizedBox(height: AppSpacing.md),
              // ── Certification documents section ──────────────────────
              Text('CERTIFICATIONS', style: AppTextStyles.displayMedium),
              const SizedBox(height: AppSpacing.sm),
              if (application.certUrls.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppRadius.cardBorder,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'No certification documents uploaded.',
                    style: AppTextStyles.bodyMedium,
                  ),
                )
              else
                ...application.certUrls
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _CertCard(
                          index: entry.key + 1,
                          url: entry.value,
                          isVerified:
                              application.status.toLowerCase() ==
                                  'approved',
                          onView: () =>
                              _showCertDialog(context, entry.value),
                        ),
                      ),
                    ),
              const SizedBox(height: AppSpacing.md),
              _buildBioSection(application.bio),
              const SizedBox(height: AppSpacing.md),
              _buildSpecialties(application.specialization),
              const SizedBox(height: AppSpacing.md),
              _buildChecklist(application),
              const SizedBox(height: AppSpacing.lg),
              // ── Approve/reject action spinner ─────────────────────────
              if (vm.isActionInProgress)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.md),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.acid),
                  ),
                ),
              _buildDecisionButtons(context, vm, application),
            ],
          );
        },
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    TrainerApplication application,
    AppUser? user,
    String memberSince,
  ) {
    // fullName comes from the application row.
    // username / avatarUrl come from AppUser; fall back gracefully if null.
    final fullName = application.fullName.isNotEmpty
        ? application.fullName
        : user?.username ?? 'Unknown';
    final username = user?.username ?? '';
    final avatarUrl = user?.avatarUrl ?? '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          // cached_network_image not in pubspec — using NetworkImage.
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.acidBg,
            backgroundImage:
                avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            onBackgroundImageError: avatarUrl.isNotEmpty
                ? (_, __) {}
                : null,
            child: avatarUrl.isEmpty
                ? Text(
                    fullName.isNotEmpty
                        ? fullName[0].toUpperCase()
                        : '?',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.black),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prototype used trainer.name — AppUser has no `name`.
                // TrainerApplication.fullName is the equivalent.
                Text(fullName, style: AppTextStyles.displayMedium),
                const SizedBox(height: AppSpacing.xxs),
                if (username.isNotEmpty)
                  Text(
                    '@$username',
                    style: AppTextStyles.monoSmall
                        .copyWith(color: AppColors.acid),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  memberSince.isNotEmpty
                      ? 'Member since $memberSince'
                      : 'Member since unknown',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    // Prototype showed followers & posts from User model
                    // (not in DB schema). Replaced with years experience
                    // (meaningful, from TrainerApplication) and gender.
                    _MiniStat(
                        label: 'Exp',
                        value:
                            '${application.yearsExperience} yrs'),
                    const SizedBox(width: AppSpacing.sm),
                    if (application.gender.isNotEmpty)
                      _MiniStat(
                          label: 'Gender',
                          value: application.gender),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Quick-stat grid ──────────────────────────────────────────────────────────

  Widget _buildQuickStats(
      int yearsExperience, int postCount, int reportCount) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      childAspectRatio: 1,
      children: [
        _QuickStatCard(
          label: 'Years Exp',
          value: '$yearsExperience',
          accent: AppColors.acid,
        ),
        // Prototype showed a hardcoded 'Avg Interaction' stat.
        // Replaced with actual post count — real data from `posts` table.
        _QuickStatCard(
          label: 'Posts',
          value: '$postCount',
        ),
        _QuickStatCard(
          label: 'Reports',
          value: '$reportCount',
          // Accent orange if they've filed any reports; acid otherwise.
          accent: reportCount > 0 ? AppColors.orange : AppColors.acid,
        ),
      ],
    );
  }

  // ── Bio section ──────────────────────────────────────────────────────────────

  Widget _buildBioSection(String bio) {
    final displayBio = bio.isNotEmpty
        ? bio
        : 'No bio provided.';
    final shouldTruncate = displayBio.length > 140;
    final visible = !_showFullBio && shouldTruncate
        ? '${displayBio.substring(0, 140)}...'
        : displayBio;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PROFESSIONAL BIO', style: AppTextStyles.monoLabel),
          const SizedBox(height: AppSpacing.sm),
          Text(visible, style: AppTextStyles.bodyMedium),
          if (shouldTruncate) ...[
            const SizedBox(height: AppSpacing.sm),
            GestureDetector(
              onTap: () =>
                  setState(() => _showFullBio = !_showFullBio),
              child: Text(
                _showFullBio ? 'Show less' : 'Read more',
                style: AppTextStyles.monoSmall
                    .copyWith(color: AppColors.acid),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Specialties section ──────────────────────────────────────────────────────
  // Prototype had Application.specialties as List<String>.
  // TrainerApplication.specialization is a single String — split on ',' for chips.

  Widget _buildSpecialties(String specialization) {
    final items = specialization
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SPECIALTIES', style: AppTextStyles.monoLabel),
          const SizedBox(height: AppSpacing.sm),
          items.isEmpty
              ? Text('No specialties listed.',
                  style: AppTextStyles.bodyMedium)
              : Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: items
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.acidBg,
                            borderRadius: BorderRadius.circular(
                                AppRadius.pill),
                          ),
                          child: Text(
                            item,
                            style: AppTextStyles.monoSmall
                                .copyWith(color: AppColors.acid),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }

  // ── Verification checklist ───────────────────────────────────────────────────

  Widget _buildChecklist(TrainerApplication application) {
    final approved =
        application.status.toLowerCase() == 'approved';
    final hasCerts = application.certUrls.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VERIFICATION CHECKLIST', style: AppTextStyles.monoLabel),
          const SizedBox(height: AppSpacing.sm),
          _ChecklistRow(
            label: 'Certification documents uploaded',
            complete: hasCerts,
          ),
          const SizedBox(height: AppSpacing.xs),
          const _ChecklistRow(
            label: 'Application submitted',
            complete: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          _ChecklistRow(
            label: 'Final admin approval',
            complete: approved,
          ),
        ],
      ),
    );
  }

  // ── Decision buttons ─────────────────────────────────────────────────────────

  Widget _buildDecisionButtons(
    BuildContext context,
    VerifyTrainerViewModel vm,
    TrainerApplication application,
  ) {
    final alreadyApproved =
        application.status.toLowerCase() == 'approved';
    final alreadyRejected =
        application.status.toLowerCase() == 'rejected';

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: vm.isActionInProgress || alreadyApproved
                ? null
                : () => _approveTrainer(context, vm),
            style: AppButtonStyles.primary,
            child: Text(alreadyApproved
                ? '✓ ALREADY APPROVED'
                : '✓ APPROVE & GRANT BADGE'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: vm.isActionInProgress || alreadyRejected
                ? null
                : () => _showRequestInfoSheet(
                    context, vm, application.fullName),
            style: AppButtonStyles.danger,
            child: const Text('⚠ REQUEST MORE INFO'),
          ),
        ),
      ],
    );
  }

  // ── Certificate dialog ────────────────────────────────────────────────────────
  // Opens when the user taps "View Certificate" on a _CertCard.
  // Shows the raw URL — a proper document viewer can be wired in later.

  void _showCertDialog(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Certificate Document',
            style: AppTextStyles.labelLarge),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Document URL:',
                style: AppTextStyles.monoSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                url,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.acid),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Connect a document/image viewer here when available.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Close', style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  // ── Approve action ────────────────────────────────────────────────────────────

  Future<void> _approveTrainer(
    BuildContext context,
    VerifyTrainerViewModel vm,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    // Prototype used trainer.name; we use application.fullName.
    final name = vm.application?.fullName ?? 'this trainer';

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: AppColors.card,
            title: Text('Approve trainer',
                style: AppTextStyles.labelLarge),
            content: Text(
              'Grant verified expert badge to $name?',
              style: AppTextStyles.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(false),
                child: Text('Cancel',
                    style: AppTextStyles.bodyMedium),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(true),
                child: Text('Approve',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.acid)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      // Runs approveApplication in `trainer_applications` AND promotes
      // `users.role` to 'expert' in parallel — see AdminRepository.
      await vm.approveApplication();
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
            content:
                Text('$name approved as expert trainer.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
          SnackBar(content: Text('Error: $e')));
    }
  }

  // ── Request-more-info bottom sheet ───────────────────────────────────────────
  // Prototype used AppInputDecoration.standard() — doesn't exist → inline.
  // The "send" action currently just shows a SnackBar (no backend messaging
  // table exists for admin→applicant notes yet).

  Future<void> _showRequestInfoSheet(
    BuildContext context,
    VerifyTrainerViewModel vm,
    String trainerName,
  ) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        // AppRadius.xl doesn't exist — 16.0 is the closest logical value.
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.mdd,
          AppSpacing.mdd,
          AppSpacing.mdd,
          MediaQuery.of(sheetContext).viewInsets.bottom +
              AppSpacing.mdd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Request More Info',
                style: AppTextStyles.displayMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Send a note to $trainerName for missing details.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            // AppInputDecoration.standard() doesn't exist → inline.
            TextField(
              controller: controller,
              maxLines: 4,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'What additional information do you need?',
                hintStyle: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.steel,
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.inputBorder,
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.inputBorder,
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.inputBorder,
                  borderSide:
                      const BorderSide(color: AppColors.acid),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // TODO: Wire to a real admin-notes / messaging endpoint
                // when the team adds that feature.
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  messenger.showSnackBar(
                    const SnackBar(
                        content:
                            Text('Request for more info sent.')),
                  );
                },
                style: AppButtonStyles.danger,
                child: const Text('Send Request'),
              ),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
  }

  // ── Error state ──────────────────────────────────────────────────────────────

  Widget _buildErrorState(
      BuildContext context, VerifyTrainerViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              vm.error ?? 'Application not found.',
              style: AppTextStyles.labelLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: vm.loadAll,
              style: AppButtonStyles.primary,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CertCard — replaces the prototype's CertificationCard widget
// (CertificationCard from widgets/admin/ does not exist in this project)
// Shows a single cert URL from TrainerApplication.certUrls.
// ─────────────────────────────────────────────────────────────────────────────

class _CertCard extends StatelessWidget {
  const _CertCard({
    required this.index,
    required this.url,
    required this.isVerified,
    required this.onView,
  });

  final int index;
  final String url;
  final bool isVerified;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    // Display the last path segment of the URL as the file name,
    // falling back to the full URL if parsing fails.
    final displayName = Uri.tryParse(url)?.pathSegments.lastOrNull ?? url;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Doc icon with verified tint
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isVerified
                  ? AppColors.acidBg
                  : AppColors.orangeBg,
              borderRadius: AppRadius.cardBorder,
            ),
            child: Icon(
              isVerified
                  ? Icons.verified_rounded
                  : Icons.insert_drive_file_outlined,
              color: isVerified ? AppColors.acid : AppColors.orange,
              size: AppIconSizes.md,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Certification Document $index',
                  style: AppTextStyles.labelMedium,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  displayName,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  isVerified ? 'VERIFIED' : 'PENDING REVIEW',
                  style: AppTextStyles.monoLabel.copyWith(
                    color:
                        isVerified ? AppColors.acid : AppColors.orange,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onView,
            child: Text(
              'VIEW',
              style:
                  AppTextStyles.monoSmall.copyWith(color: AppColors.acid),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QuickStatCard — small stat tile in the 3-column grid
// Prototype used AppTextStyles.statSmall — doesn't exist → statMedium used.
// ─────────────────────────────────────────────────────────────────────────────

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.label,
    required this.value,
    this.accent = AppColors.white,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.cardBorder,
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AppTextStyles.statSmall doesn't exist → statMedium used.
          Text(value,
              style: AppTextStyles.statMedium.copyWith(color: accent)),
          const SizedBox(height: AppSpacing.xxs),
          Text(label,
              textAlign: TextAlign.center,
              style: AppTextStyles.monoSmall),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MiniStat — small label: value pill in the header row
// ─────────────────────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.steel,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$label: $value',
        style: AppTextStyles.monoSmall.copyWith(color: AppColors.white),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ChecklistRow — icon + label row for the verification checklist
// ─────────────────────────────────────────────────────────────────────────────

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.label, required this.complete});

  final String label;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          complete
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked,
          color: complete ? AppColors.acid : AppColors.orange,
          size: AppIconSizes.md,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }
}

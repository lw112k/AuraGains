import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:auragains/features/admin/admin_palette.dart';
import '../models/trainer_application_model.dart';
import '../repositories/admin_repository.dart';

/// Shows the full detail of a trainer application.
///
/// Admin can Approve (grants the expert badge) or Reject the application.
/// On success the screen pops with `true` so [ApplicationsScreen] can
/// refresh its list.
class VerifyTrainerScreen extends StatefulWidget {
  final String applicationId;

  const VerifyTrainerScreen({super.key, required this.applicationId});

  @override
  State<VerifyTrainerScreen> createState() => _VerifyTrainerScreenState();
}

class _VerifyTrainerScreenState extends State<VerifyTrainerScreen> {
  final _repo = AdminRepository();

  TrainerApplication? _app;
  bool _isLoading = true;
  String? _error;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Data ───────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final row = await _repo.fetchApplicationById(widget.applicationId);
      setState(() {
        _app = row != null ? TrainerApplication.fromSupabase(row) : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _approve() async {
    if (_app == null || _isActing) return;
    final confirmed = await _confirm(
      title: 'Approve Application',
      message:
          'Grant ${_app!.fullName.isNotEmpty ? _app!.fullName : "this applicant"} the Expert badge and promote their account?',
      confirmLabel: 'Approve',
      confirmColor: AppColors.accent,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isActing = true);
    try {
      await _repo.approveApplication(widget.applicationId, _app!.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Application approved — Expert badge granted.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
        setState(() => _isActing = false);
      }
    }
  }

  Future<void> _reject() async {
    if (_app == null || _isActing) return;
    final confirmed = await _confirm(
      title: 'Reject Application',
      message: 'Decline this trainer application? This cannot be undone.',
      confirmLabel: 'Reject',
      confirmColor: AppColors.error,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isActing = true);
    try {
      await _repo.rejectApplication(widget.applicationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Application rejected.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
        setState(() => _isActing = false);
      }
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: AppTextStyles.headlineMedium),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text(confirmLabel, style: TextStyle(color: confirmColor)),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title:
            const Text('Verify Trainer', style: AppTextStyles.headlineLarge),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? Center(
                  child:
                      Text(_error!, style: AppTextStyles.bodyMedium))
              : _app == null
                  ? const Center(
                      child: Text('Application not found.',
                          style: AppTextStyles.bodyMedium))
                  : _buildDetail(_app!),
    );
  }

  Widget _buildDetail(TrainerApplication app) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Resolved banner ───────────────────────────────────────────
          if (!app.isPending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              decoration: BoxDecoration(
                color: app.isApproved ? AppColors.acidBg : AppColors.errorBg,
                borderRadius: AppRadius.mdAll,
              ),
              child: Text(
                app.isApproved
                    ? 'This application has been APPROVED.'
                    : 'This application has been REJECTED.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color:
                      app.isApproved ? AppColors.accent : AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // ── Applicant header ──────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.acidBg,
                child: Text(
                  app.fullName.isNotEmpty
                      ? app.fullName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.headlineLarge
                      .copyWith(color: AppColors.accent),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.fullName.isNotEmpty
                          ? app.fullName
                          : 'Unknown Applicant',
                      style: AppTextStyles.displayMedium,
                    ),
                    if (app.email.isNotEmpty)
                      Text(app.email, style: AppTextStyles.bodySmall),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Applied: ${app.createdAt.toLocal().toString().split(' ').first}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Info chips ────────────────────────────────────────────────
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (app.specialization.isNotEmpty)
                _InfoChip(
                    label: app.specialization,
                    icon: Icons.fitness_center_outlined),
              if (app.gender.isNotEmpty)
                _InfoChip(
                    label: app.gender, icon: Icons.person_outline),
              if (app.yearsExperience > 0)
                _InfoChip(
                    label: '${app.yearsExperience} yrs experience',
                    icon: Icons.timer_outlined),
            ],
          ),

          const SizedBox(height: AppSpacing.xxl),

          // ── Bio ───────────────────────────────────────────────────────
          if (app.bio.isNotEmpty) ...[
            const Text('About', style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: AppColors.border),
              ),
              child: Text(app.bio, style: AppTextStyles.bodyMedium),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],

          // ── Certifications ────────────────────────────────────────────
          if (app.certUrls.isNotEmpty) ...[
            const Text('Certifications', style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            ...app.certUrls.map((url) => _CertTile(url: url)),
            const SizedBox(height: AppSpacing.xxl),
          ],

          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.xxl),

          // ── Action buttons (only for pending applications) ────────────
          if (app.isPending) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isActing ? null : _approve,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg),
                  disabledBackgroundColor: AppColors.acidBg,
                ),
                icon: _isActing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.background),
                      )
                    : const Icon(Icons.verified_outlined),
                label: const Text('Approve & Grant Expert Badge'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isActing ? null : _reject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg),
                ),
                icon: const Icon(Icons.close),
                label: const Text('Reject Application'),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ],
      ),
    );
  }
}

// ── Private helper widgets ────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.acidBg,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.accent.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: AppSpacing.xs),
          Text(label,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.accent)),
        ],
      ),
    );
  }
}

class _CertTile extends StatelessWidget {
  const _CertTile({required this.url});

  final String url;

  bool get _isImage {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    if (_isImage) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        height: 180,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: AppRadius.mdAll,
          color: AppColors.surfaceVariant,
        ),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, __) => const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
          errorWidget: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, color: AppColors.textMuted),
          ),
        ),
      );
    }

    // Non-image cert (PDF or other link)
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              url.split('/').last,
              style: AppTextStyles.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.open_in_new,
              size: AppIconSizes.xs, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

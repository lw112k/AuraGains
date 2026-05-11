import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/admin_viewmodel.dart';
import 'package:auragains/features/admin/admin_palette.dart';

class AdminVerifyView extends StatelessWidget {
  const AdminVerifyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.card,
        foregroundColor: Colors.white,
        title: const Text(
          'Verify Application',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<AdminViewModel>(
        builder: (context, vm, _) {
          final app = vm.detailApplication;
          if (app == null) {
            return Center(
              child: Text('No application selected.',
                  style: TextStyle(color: AppTheme.muted)),
            );
          }

          final isPending = (app.applicationStatus ?? 'pending') == 'pending';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─ Applicant card ─────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Avatar(
                            url: app.profilePicUrl,
                            name: app.username ?? '?'),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app.username ?? '(unknown)',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700),
                              ),
                              if (app.email != null)
                                Text(
                                  app.email!,
                                    style: TextStyle(
                                      color: AppTheme.muted, fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─ Expert details ─────────────────────────
              _SectionLabel('EXPERT TITLE'),
              const SizedBox(height: 6),
              _InfoBox(
                  text: app.expertTitle ?? '(not provided)'),
              const SizedBox(height: 14),

              _SectionLabel('EXPERIENCE'),
              const SizedBox(height: 6),
              _InfoBox(
                text: app.experienceYears != null
                    ? '${app.experienceYears} year${app.experienceYears! == 1 ? '' : 's'}'
                    : '(not provided)',
              ),
              const SizedBox(height: 14),

              _SectionLabel('BIO / DESCRIPTION'),
              const SizedBox(height: 6),
              _InfoBox(
                  text: app.experienceDescription ?? '(not provided)'),
              const SizedBox(height: 14),

              // ─ Supporting images ──────────────────────
              if (app.imageUrls.isNotEmpty) ...[
                _SectionLabel('SUPPORTING IMAGES (${app.imageUrls.length})'),
                const SizedBox(height: 8),
                ...app.imageUrls.map(
                  (url) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 120,
                          color: AppTheme.card,
                          child: Center(
                            child: Icon(Icons.broken_image_rounded,
                                color: AppTheme.muted),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // ─ Applied date ───────────────────────────
              if (app.createDate != null) ...[
                Text(
                  'Applied ${_fmtDate(app.createDate!)}',
                  style: TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
                const SizedBox(height: 20),
              ],

              // ─ Decision actions ───────────────────────
              if (isPending) ...[
                _SectionLabel('DECISION'),
                const SizedBox(height: 10),
                if (vm.isActionLoading)
                  Center(
                      child: CircularProgressIndicator(color: AppTheme.accent))
                else ...[
                  FilledButton.icon(
                    onPressed: () => _onApprove(context, vm, app),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Approve Application'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.success.withOpacity(0.15),
                      foregroundColor: AppTheme.success,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _onReject(context, vm, app),
                    icon: const Icon(Icons.cancel_rounded),
                    label: const Text('Reject Application'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ] else
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      'Status: ${(app.applicationStatus ?? 'pending').toUpperCase()}',
                      style: TextStyle(color: AppTheme.muted, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Future<void> _onApprove(
      BuildContext context, AdminViewModel vm, dynamic app) async {
    final ok = await vm.approveApplication(app.applicationId, app.userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(ok ? 'Application approved!' : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? AppTheme.success : Colors.redAccent,
        ),
      );
      if (ok) Navigator.of(context).pop();
    }
  }

  Future<void> _onReject(
      BuildContext context, AdminViewModel vm, dynamic app) async {
    final ok = await vm.rejectApplication(app.applicationId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(ok ? 'Application rejected.' : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? AppTheme.card : Colors.redAccent,
        ),
      );
      if (ok) Navigator.of(context).pop();
    }
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
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

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white70, fontSize: 14, height: 1.5),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFF2A2A2A),
        backgroundImage: NetworkImage(url!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: AppTheme.accent.withOpacity(0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
        color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 18),
      ),
    );
  }
}

String _fmtDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

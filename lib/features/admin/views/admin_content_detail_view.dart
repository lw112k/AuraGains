import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/admin_viewmodel.dart';

const Color _kBg = Color(0xFF121212);
const Color _kCard = Color(0xFF1E1E1E);
const Color _kBorder = Color(0xFF2A2A2A);
const Color _kAccent = Color(0xFF00E5FF);
const Color _kWarn = Color(0xFFFF6B35);
const Color _kSuccess = Color(0xFF00E676);
const Color _kMuted = Color(0xFF9E9E9E);

class AdminContentDetailView extends StatefulWidget {
  const AdminContentDetailView({
    super.key,
    required this.postId,
    this.reportId,
  });

  final int postId;
  final int? reportId;

  @override
  State<AdminContentDetailView> createState() => _AdminContentDetailViewState();
}

class _AdminContentDetailViewState extends State<AdminContentDetailView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadContentDetail(
            widget.postId,
            widget.reportId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        foregroundColor: Colors.white,
        title: const Text(
          'Content Detail',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      body: Consumer<AdminViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: _kAccent));
          }
          if (vm.detailPost == null) {
            return const Center(
              child: Text('Post not found.', style: TextStyle(color: _kMuted)),
            );
          }

          final post = vm.detailPost!;
          final author = vm.detailPostAuthor;
          final report = vm.detailReport;
          final mediaUrls = vm.detailMediaUrls;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─ Report context ─────────────────────────
              if (report != null) ...[
                _SectionLabel('REPORT CONTEXT'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kWarn.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: _kWarn.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reason: ${report.reason ?? '(none)'}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reported ${_fmtDate(report.createDate)}',
                        style:
                            const TextStyle(color: _kMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ─ Post info ──────────────────────────────
              _SectionLabel('POST'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author row
                    if (author != null)
                      Row(
                        children: [
                          _SmallAvatar(
                              url: author.profilePicUrl,
                              name: author.username),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                author.username,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14),
                              ),
                              Text(
                                author.email,
                                style: const TextStyle(
                                    color: _kMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    if (author != null) const SizedBox(height: 12),
                    Text(
                      post.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700),
                    ),
                    if (post.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        post.description!,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            height: 1.5),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _TagChip(
                            label: post.postType ?? 'post',
                            color: _kAccent),
                        const SizedBox(width: 6),
                        _TagChip(
                            label: '♥ ${post.postLike}', color: _kMuted),
                      ],
                    ),
                    if (post.createDate != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _fmtDate(post.createDate),
                        style: const TextStyle(
                            color: _kMuted, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),

              // ─ Media ─────────────────────────────────
              if (mediaUrls.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionLabel('MEDIA (${mediaUrls.length})'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: mediaUrls.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        mediaUrls[i],
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          width: 200,
                          color: _kCard,
                          child: const Icon(Icons.broken_image_rounded,
                              color: _kMuted),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // ─ Actions ───────────────────────────────
              if (widget.reportId != null) ...[
                const SizedBox(height: 28),
                _SectionLabel('ACTIONS'),
                const SizedBox(height: 10),
                _ActionButtons(
                  postId: widget.postId,
                  reportId: widget.reportId!,
                  isActionLoading: vm.isActionLoading,
                ),
              ],

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.postId,
    required this.reportId,
    required this.isActionLoading,
  });

  final int postId;
  final int reportId;
  final bool isActionLoading;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<AdminViewModel>();
    if (isActionLoading) {
      return const Center(
          child: CircularProgressIndicator(color: _kAccent));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => _onApproveReport(context, vm),
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Approve Report'),
          style: FilledButton.styleFrom(
            backgroundColor: _kSuccess.withValues(alpha: 0.15),
            foregroundColor: _kSuccess,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => _onDeletePost(context, vm),
          icon: const Icon(Icons.delete_rounded),
          label: const Text('Approve Report & Delete Post'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
            foregroundColor: Colors.redAccent,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => _onDismiss(context, vm),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kMuted,
            side: const BorderSide(color: _kBorder),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Dismiss Report'),
        ),
      ],
    );
  }

  Future<void> _onApproveReport(
      BuildContext context, AdminViewModel vm) async {
    final ok = await vm.approveReport(reportId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Report approved.' : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? _kSuccess : Colors.redAccent,
        ),
      );
      if (ok) Navigator.of(context).pop();
    }
  }

  Future<void> _onDeletePost(
      BuildContext context, AdminViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _kCard,
        title: const Text('Delete Post?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete the post and approve the report.',
          style: TextStyle(color: _kMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _kMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final ok = await vm.deletePost(postId, reportId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              ok ? 'Post deleted.' : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? _kCard : Colors.redAccent,
        ),
      );
      if (ok) Navigator.of(context).pop();
    }
  }

  Future<void> _onDismiss(BuildContext context, AdminViewModel vm) async {
    final ok = await vm.dismissReport(reportId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Report dismissed.' : (vm.errorMessage ?? 'Error')),
          backgroundColor: ok ? _kCard : Colors.redAccent,
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
      style: const TextStyle(
        color: _kMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0xFF2A2A2A),
        backgroundImage: NetworkImage(url!),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: _kAccent.withValues(alpha: 0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: _kAccent, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

String _fmtDate(DateTime? dt) {
  if (dt == null) return '-';
  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year}';
}

import 'package:flutter/material.dart';

import 'package:auragains/features/admin/admin_palette.dart';
import '../../../core/services/database_connection.dart';

class ContentDetailScreen extends StatefulWidget {
  final String postId;

  const ContentDetailScreen({super.key, required this.postId});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  final _client = DatabaseConnection.client;
  Map<String, dynamic>? _post;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rows = await _client
          .from('post')
          .select()
          .eq('post_id', widget.postId)
          .limit(1);
      setState(() {
        _post = rows.isNotEmpty ? rows.first as Map<String, dynamic> : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Post', style: AppTextStyles.headlineMedium),
        content: const Text(
          'This will permanently delete the post. Continue?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _client.from('post').delete().eq('post_id', widget.postId);
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Content Detail', style: AppTextStyles.headlineLarge),
        actions: [
          if (_post != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _deletePost,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? Center(child: Text(_error!, style: AppTextStyles.bodyMedium))
              : _post == null
                  ? const Center(
                      child: Text('Post not found', style: AppTextStyles.bodyMedium),
                    )
                  : _buildPostDetail(_post!),
    );
  }

  Widget _buildPostDetail(Map<String, dynamic> post) {
    final thumbnail = post['thumbnail_url'] as String?;
    final title = post['title'] as String? ?? '(No title)';
    final description = post['description'] as String? ?? '';
    final createDate = post['create_date'] as String? ?? '';
    final postType = post['post_type'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (thumbnail != null && thumbnail.isNotEmpty)
            ClipRRect(
              borderRadius: AppRadius.mdAll,
              child: Image.network(
                thumbnail,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.broken_image, size: 48, color: AppColors.textMuted),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              if (postType.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(30),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text(postType, style: AppTextStyles.caption.copyWith(color: AppColors.accent)),
                ),
              const Spacer(),
              Text(createDate.split('T').first, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTextStyles.headlineLarge),
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(description, style: AppTextStyles.bodyMedium),
          ],
          const SizedBox(height: AppSpacing.xxxl),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
              onPressed: _deletePost,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete This Post'),
            ),
          ),
        ],
      ),
    );
  }
}

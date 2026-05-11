import 'package:flutter/material.dart';

import 'package:auragains/features/admin/admin_palette.dart';
import '../../../core/services/database_connection.dart';
import 'content_detail_screen.dart';

/// Displays a paginated list of all posts for admin review.
/// Tapping a card navigates to [ContentDetailScreen].
class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  final _client = DatabaseConnection.client;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rows = await _client
          .from('post')
          .select('post_id, title, thumbnail_url, post_type, create_date')
          .order('create_date', ascending: false);
      setState(() {
        _posts = (rows as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Content', style: AppTextStyles.headlineLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.accent),
            onPressed: _loadPosts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _loadPosts,
                  child: _posts.isEmpty
                      ? const Center(
                          child: Text('No posts found.', style: AppTextStyles.bodyMedium),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: _posts.length,
                          itemBuilder: (context, index) =>
                              _buildPostCard(_posts[index]),
                        ),
                ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final postId = post['post_id'] as String? ?? '';
    final title = post['title'] as String? ?? '(No title)';
    final thumbnail = post['thumbnail_url'] as String?;
    final postType = post['post_type'] as String? ?? '';
    final createDate = (post['create_date'] as String? ?? '').split('T').first;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ContentDetailScreen(postId: postId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdAll,
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                bottomLeft: Radius.circular(AppRadius.md),
              ),
              child: thumbnail != null && thumbnail.isNotEmpty
                  ? Image.network(
                      thumbnail,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderThumb(),
                    )
                  : _placeholderThumb(),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        if (postType.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withAlpha(30),
                              borderRadius: AppRadius.smAll,
                            ),
                            child: Text(
                              postType,
                              style: AppTextStyles.caption
                                  .copyWith(color: AppColors.accent),
                            ),
                          ),
                        const Spacer(),
                        Text(createDate, style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: AppSpacing.md),
              child: Icon(Icons.chevron_right, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.image_not_supported,
          size: 28, color: AppColors.textMuted),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: AppSpacing.lg),
          Text(_error!, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _loadPosts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

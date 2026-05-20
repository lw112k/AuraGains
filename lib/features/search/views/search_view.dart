import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auragains/features/search/view_models/search_viewmodel.dart';
import 'package:auragains/features/post_feed/views/widgets/home/post_card.dart';
import 'package:auragains/features/auth/view_models/auth_viewmodel.dart';
import 'package:auragains/features/post_feed/models/post_preview_model.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitSearch(SearchViewModel vm, AuthViewModel authVm, String query) {
    final q = query.trim();
    if (q.isEmpty || q.length < 2) return;

    vm.addRecentSearch(q);
    vm.executeSearch(q, authVm.currentUser?.id ?? '');
    _focusNode.unfocus();
  }

  void _fillAndSearch(SearchViewModel vm, AuthViewModel authVm, String query) {
    _controller.text = query;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _submitSearch(vm, authVm, query);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A1A),
          elevation: 0,
          title: const Text(
            'AURAGAINS',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
        body: Consumer<SearchViewModel>(
          builder: (context, vm, _) {
            final authVm = context.read<AuthViewModel>();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── SEARCH BAR ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      textInputAction: TextInputAction.search,

                      onChanged: (v) => vm.onSearchTextChanged(
                        v,
                        authVm.currentUser?.id ?? '',
                      ),
                      onSubmitted: (v) => _submitSearch(vm, authVm, v),

                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.grey,
                          size: 22,
                        ),
                        suffixIcon: vm.isSearching
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _controller.clear();
                                  vm.clearSearch();
                                },
                              )
                            : null,
                        hintText: 'Search Posts & Tags...',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── BODY (Discovery vs Results) ─────────────────────────
                Expanded(
                  child: vm.isLoading
                      ? const Center(
                          // Kept your cyan accent!
                          child: CircularProgressIndicator(
                            color: Color(0xFF00E5FF),
                          ),
                        )
                      : vm.isSearching
                      ? _buildResults(context, vm)
                      : _buildDiscovery(vm, authVm), // Pass authVm down
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── DISCOVERY SCREEN  ────────────────────────────
  Widget _buildDiscovery(SearchViewModel vm, AuthViewModel authVm) {
    if (vm.isInitializing) {
      return const Center(
        // Kept your cyan accent!
        child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // --- RECENT SEARCHES ---
        if (vm.recentSearches.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT SEARCHES',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: vm.clearRecentSearches,
                child: const Text(
                  'CLEAR ALL',
                  style: TextStyle(
                    // Kept your cyan accent!
                    color: Colors.cyanAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vm.recentSearches.map((term) {
              return _DismissibleChip(
                label: term,
                onTap: () => _fillAndSearch(vm, authVm, term),
                onDismiss: () => vm.removeRecentSearch(term),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // --- TRENDING SEARCHES ---
        if (vm.trendingSearches.isNotEmpty) ...[
          const SizedBox(height: 4),
          const Text(
            'SEARCH BY TAGS',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: vm.trendingSearches.map((tag) {
              return _TrendingChip(
                label: tag.name,
                onTap: () => _fillAndSearch(vm, authVm, tag.name),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ── RESULTS SCREEN ───────────────────────────────────────────────────
  Widget _buildResults(BuildContext context, SearchViewModel vm) {
    if (vm.postResults.isEmpty) {
      return const Center(
        child: Text('No results found', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'POSTS',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: vm.postResults.length,
            itemBuilder: (context, index) {
              final postMap = vm.postResults[index];
              final userData = postMap['user'] as Map<String, dynamic>?;
              final creatorId = postMap['post_by']?.toString() ?? '';
              final postType = postMap['post_type']?.toString() ?? 'normal';
              final visibility = postMap['visibility']?.toString() ?? 'public';

              final isFriendsOnly = visibility == 'friends';
              final isExpert = postType == 'ask_expert';

              final postModel = PostPreviewModel(
                postId:
                    int.tryParse(postMap['post_id']?.toString() ?? '0') ?? 0,
                title: postMap['title']?.toString() ?? 'Untitled',
                thumbnailUrl: postMap['thumbnail_url']?.toString(),
                firstMediaUrl:
                    postMap['post_media'] is List &&
                        (postMap['post_media'] as List).isNotEmpty
                    ? (postMap['post_media'] as List).first['media_url']
                          ?.toString()
                    : null,
                firstMediaType:
                    postMap['post_media'] is List &&
                        (postMap['post_media'] as List).isNotEmpty
                    ? (postMap['post_media'] as List).first['media_type']
                          ?.toString()
                    : null,
                creatorId: creatorId,
                creatorUsername: userData?['username']?.toString() ?? 'Unknown',
                creatorProfileUrl: userData?['profile_pic_url']?.toString(),
                likeCount:
                    int.tryParse(postMap['post_like']?.toString() ?? '0') ?? 0,
                createDate:
                    DateTime.tryParse(
                      postMap['create_date']?.toString() ?? '',
                    ) ??
                    DateTime.now(),
              );

              final isVideo =
                  postModel.firstMediaType?.toLowerCase() == 'video';

              final double topPosition = isVideo ? 50.0 : 25.0;

              final double rightPosition = isVideo ? 12.0 : 17.0;

              return Stack(
                children: [
                  Positioned.fill(child: PostCard(post: postModel)),

                  Positioned(
                    top: topPosition,
                    right: rightPosition,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Ask Expert Indicator
                        if (isExpert)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.cyanAccent,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.forum,
                              color: Colors.black,
                              size: 12,
                            ),
                          ),

                        // Friends Only Indicator
                        if (isFriendsOnly)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.85),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.group,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── REUSABLE CHIP WIDGETS ─────────────────────────────────────────────

class _DismissibleChip extends StatelessWidget {
  const _DismissibleChip({
    required this.label,
    required this.onTap,
    required this.onDismiss,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(Icons.close, color: Colors.grey, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendingChip extends StatelessWidget {
  const _TrendingChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}

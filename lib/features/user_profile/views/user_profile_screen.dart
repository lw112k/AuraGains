import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/other_user_profile_viewmodel.dart';

class UserProfileScreen extends StatelessWidget {
  final String userId;

  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Wrap the screen in ChangeNotifierProvider to inject the target userId
    return ChangeNotifierProvider(
      create: (_) => OtherUserProfileViewModel(targetUserId: userId),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Consumer<OtherUserProfileViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF0066FF)));
            }

            return DefaultTabController(
              length: 4, // Posts, Workout Plan, Stats, Goals
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    // 1. Cover Banner & App Bar
                    SliverAppBar(
                      expandedHeight: 160.0,
                      pinned: true,
                      backgroundColor: const Color(0xFF0A0A0A),
                      flexibleSpace: FlexibleSpaceBar(
                        background: viewModel.coverUrl != null
                            ? Image.network(viewModel.coverUrl!, fit: BoxFit.cover)
                            : Container(color: const Color(0xFF1E1E1E)), // Fallback cover
                      ),
                    ),
                    
                    // 2. Profile Info (Avatar, Name, Badges, Counts)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar and Follow Button Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Transform.translate(
                                  offset: const Offset(0, -30),
                                  child: CircleAvatar(
                                    radius: 45,
                                    backgroundColor: const Color(0xFF0A0A0A),
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundColor: const Color(0xFF1E1E1E),
                                      backgroundImage: viewModel.avatarUrl != null 
                                          ? NetworkImage(viewModel.avatarUrl!) 
                                          : null,
                                      child: viewModel.avatarUrl == null 
                                          ? const Icon(Icons.person, size: 40, color: Colors.white54) 
                                          : null,
                                    ),
                                  ),
                                ),
                                // Follow/Unfollow Button
                                ElevatedButton(
                                  onPressed: viewModel.toggleFollow,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: viewModel.isFollowing 
                                        ? const Color(0xFF1E1E1E) 
                                        : const Color(0xFF0066FF),
                                    side: BorderSide(
                                      color: viewModel.isFollowing ? Colors.white24 : Colors.transparent,
                                    ),
                                  ),
                                  child: Text(
                                    viewModel.isFollowing ? 'Following' : 'Follow',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Username & Verified Badge
                            Transform.translate(
                              offset: const Offset(0, -20),
                              child: Row(
                                children: [
                                  Text(
                                    viewModel.userName ?? 'Unknown User',
                                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  if (viewModel.isExpert)
                                    const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                                ],
                              ),
                            ),
                            
                            // Stats Row
                            Transform.translate(
                              offset: const Offset(0, -10),
                              child: Row(
                                children: [
                                  _buildStatColumn(viewModel.postCount.toString(), 'Posts'),
                                  const SizedBox(width: 24),
                                  _buildStatColumn(viewModel.followerCount.toString(), 'Followers'),
                                  const SizedBox(width: 24),
                                  _buildStatColumn(viewModel.followingCount.toString(), 'Following'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 3. Tab Bar
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        const TabBar(
                          indicatorColor: Color(0xFF0066FF),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey,
                          tabs: [
                            Tab(text: 'Posts'),
                            Tab(text: 'Workout'),
                            Tab(text: 'Stats'),
                            Tab(text: 'Goals'),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                
                // 4. Tab Views
                body: TabBarView(
                  children: [
                    // Posts Tab
                    GridView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: viewModel.postCount,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemBuilder: (context, index) => Container(
                        color: const Color(0xFF1E1E1E),
                        child: const Center(child: Icon(Icons.image, color: Colors.white54)),
                      ),
                    ),
                    // Workout Plan Tab (Placeholder UI until wired)
                    const Center(child: Text('Workout Plan Data', style: TextStyle(color: Colors.grey))),
                    // Stats Tab
                    const Center(child: Text('Stats Data', style: TextStyle(color: Colors.grey))),
                    // Goals Tab
                    const Center(child: Text('Goals Data', style: TextStyle(color: Colors.grey))),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}

// Helper class to make the TabBar stick to the top when scrolling up
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
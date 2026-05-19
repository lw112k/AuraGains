import 'package:auragains/features/workout_management/views/protocol_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/user_profile_viewmodel.dart';
import '../../expert/views/expert_application_views.dart';
import '../../post_feed/view_models/post_detail/post_detail_viewmodel.dart';
import '../../post_feed/views/pages/post_detail/post_detail_view.dart';

class UserProfileView extends StatelessWidget {
  final String targetUserId;
  final String currentUserId;

  const UserProfileView({
    Key? key,
    required this.targetUserId,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          UserProfileViewModel(targetUserId: targetUserId)
            ..initializeProfile(currentUserId),
      child: Consumer<UserProfileViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFF121212),
              body: Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent),
              ),
            );
          }

          return DefaultTabController(
            length: viewModel.isMe ? 2 : 1,
            child: Scaffold(
              backgroundColor: const Color(0xFF121212),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                  viewModel.isMe ? 'Your Profile' : 'Profile',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                centerTitle: true,
              ),
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return <Widget>[
                    SliverToBoxAdapter(
                      child: Column(
                        children: <Widget>[
                          _buildIdentityZone(context, viewModel),
                          const SizedBox(height: 24),
                          _buildDashboardRow(context, viewModel),
                          const SizedBox(height: 24),
                          _buildActionZone(context, viewModel),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          indicatorColor: Colors.cyanAccent,
                          labelColor: Colors.cyanAccent,
                          unselectedLabelColor: Colors.grey,
                          tabs: <Widget>[
                            const Tab(icon: Icon(Icons.grid_on), text: 'POSTS'),
                            if (viewModel.isMe)
                              const Tab(
                                icon: Icon(Icons.bookmark_border),
                                text: 'SAVED',
                              ),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  children: <Widget>[
                    _buildPostGrid(viewModel, viewModel.userPosts),
                    if (viewModel.isMe)
                      _buildPostGrid(viewModel, viewModel.savedPosts),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Identity Zone ---
  Widget _buildIdentityZone(
    BuildContext context,
    UserProfileViewModel viewModel,
  ) {
    final username = viewModel.profile?.username ?? 'Unknown';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    final picUrl = viewModel.profile?.profilePicUrl;

    final avatarContent = (picUrl != null && picUrl.isNotEmpty)
        ? CircleAvatar(radius: 48, backgroundImage: NetworkImage(picUrl))
        : CircleAvatar(
            radius: 48,
            backgroundColor: Colors.blueAccent,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

    return Column(
      children: <Widget>[
        if (viewModel.isMe)
          Column(
            children: <Widget>[
              GestureDetector(
                onTap: () => viewModel.pickAndUploadImage(context),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.cyanAccent,
                      child: viewModel.isUploadingPic
                          ? const CircularProgressIndicator(color: Colors.black)
                          : CircleAvatar(
                              radius: 48,
                              backgroundColor: const Color(0xFF1E1E1E),
                              backgroundImage:
                                  (picUrl != null && picUrl.isNotEmpty)
                                  ? NetworkImage(picUrl)
                                  : null,
                              child: (picUrl == null || picUrl.isEmpty)
                                  ? const Icon(
                                      Icons.person_outline,
                                      color: Colors.cyanAccent,
                                      size: 40,
                                    )
                                  : null,
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.cyanAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.black,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (picUrl != null && picUrl.isNotEmpty)
                TextButton(
                  onPressed: () => viewModel.clearProfileImage(context),
                  child: const Text(
                    'Clear Photo',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
            ],
          )
        else
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.cyanAccent,
            child: avatarContent,
          ),

        const SizedBox(height: 12),
        Text(
          username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        _buildVerificationBadge(context, viewModel),

        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _networkStatCard('Followers', viewModel.followerCount),
              Container(
                height: 30,
                width: 1,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                color: Colors.grey.withOpacity(0.3),
              ),
              _networkStatCard('Following', viewModel.followingCount),
            ],
          ),
        ),
      ],
    );
  }

  Widget _networkStatCard(String label, int count) {
    return Column(
      children: <Widget>[
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  // --- Verification Badge (Pill Shape) ---
  Widget _buildVerificationBadge(
    BuildContext context,
    UserProfileViewModel viewModel,
  ) {
    final status = viewModel.expertStatus;
    final isMe = viewModel.isMe;

    if (status == 'approved') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.cyanAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.cyanAccent),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.verified, color: Colors.cyanAccent, size: 16),
            SizedBox(width: 4),
            Text(
              'Verified Trainer',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (isMe) {
      if (status == 'pending') {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.access_time, color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Text(
                'Verification Pending',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      } else {
        return Material(
          color: Colors.cyanAccent,
          borderRadius: BorderRadius.circular(50),
          child: InkWell(
            borderRadius: BorderRadius.circular(50),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TrainerApplicationScreen(
                    currentUserId: viewModel.currentUserId,
                  ),
                ),
              );
              viewModel.refreshProfile();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Verify Trainer',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, color: Colors.black, size: 10),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(50),
        ),
        child: const Text(
          'AuraGains User',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
  }

  // --- Unified Dashboard (Objective & Stats) ---
  Widget _buildDashboardRow(
    BuildContext context,
    UserProfileViewModel viewModel,
  ) {
    final displayName = viewModel.currentLevel?.name ?? 'Set Objective';
    final useImperial = viewModel.displayUnitSystem == 'ft/lbs';

    final hCm = viewModel.bodyStats?.heightCm;
    final wKg = viewModel.bodyStats?.weightKg;
    final hasHeight = hCm != null && hCm > 0;
    final hasWeight = wKg != null && wKg > 0;

    final hText = !hasHeight
        ? "-"
        : (useImperial
              ? viewModel.bodyStats!.heightFtIn
              : '${hCm.toStringAsFixed(1)} cm');

    final wText = !hasWeight
        ? "-"
        : (useImperial
              ? '${viewModel.bodyStats!.weightLbs.toStringAsFixed(1)} lbs'
              : '${wKg.toStringAsFixed(1)} kg');
    Widget sectionHeader(String title) {
      return Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (viewModel.isMe) ...const [
              SizedBox(width: 4),
              Icon(Icons.edit, color: Colors.cyanAccent, size: 12),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: <Widget>[
          // ----------------------------------------------------
          // 1. OBJECTIVE COLUMN
          // ----------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionHeader('OBJECTIVE'),
                SizedBox(
                  height: 65, // 💡 Sleek, fixed height box!
                  child: Material(
                    color: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: viewModel.isMe
                            ? Colors.cyanAccent.withOpacity(0.4)
                            : Colors.grey.withOpacity(0.1),
                        width: viewModel.isMe ? 1.5 : 1.0,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: viewModel.isMe
                          ? () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) => EditObjectiveBottomSheet(
                                  viewModel: viewModel,
                                ),
                              );
                            }
                          : null,
                      child: Center(
                        child: Text(
                          displayName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ----------------------------------------------------
          // 2. STATS COLUMN
          // ----------------------------------------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionHeader('STATS'),
                SizedBox(
                  height: 65,
                  child: Material(
                    color: const Color(0xFF1E1E1E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: viewModel.isMe
                            ? Colors.cyanAccent.withOpacity(0.4)
                            : Colors.grey.withOpacity(0.1),
                        width: viewModel.isMe ? 1.5 : 1.0,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: viewModel.isMe
                          ? () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) =>
                                    EditStatsBottomSheet(viewModel: viewModel),
                              );
                            }
                          : null,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          _compactStat('Height', hText),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          _compactStat('Weight', wText),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  // --- Action Zone ---
  Widget _buildActionZone(
    BuildContext context,
    UserProfileViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          if (viewModel.isMe) ...<Widget>[
            _actionButton(
              text: 'Workout Plan',
              icon: Icons.fitness_center,
              onTap: () => _openWorkoutPlan(context, viewModel),
            ),
          ] else ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: viewModel.isFollowing
                            ? Colors.transparent
                            : Colors.cyanAccent,
                        side: viewModel.isFollowing
                            ? BorderSide(
                                color: Colors.grey.withValues(alpha: 0.5),
                              )
                            : BorderSide.none,
                        elevation: viewModel.isFollowing ? 0 : 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => viewModel.toggleFollow(),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          viewModel.isFollowing ? 'Following' : 'Follow',
                          style: TextStyle(
                            color: viewModel.isFollowing
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _actionButton(
                    text: 'View Workout',
                    icon: Icons.visibility,
                    onTap: () => _openWorkoutPlan(context, viewModel),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _openWorkoutPlan(BuildContext context, UserProfileViewModel viewModel) {
    final protocol = viewModel.activeProtocol;

    if (protocol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.isMe
                ? 'You have no active workout protocol yet. Start one from the Workout tab!'
                : '${viewModel.profile?.username ?? 'This user'} hasn\'t started any training protocols yet.',
          ),
          backgroundColor: const Color(0xFF2A2A2A),
        ),
      );
      return;
    }

    final bool isPublic = protocol['is_public'] == true;

    if (!viewModel.isMe && !isPublic) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${viewModel.profile?.username ?? 'This user'}\'s workout plan is private.',
          ),
          backgroundColor: const Color(0xFF2A2A2A),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProtocolDetailView(protocolData: protocol),
      ),
    );
  }

  Widget _actionButton({
    required String text,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A2A2A),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.cyanAccent.withOpacity(0.3)),
          ),
        ),
        onPressed: onTap,
        // 💡 Wrapped the ENTIRE Row in a FittedBox to shrink icon + text together!
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize:
                MainAxisSize.min, // 💡 Important so it shrinks properly
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18, color: Colors.cyanAccent),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontSize: 14, // Slightly smaller base font
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Post Grid ---
  Widget _buildPostGrid(
    UserProfileViewModel viewModel,
    List<Map<String, dynamic>> postsList,
  ) {
    if (viewModel.isLoadingPosts) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.cyanAccent),
      );
    }

    if (postsList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.grid_off, color: Colors.grey, size: 48),
            SizedBox(height: 16),
            Text(
              'No Posts Found',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final sortedPosts = List<Map<String, dynamic>>.from(postsList);
    sortedPosts.sort((a, b) {
      final idA = int.tryParse(a['post_id'].toString()) ?? 0;
      final idB = int.tryParse(b['post_id'].toString()) ?? 0;
      return idB.compareTo(idA);
    });

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: sortedPosts.length,
      itemBuilder: (context, index) {
        final post = sortedPosts[index];
        final postId = int.parse(post['post_id'].toString());

        return _PostPreviewTile(
          post: post,
          onTap: () {
            if (!context.mounted) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (context) {
                    return PostDetailViewModel(
                      postId: postId,
                      currentUserId: viewModel.currentUserId,
                    )..loadPost();
                  },
                  child: const PostDetailView(),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: const Color(0xFF121212), child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class EditObjectiveBottomSheet extends StatelessWidget {
  final UserProfileViewModel viewModel;
  const EditObjectiveBottomSheet({Key? key, required this.viewModel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Select Primary Objective',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...viewModel.availableLevels.map((level) {
              final isSelected =
                  viewModel.currentLevel?.levelId == level.levelId;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  level.name,
                  style: TextStyle(
                    color: isSelected ? Colors.cyanAccent : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  level.description,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.cyanAccent)
                    : null,
                onTap: () {
                  viewModel.saveLevel(level);
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 24),
          ],
        ), // Closes the Column
      ),
    ); // Closes the Container
  }
}

class EditStatsBottomSheet extends StatefulWidget {
  final UserProfileViewModel viewModel;

  const EditStatsBottomSheet({Key? key, required this.viewModel})
    : super(key: key);

  @override
  State<EditStatsBottomSheet> createState() => _EditStatsBottomSheetState();
}

class _EditStatsBottomSheetState extends State<EditStatsBottomSheet> {
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late String _selectedUnit;

  @override
  void initState() {
    super.initState();
    final stats = widget.viewModel.bodyStats;
    _selectedUnit = stats?.unitSystem ?? 'cm/kg';

    final isImperial = _selectedUnit == 'ft/lbs';
    final initialHeight = isImperial
        ? ((stats?.heightCm ?? 0) / 2.54).toStringAsFixed(1)
        : (stats?.heightCm ?? 0).toStringAsFixed(1);

    final initialWeight = isImperial
        ? (stats?.weightLbs ?? 0).toStringAsFixed(1)
        : (stats?.weightKg ?? 0).toStringAsFixed(1);

    _heightController = TextEditingController(
      text: initialHeight == '0.0' ? '' : initialHeight,
    );
    _weightController = TextEditingController(
      text: initialWeight == '0.0' ? '' : initialWeight,
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Edit Body Stats',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Center(
            child: ToggleButtons(
              isSelected: <bool>[
                _selectedUnit == 'cm/kg',
                _selectedUnit == 'ft/lbs',
              ],
              onPressed: (index) => setState(
                () => _selectedUnit = index == 0 ? 'cm/kg' : 'ft/lbs',
              ),
              color: Colors.grey,
              selectedColor: Colors.black,
              fillColor: Colors.cyanAccent,
              borderRadius: BorderRadius.circular(8),
              borderColor: Colors.grey[800],
              selectedBorderColor: Colors.cyanAccent,
              children: const <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text('Metric'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text('Imperial'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _heightController,
            label: _selectedUnit == 'cm/kg'
                ? 'Height (cm)'
                : 'Height (total inches)',
            icon: Icons.height,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _weightController,
            label: _selectedUnit == 'cm/kg' ? 'Weight (kg)' : 'Weight (lbs)',
            icon: Icons.monitor_weight,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: widget.viewModel.isSavingStats
                  ? null
                  : () async {
                      final h = double.tryParse(_heightController.text) ?? 0;
                      final w = double.tryParse(_weightController.text) ?? 0;

                      final success = await widget.viewModel.saveBodyStats(
                        inputHeight: h,
                        inputWeight: w,
                        selectedUnitSystem: _selectedUnit,
                      );
                      if (success && mounted) Navigator.pop(context);
                    },
              child: widget.viewModel.isSavingStats
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.black),
                    )
                  : const Text(
                      'Save Stats',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        filled: true,
        fillColor: const Color(0xFF121212),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
      ),
    );
  }
}

// ==========================================
// Private Grid Tile Class
// ==========================================
class _PostPreviewTile extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;

  const _PostPreviewTile({Key? key, required this.post, required this.onTap})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String title = post['title']?.toString() ?? 'No Title';
    final int postId =
        int.tryParse(post['post_id'].toString()) ?? title.hashCode;
    final String visibility = post['visibility']?.toString() ?? 'public';
    final String? explicitThumbnail = post['thumbnail_url']?.toString();
    final String postType = post['post_type']?.toString() ?? 'normal';
    String? mediaUrl;
    String mediaType = 'text';

    final postMedia = post['post_media'];

    Map<String, dynamic>? mediaData;

    // THE CATCH-ALL: Handle both Lists and single Maps safely
    if (postMedia is List && postMedia.isNotEmpty) {
      mediaData = postMedia.first as Map<String, dynamic>;
    } else if (postMedia is Map) {
      mediaData = postMedia as Map<String, dynamic>;
    }

    // If we successfully grabbed the media data, extract the URL and type
    if (mediaData != null) {
      mediaUrl = mediaData['media_url']?.toString();
      // Double check if your database column is called 'type' instead of 'media_type'!
      mediaType = mediaData['media_type']?.toString() ?? 'picture';
    }

    final String? imageToShow =
        (explicitThumbnail != null && explicitThumbnail.isNotEmpty)
        ? explicitThumbnail
        : mediaUrl;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildThumbnailOrFallback(imageToShow, title, postId),

            if (postType == 'ask_expert')
              Positioned(
                top: 6,
                left: 6, 
                child: Container(
                  padding: const EdgeInsets.all(6), 
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape
                        .circle, 
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons
                        .forum_outlined, 
                    color: Colors.black,
                    size: 14,
                  ),
                ),
              ),

            Positioned(
              top: 6,
              right: 6,
              child: _buildIndicators(visibility, mediaType),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators(String visibility, String mediaType) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. VISIBILITY INDICATORS
        if (visibility == 'private') ...[
          _indicatorContainer(Icons.lock_outline),
          const SizedBox(width: 4),
        ] else if (visibility == 'friends') ...[
          _indicatorContainer(
            Icons.people_outline,
          ), // 💡 Group icon for friends-only!
          const SizedBox(width: 4),
        ],
        // Note: If it's 'public', we don't show an icon to keep the thumbnail clean,
        // just like Instagram does!

        // 2. MEDIA TYPE INDICATORS
        if (mediaType == 'video')
          _indicatorContainer(Icons.play_arrow)
        else if (mediaType == 'text')
          _indicatorContainer(Icons.text_snippet)
        else // picture
          _indicatorContainer(Icons.photo_library, size: 12),
      ],
    );
  }

  Widget _indicatorContainer(IconData icon, {double size = 14}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }

  Widget _buildThumbnailOrFallback(String? url, String title, int id) {
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildFeedStyleFallback(title, id),
      );
    }
    return _buildFeedStyleFallback(title, id);
  }

  Widget _buildFeedStyleFallback(String title, int id) {
    final List<List<Color>> feedBackgrounds = [
      [const Color(0xFF283593), const Color(0xFF3F51B5)],
      [const Color(0xFFE65100), const Color(0xFFFF9800)],
      [const Color(0xFF01579B), const Color(0xFF0288D1)],
      [const Color(0xFF4A148C), const Color(0xFF7B1FA2)],
      [const Color(0xFF004D40), const Color(0xFF00796B)],
    ];

    final gradient = feedBackgrounds[id % feedBackgrounds.length];

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        textAlign: TextAlign.center,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}

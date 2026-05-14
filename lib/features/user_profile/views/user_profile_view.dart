import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/user_profile_viewmodel.dart';

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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _networkStatCard('Followers', viewModel.followerCount),
            const SizedBox(width: 32),
            _networkStatCard('Following', viewModel.followingCount),
          ],
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
        return GestureDetector(
          onTap: () {
            // Navigator.of(context).push(
            //   MaterialPageRoute(
            //     builder: (_) => TrainerApplicationScreen(currentUserId: viewModel.currentUserId),
            //   ),
            // );
            print("Navigate to Application Screen");
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.cyanAccent),
            ),
            child: const Text(
              'Verify Trainer',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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

  // --- Unified Dashboard ---
  Widget _buildDashboardRow(
    BuildContext context,
    UserProfileViewModel viewModel,
  ) {
    final displayName = viewModel.currentLevel?.name ?? 'Set Objective';
    final isPrivate = viewModel.bodyStats?.visibility == 'private';
    final hideStats = !viewModel.isMe && isPrivate;
    final useImperial = viewModel.bodyStats?.unitSystem == 'ft/lbs';

    final hCm = viewModel.bodyStats?.heightCm;
    final wKg = viewModel.bodyStats?.weightKg;
    final hasHeight = hCm != null && hCm > 0;
    final hasWeight = wKg != null && wKg > 0;

    final hText = hideStats
        ? "Hidden"
        : (!hasHeight
              ? "-"
              : (useImperial ? viewModel.bodyStats!.heightFtIn : '$hCm cm'));

    final wText = hideStats
        ? "Hidden"
        : (!hasWeight
              ? "-"
              : (useImperial
                    ? '${viewModel.bodyStats!.weightLbs} lbs'
                    : '$wKg kg'));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: GestureDetector(
                onTap: viewModel.isMe
                    ? () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) =>
                              EditObjectiveBottomSheet(viewModel: viewModel),
                        );
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const SizedBox(width: 4),
                          const Text(
                            'OBJECTIVE',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (viewModel.isMe) ...<Widget>[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.edit,
                              color: Colors.cyanAccent,
                              size: 12,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: GestureDetector(
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
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.cyanAccent.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const SizedBox(width: 4),
                          const Text(
                            'STATS',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (viewModel.isMe) ...<Widget>[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.edit,
                              color: Colors.cyanAccent,
                              size: 12,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          _compactStat('Height', hText, hideStats),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                          _compactStat('Weight', wText, hideStats),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactStat(String label, String value, bool isHidden) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (isHidden)
          const Icon(Icons.visibility_off, color: Colors.grey, size: 16)
        else
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: <Widget>[
          if (viewModel.isMe) ...<Widget>[
            _commandButton(
              'Workout Plan',
              const Color(0xFF1E1E1E),
              Colors.white,
              () {},
            ),
          ] else ...<Widget>[
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: viewModel.isFollowing
                      ? Colors.transparent
                      : Colors.cyanAccent,
                  side: viewModel.isFollowing
                      ? const BorderSide(color: Colors.grey)
                      : BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => viewModel.toggleFollow(),
                child: Text(
                  viewModel.isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    color: viewModel.isFollowing ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _commandButton(
              'View Workout Plan',
              const Color(0xFF1E1E1E),
              Colors.white,
              () {},
            ),
          ],
        ],
      ),
    );
  }

  Widget _commandButton(
    String text,
    Color bgColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
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

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: postsList.length,
      itemBuilder: (context, index) {
        final post = postsList[index];
        final imageUrl = post['thumbnail_url'] as String?;
        final postId = post['post_id'].toString();

        return GestureDetector(
          onTap: () {
            // 🚀 TEAMMATE HANDOFF POINT
            debugPrint("Navigating to Post View...");
            debugPrint("Target User ID: ${viewModel.targetUserId}");
            debugPrint("Post ID clicked: $postId");
          },
          child: Container(
            color: const Color(0xFF1E1E1E),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.cyanAccent,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    },
                  )
                : const Icon(Icons.image_not_supported, color: Colors.grey),
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;

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
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
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
            final isSelected = viewModel.currentLevel?.levelId == level.levelId;
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
      ),
    );
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

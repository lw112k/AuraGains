import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:auragains/features/post_feed/views/pages/home/home_view.dart';
import 'package:auragains/features/message/views/message_view.dart';
import 'package:auragains/features/workout_management/views/workout_view.dart';
import '../../features/user_profile/views/user_profile_view.dart';

import '../../features/auth/view_models/auth_viewmodel.dart';
import 'clickable_avatar.dart';
import '../../features/message/view_models/message_view_model.dart';

/// =====================================================================
/// [UserHomepageFrame]
///
/// The Master Layout Shell for all authenticated users in AuraGains.
///
/// PURPOSE:
/// This widget acts as the persistent "Frame" of the app. It holds the
/// top [AppBar] (Header) and the [BottomNavigationBar] (Footer) in place,
/// ensuring they never flicker or reload when the user navigates.
///
/// HOW IT WORKS:
/// Instead of pushing new screens, this frame uses an [IndexedStack] to
/// simply swap out the middle content based on the selected Navbar tab.
/// This keeps the state of all 5 tabs "alive" in the background (e.g.,
/// scroll positions won't reset when switching tabs).
///
/// TEAM INSTRUCTIONS:
/// Do NOT add Scaffolds, AppBars, or NavBars to your individual feature
/// screens (Home, Challenge, Post, Message). Just build your raw UI
/// content, and the Lead Developer will plug it into the [_pages] array below.
/// =====================================================================

class UserHomepageFrame extends StatefulWidget {
  const UserHomepageFrame({super.key});

  @override
  State<UserHomepageFrame> createState() => _UserHomepageFrameState();
}

class _UserHomepageFrameState extends State<UserHomepageFrame> {
  int _currentIndex = 0;

  // THE REDIRECTION TARGETS
  // REMEMBER Teammates: When your feature is complete, replace the placeholder
  // Text widget below with your actual View class (e.g., HomeView()).
  final List<Widget> _pages = [
    const HomeView(), // Index 0: Replace with HomeView()
    const WorkoutView(), // Index 1: Replace with ChallengeView()
    const Center(child: Text('Post')), // Index 2: Replace with PostView()
    const MessageView(), // Index 3: Replace with MessageView()
    const Center(child: Text('Expert')), // Index 4: Replace with ExpertView()
  ];

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final user = authVM.currentUser;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white10, height: 1.0),
        ),
        title: const Text('AURAGAINS'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              print("Search tapped");
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 45),
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (String value) {
                if (value == 'profile' && user != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileView(
                        targetUserId: user.id,
                        currentUserId: user.id,
                      ),
                    ),
                  );
                } else if (value == 'logout') {
                  context.read<MessageViewModel>().clearData();

                  authVM.logout();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: ListTile(
                    leading: Icon(Icons.person_outline),
                    title: Text('Profile'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.redAccent),
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              child: ClickableAvatar(
                profilePicUrl: user?.profilePicUrl,
                username: user?.username,
                radius: 16,
                onTap: null,
              ),
            ),
          ),
        ],
      ),
      // IndexedStack keeps the state of all 5 tabs "alive"
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // --- PRIVATE NAVBAR WIDGET ---
  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: Colors.blueAccent,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center_outlined),
          activeIcon: Icon(Icons.fitness_center),
          label: 'Workout',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_box_outlined),
          activeIcon: Icon(Icons.add_box),
          label: 'Post',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          activeIcon: Icon(Icons.chat_bubble),
          label: 'Message',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.contact_support_outlined),
          activeIcon: Icon(Icons.contact_support),
          label: 'Expert',
        ),
      ],
    );
  }
}

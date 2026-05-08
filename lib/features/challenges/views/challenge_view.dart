import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'browse_challenge_view.dart';
import '../view_models/challenge_viewmodel.dart';
import 'leaderboard_view.dart';
import 'history_view.dart';

class ChallengeView extends StatefulWidget {
  const ChallengeView({super.key});

  @override
  State<ChallengeView> createState() => _ChallengeViewState();
}

class _ChallengeViewState extends State<ChallengeView> {
  final List<String> _titles = ['Challenges', 'Leaderboard', 'History'];

  @override
  void initState() {
    super.initState();
    // Fetch points once when the view first loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String currentUserId =
          Supabase.instance.client.auth.currentUser?.id ?? '';
      if (currentUserId.isNotEmpty) {
        context.read<ChallengeViewModel>().loadLeaderboardData(currentUserId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Matches the 3 tabs below
      child: Builder(
        builder: (context) {
          // Access the controller to track the current index for the title
          final TabController tabController = DefaultTabController.of(context);

          return AnimatedBuilder(
            animation: tabController,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. DYNAMIC TITLE & POINTS WALLET
                  SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left Side: Section Title
                          Text(
                            _titles[tabController.index].toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey[300],
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 2.0,
                            ),
                          ),

                          // Right Side: The Points Wallet
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x1A00FFFF), // 10% Cyan Accent
                              border: Border.all(
                                color: const Color(
                                  0x8000FFFF,
                                ), // 50% Cyan Accent
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 4),
                                // 💡 Pulling live data from the ViewModel
                                Text(
                                  '${context.watch<ChallengeViewModel>().totalPoints} PTS',
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2. THE PILL NAV BAR
                  Container(
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: Colors.cyanAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.cyanAccent,
                          width: 1.5,
                        ),
                      ),
                      labelColor: Colors.cyanAccent,
                      unselectedLabelColor: Colors.grey[600],
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(text: 'Browse'),
                        Tab(text: 'Leaderboard'),
                        Tab(text: 'History'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3. CONTENT AREA
                  Expanded(
                    child: TabBarView(
                      children: [
                        const BrowseChallengeView(),
                        // Leaderboard Tab
                        const Center(child: LeaderboardView()),
                        // History Tab
                        const Center(
                          child: HistoryView()
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
